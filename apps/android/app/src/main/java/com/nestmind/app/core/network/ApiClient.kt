package com.nestmind.app.core.network

import com.nestmind.app.core.config.AppConfig
import com.nestmind.app.models.*
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.android.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json
import java.io.IOException
import kotlin.coroutines.cancellation.CancellationException

sealed class ApiError : Exception() {
    object Unauthorized : ApiError() {
        override val message: String = "Session expired. Please sign in again."
    }
    data class Server(override val message: String) : ApiError()
    data class Network(override val message: String = "Network error. Please check your connection and try again.") : ApiError()
    object InvalidResponse : ApiError() {
        override val message: String = "Unexpected response from server."
    }
}

class ApiClient(
    private val config: AppConfig,
    private val accessTokenProvider: () -> String?
) : java.io.Closeable {
    private val json = Json {
        ignoreUnknownKeys = true
        coerceInputValues = true
        isLenient = true
    }

    private val http = HttpClient(Android) {
        install(ContentNegotiation) {
            json(json)
        }
        engine {
            connectTimeout = 60_000
            socketTimeout = 60_000
        }
    }

    override fun close() {
        http.close()
    }

    // ─── Profile ─────────────────────────────────────────────────────────────

    suspend fun fetchProfile(): UserProfile {
        val response: ProfileResponse = get("api/profile")
        return response.profile
    }

    suspend fun updateProfile(request: ProfileUpdateRequest): UserProfile {
        val response: ProfileResponse = patch("api/profile", request)
        return response.profile
    }

    // ─── Conversations ────────────────────────────────────────────────────────

    suspend fun fetchConversations(): List<ConversationSummary> {
        val response: ConversationsResponse = get("api/conversations")
        return response.conversations
    }

    suspend fun fetchConversation(id: String): ConversationDetail {
        val response: ConversationResponse = get("api/conversations/$id")
        return response.conversation
    }

    suspend fun sendChat(request: ChatRequest): ChatResponse {
        return post("api/chat", request)
    }

    suspend fun deleteConversation(id: String) {
        deleteRequest<Unit>("api/conversations/$id")
    }

    // ─── Memory ───────────────────────────────────────────────────────────────

    suspend fun fetchMemories(): List<MemoryEntry> {
        val response: MemoriesResponse = get("api/memories")
        return response.memories
    }

    suspend fun updateMemory(id: String, request: MemoryUpdateRequest): MemoryEntry {
        return patch("api/memories/$id", request)
    }

    suspend fun deleteMemory(id: String) {
        deleteRequest<Unit>("api/memories/$id")
    }

    suspend fun sendMemoryFeedback(id: String, request: MemoryFeedbackRequest): MemoryEntry {
        return post("api/memories/$id/feedback", request)
    }

    // ─── HTTP Helpers ─────────────────────────────────────────────────────────

    private suspend inline fun <reified T> get(path: String): T {
        val response = try {
            http.get(url(path)) {
                applyAuth()
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: IOException) {
            throw ApiError.Network()
        } catch (e: Exception) {
            throw ApiError.Network(e.message ?: "Request failed")
        }
        return handleResponse(response)
    }

    private suspend inline fun <reified T, reified B> post(path: String, body: B): T {
        val response = try {
            http.post(url(path)) {
                applyAuth()
                contentType(ContentType.Application.Json)
                setBody(body)
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: IOException) {
            throw ApiError.Network()
        } catch (e: Exception) {
            throw ApiError.Network(e.message ?: "Request failed")
        }
        return handleResponse(response)
    }

    private suspend inline fun <reified T, reified B> patch(path: String, body: B): T {
        val response = try {
            http.patch(url(path)) {
                applyAuth()
                contentType(ContentType.Application.Json)
                setBody(body)
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: IOException) {
            throw ApiError.Network()
        } catch (e: Exception) {
            throw ApiError.Network(e.message ?: "Request failed")
        }
        return handleResponse(response)
    }

    private suspend inline fun <reified T> deleteRequest(path: String) {
        val response = try {
            http.delete(url(path)) {
                applyAuth()
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: IOException) {
            throw ApiError.Network()
        } catch (e: Exception) {
            throw ApiError.Network(e.message ?: "Request failed")
        }
        // Always check the response status, even for Unit-typed deletes
        handleResponse<Unit>(response)
    }

    private fun HttpRequestBuilder.applyAuth() {
        accessTokenProvider()?.let { token ->
            header(HttpHeaders.Authorization, "Bearer $token")
        }
    }

    private suspend inline fun <reified T> handleResponse(response: HttpResponse): T {
        return when {
            response.status == HttpStatusCode.Unauthorized -> throw ApiError.Unauthorized
            response.status.isSuccess() -> {
                if (T::class == Unit::class) Unit as T
                else response.body()
            }
            else -> {
                val envelope = runCatching { response.body<ApiErrorEnvelope>() }.getOrNull()
                throw ApiError.Server(envelope?.error ?: "Server error (${response.status.value})")
            }
        }
    }

    private fun url(path: String): String {
        val base = config.functionsBaseUrl.trimEnd('/')
        val cleanPath = path.trimStart('/')
        return "$base/$cleanPath"
    }
}

package com.nestmind.app.core.auth

import com.nestmind.app.core.config.AppConfig
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.storage.Storage
import java.io.Closeable

class SupabaseService(config: AppConfig) : Closeable {
    val client: SupabaseClient = createSupabaseClient(
        supabaseUrl = config.supabaseUrl,
        supabaseKey = config.supabaseAnonKey
    ) {
        install(Auth) {
            scheme = "nestmind"
            host = "auth-callback"
        }
        install(Storage)
    }

    override fun close() {
        client.close()
    }
}

import Foundation

struct EmptyResponse: Decodable {}

enum APIClientError: LocalizedError {
  case unauthorized
  case invalidResponse
  case server(String)

  var errorDescription: String? {
    switch self {
    case .unauthorized:
      return "Your session expired. Please sign in again."
    case .invalidResponse:
      return "The server returned an unexpected response."
    case .server(let message):
      return message
    }
  }
}

struct APIErrorEnvelope: Decodable {
  let error: String
}

final class APIClient {
  private let config: AppConfig
  private let accessTokenProvider: @MainActor () -> String?
  private let urlSession: URLSession
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init(
    config: AppConfig,
    accessTokenProvider: @escaping @MainActor () -> String?,
    urlSession: URLSession = .shared
  ) {
    self.config = config
    self.accessTokenProvider = accessTokenProvider
    self.urlSession = urlSession

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    self.encoder = encoder

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    self.decoder = decoder
  }

  func fetchProfile() async throws -> UserProfile {
    let response: ProfileResponse = try await request(path: "/v1/profile", method: "GET", body: Optional<String>.none)
    return response.profile
  }

  func updateProfile(_ requestBody: ProfileUpdateRequest) async throws -> UserProfile {
    let response: ProfileResponse = try await request(path: "/v1/profile", method: "PATCH", body: requestBody)
    return response.profile
  }

  func fetchMemories() async throws -> [MemoryEntry] {
    let response: MemoriesResponse = try await request(path: "/v1/memories", method: "GET", body: Optional<String>.none)
    return response.memories
  }

  func updateMemory(id: UUID, requestBody: MemoryUpdateRequest) async throws -> MemoryEntry {
    let response: MemoryEntry = try await request(path: "/v1/memories/\(id.uuidString)", method: "PATCH", body: requestBody)
    return response
  }

  func deleteMemory(id: UUID) async throws {
    let _: EmptyResponse = try await request(path: "/v1/memories/\(id.uuidString)", method: "DELETE", body: Optional<String>.none)
  }

  func sendMemoryFeedback(id: UUID, feedback: MemoryFeedbackRequest) async throws -> MemoryEntry {
    let response: MemoryEntry = try await request(path: "/v1/memories/\(id.uuidString)/feedback", method: "POST", body: feedback)
    return response
  }

  func fetchConversations(limit: Int = 1) async throws -> [ConversationSummary] {
    let response: ConversationsResponse = try await request(
      path: "/v1/conversations?limit=\(limit)",
      method: "GET",
      body: Optional<String>.none
    )
    return response.conversations
  }

  func fetchConversation(id: UUID) async throws -> ConversationDetail {
    let response: ConversationResponse = try await request(path: "/v1/conversations/\(id.uuidString)", method: "GET", body: Optional<String>.none)
    return response.conversation
  }

  func sendChat(requestBody: ChatRequest) async throws -> ChatResponse {
    try await request(path: "/v1/chat", method: "POST", body: requestBody)
  }

  func analyzeMedia(requestBody: MediaAnalyzeRequest) async throws -> MediaAnalyzeResponse {
    try await request(path: "/v1/media/analyze", method: "POST", body: requestBody)
  }

  private func request<Response: Decodable, Body: Encodable>(
    path: String,
    method: String,
    body: Body?
  ) async throws -> Response {
    let token = await accessTokenProvider()
    guard let token, !token.isEmpty else {
      throw APIClientError.unauthorized
    }

    let sanitizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
    let url = try makeURL(path: sanitizedPath)
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if let body {
      request.httpBody = try encoder.encode(body)
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    let (data, response) = try await urlSession.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIClientError.invalidResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      if httpResponse.statusCode == 401 {
        throw APIClientError.unauthorized
      }

      if let errorEnvelope = try? decoder.decode(APIErrorEnvelope.self, from: data) {
        throw APIClientError.server(errorEnvelope.error)
      }

      throw APIClientError.server(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
    }

    if Response.self == EmptyResponse.self {
      return EmptyResponse() as! Response
    }

    return try decoder.decode(Response.self, from: data)
  }

  private func makeURL(path: String) throws -> URL {
    let parts = path.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
    var components = URLComponents(url: config.functionsBaseURL, resolvingAgainstBaseURL: false)
    let basePath = config.functionsBaseURL.path.hasSuffix("/")
      ? String(config.functionsBaseURL.path.dropLast())
      : config.functionsBaseURL.path
    components?.path = "\(basePath)/\(parts[0])"

    if parts.count == 2 {
      components?.percentEncodedQuery = String(parts[1])
    }

    guard let url = components?.url else {
      throw APIClientError.invalidResponse
    }

    return url
  }
}

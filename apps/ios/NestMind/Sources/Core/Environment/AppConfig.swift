import Foundation

struct AppConfig {
  let supabaseURL: URL
  let supabasePublishableKey: String
  let functionsBaseURL: URL

  static func load(bundle: Bundle = .main) throws -> AppConfig {
    let supabaseURL = try urlValue("SUPABASE_URL", bundle: bundle)
    let publishableKey = try stringValue("SUPABASE_PUBLISHABLE_KEY", bundle: bundle)
    let functionsBaseURL = try urlValue("SUPABASE_FUNCTIONS_BASE_URL", bundle: bundle)
    return AppConfig(
      supabaseURL: supabaseURL,
      supabasePublishableKey: publishableKey,
      functionsBaseURL: functionsBaseURL
    )
  }

  private static func stringValue(_ key: String, bundle: Bundle) throws -> String {
    guard
      let raw = bundle.object(forInfoDictionaryKey: key) as? String,
      !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      throw AppConfigError.missingKey(key)
    }
    return raw
  }

  private static func urlValue(_ key: String, bundle: Bundle) throws -> URL {
    guard let url = URL(string: try stringValue(key, bundle: bundle)) else {
      throw AppConfigError.invalidURL(key)
    }
    return url
  }
}

enum AppConfigError: LocalizedError {
  case missingKey(String)
  case invalidURL(String)

  var errorDescription: String? {
    switch self {
    case .missingKey(let key):
      return "Missing configuration value for \(key)."
    case .invalidURL(let key):
      return "Invalid URL configured for \(key)."
    }
  }
}


import Foundation
import Supabase

final class SupabaseService {
  let client: SupabaseClient

  init(config: AppConfig) {
    client = SupabaseClient(
      supabaseURL: config.supabaseURL,
      supabaseKey: config.supabasePublishableKey
    )
  }
}


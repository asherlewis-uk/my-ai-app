package com.nestmind.app.core.config

import com.nestmind.app.BuildConfig

data class AppConfig(
    val supabaseUrl: String,
    val supabaseAnonKey: String,
    val functionsBaseUrl: String
) {
    init {
        require(supabaseUrl.isNotBlank() && !supabaseUrl.contains("your-project")) { 
            "SUPABASE_URL must be configured with a valid URL" 
        }
        require(supabaseAnonKey.isNotBlank() && !supabaseAnonKey.contains("your-anon-key")) { 
            "SUPABASE_ANON_KEY must be configured with a valid key" 
        }
        require(functionsBaseUrl.isNotBlank() && !functionsBaseUrl.contains("your-project")) { 
            "SUPABASE_FUNCTIONS_BASE_URL must be configured with a valid URL" 
        }
    }

    companion object {
        fun load(): AppConfig = AppConfig(
            supabaseUrl = BuildConfig.SUPABASE_URL,
            supabaseAnonKey = BuildConfig.SUPABASE_ANON_KEY,
            functionsBaseUrl = BuildConfig.SUPABASE_FUNCTIONS_BASE_URL
        )
    }
}

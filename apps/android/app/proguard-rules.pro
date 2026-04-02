# Keep Kotlin serialization metadata and serializers
-keepattributes *Annotation*, InnerClasses, Signature, Exceptions
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep app models and their serializers
-keep,includedescriptorclasses class com.nestmind.app.models.** { *; }
-keep,includedescriptorclasses class com.nestmind.app.**$$serializer { *; }
-keepclassmembers class com.nestmind.app.models.** {
    *** Companion;
}
-keepclasseswithmembers class com.nestmind.app.models.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Ktor - Only keep what is necessary for serialization and engines
-keep class io.ktor.client.engine.android.** { *; }
-keep class io.ktor.serialization.kotlinx.json.** { *; }

# Supabase - Keep auth and storage models
-keep class io.github.jan.supabase.auth.** { *; }
-keep class io.github.jan.supabase.storage.** { *; }

# Coroutines - Standard rules
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.coroutines.android.HandlerContext$Main {
  java.lang.String name;
}

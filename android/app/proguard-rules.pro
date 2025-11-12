# --- Rules for llama_flutter_android ---
# This is the most important rule. It keeps the entire plugin's code from being shrunk or obfuscated.
-keep class com.write4me.llama_flutter_android.** { *; }

# --- General Rules for Kotlin & Coroutines ---
# The plugin likely uses Kotlin coroutines (like DefaultDispatcher-worker-2 in your log).
# These rules prevent crashes related to Kotlin's internal workings.
-keepclasseswithmembers class kotlin.jvm.internal.Lambda {
    <fields>;
    <methods>;
}

-keep class kotlin.Metadata { *; }

-keepclassmembers public class * extends kotlin.coroutines.jvm.internal.BaseContinuationImpl {
    public <init>(kotlin.coroutines.Continuation);
}

-keepclassmembers class * implements kotlin.coroutines.Continuation {
    <fields>;
    <methods>;
}

# --- Keep Kotlin function callbacks (like the one that crashed) ---
-keep interface kotlin.jvm.functions.Function1 { *; }
-keep interface kotlin.jvm.functions.Function2 { *; }
# Add more (Function3, Function4...) if needed, but Function1 is in your log.
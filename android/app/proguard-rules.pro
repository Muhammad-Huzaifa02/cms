# Flutter Wrapper Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Firebase Rules & Reflection Attributes
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-dontwarn com.google.firebase.**

# Biometrics & Secure Storage
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Play Core / Deferred Components (optional, suppress warnings so unused code is pruned)
-dontwarn com.google.android.play.core.**

# Native library keep
-keepclasseswithmembernames class * {
    native <methods>;
}

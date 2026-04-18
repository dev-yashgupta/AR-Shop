# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Fix R8 missing Play Core classes (Flutter deferred components — not used in this app)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Hive
-keep class * extends com.google.flatbuffers.Table { *; }
-dontwarn com.google.flatbuffers.**

# AR Flutter Plugin
-keep class io.github.sceneview.** { *; }
-keep class com.google.ar.** { *; }
-dontwarn com.google.ar.**

# ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Model Viewer / WebView
-keep class org.chromium.** { *; }
-dontwarn org.chromium.**

# Keep all annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes InnerClasses

# Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable
-keep class * implements android.os.Parcelable { *; }
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Suppress all other warnings
-dontwarn **

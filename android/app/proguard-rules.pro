# Flutter default rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep re2j classes
-keep class com.google.re2j.** { *; }
-dontwarn com.google.re2j.**

# Keep JSoup
-keep class org.jsoup.** { *; }
-dontwarn org.jsoup.**

# Keep Rhino JavaScript engine
-keep class org.mozilla.javascript.** { *; }
-dontwarn org.mozilla.javascript.**
-keep class java.beans.** { *; }
-dontwarn java.beans.**

# Keep javax.script
-keep class javax.script.** { *; }
-dontwarn javax.script.**

# Keep Google Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
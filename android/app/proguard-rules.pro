# WorkManager and Room, pulled in transitively by the Google Mobile Ads SDK.
# R8 full mode (the default since AGP 8) strips the Room-generated database
# implementation that WorkManager instantiates by reflection, which crashes
# the app at startup before Flutter loads:
#   Unable to get provider androidx.startup.InitializationProvider
#   Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
# Keeping all of WorkManager fixes it; that rule already covers the
# generated WorkDatabase in androidx.work.impl, so it stands alone.
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# ML Kit and the document scanner plugin. flutter_doc_scanner 0.0.21 ships no
# consumer proguard rules and calls com.google.mlkit.vision.documentscanner
# classes reflectively (GmsDocumentScanning, GmsDocumentScanningResult). R8
# full mode renames them in release, so a scan fails immediately with a
# generic error before the camera even opens. Debug builds skip R8, which is
# why scanning worked there. Keep ML Kit and the plugin intact.
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class com.shirsh.flutter_doc_scanner.** { *; }
-dontwarn com.google.mlkit.**

# google_mlkit_text_recognition ships only the Latin model, but its plugin
# code references the other script recognizers. R8 fails the release build on
# the missing classes unless told they are absent on purpose. These rules are
# exactly what R8 generated in missing_rules.txt on 2026-07-14.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

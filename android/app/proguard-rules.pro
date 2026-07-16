# WorkManager and Room, pulled in transitively by the Google Mobile Ads SDK.
# R8 full mode (the default since AGP 8) strips the Room-generated database
# implementation that WorkManager instantiates by reflection, which crashes
# the app at startup before Flutter loads:
#   Unable to get provider androidx.startup.InitializationProvider
#   Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
# Keeping Room databases and the WorkManager internals fixes it.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

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

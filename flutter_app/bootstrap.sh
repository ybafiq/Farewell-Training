#!/usr/bin/env bash
# Creates the Android project scaffolding around lib/ and applies every setting
# ultralytics_yolo needs. Run it once, from inside flutter_app/.
#
#   bash bootstrap.sh
#   flutter run --release
#
# Safe to run again - it only ever adds what is missing.

set -euo pipefail

ORG="${ORG:-com.example}"
GREEN=$'\033[32m'; AMBER=$'\033[33m'; OFF=$'\033[0m'
say() { echo "  ${GREEN}OK${OFF}   $1"; }
note() { echo "  ${AMBER}NOTE${OFF} $1"; }

command -v flutter >/dev/null || { echo "flutter is not on your PATH. Install Flutter first."; exit 1; }

echo
echo "Flutter version in use:"
flutter --version | head -1
echo

# ---------------------------------------------------------------- scaffolding
if [ ! -d android ]; then
  echo "Creating the Android project files..."
  # Keeps our lib/ and pubspec.yaml, generates only what is missing.
  flutter create --org "$ORG" --platforms=android --project-name leaf_scanner .
  say "android/ created"
else
  say "android/ already exists - leaving it alone"
fi

GRADLE_KTS="android/app/build.gradle.kts"
GRADLE_GROOVY="android/app/build.gradle"
MANIFEST="android/app/src/main/AndroidManifest.xml"

# ------------------------------------------------------------- SDK levels
# ultralytics_yolo needs minSdk 23 and compileSdk 36.
if [ -f "$GRADLE_KTS" ]; then
  sed -i.bak -E 's/minSdk = [^ ]*/minSdk = 23/'                 "$GRADLE_KTS" || true
  sed -i.bak -E 's/compileSdk = [^ ]*/compileSdk = 36/'         "$GRADLE_KTS" || true
  sed -i.bak -E 's/targetSdk = [^ ]*/targetSdk = 36/'           "$GRADLE_KTS" || true
  rm -f "$GRADLE_KTS.bak"
  say "$GRADLE_KTS  ->  minSdk 23, compileSdk 36, targetSdk 36"
elif [ -f "$GRADLE_GROOVY" ]; then
  sed -i.bak -E 's/minSdkVersion .*/minSdkVersion 23/'          "$GRADLE_GROOVY" || true
  sed -i.bak -E 's/compileSdkVersion .*/compileSdkVersion 36/'  "$GRADLE_GROOVY" || true
  sed -i.bak -E 's/targetSdkVersion .*/targetSdkVersion 36/'    "$GRADLE_GROOVY" || true
  rm -f "$GRADLE_GROOVY.bak"
  say "$GRADLE_GROOVY  ->  minSdk 23, compileSdk 36, targetSdk 36"
else
  note "could not find android/app/build.gradle(.kts) - set minSdk 23 / compileSdk 36 by hand"
fi

# ----------------------------------------------------------- camera permission
if [ -f "$MANIFEST" ]; then
  if grep -q 'android.permission.CAMERA' "$MANIFEST"; then
    say "camera permission already declared"
  else
    # Insert immediately after the opening <manifest ...> tag.
    awk '
      /<manifest/ && !done {
        print
        print "    <uses-permission android:name=\"android.permission.CAMERA\" />"
        print "    <uses-feature android:name=\"android.hardware.camera\" android:required=\"true\" />"
        done = 1
        next
      }
      { print }
    ' "$MANIFEST" > "$MANIFEST.new" && mv "$MANIFEST.new" "$MANIFEST"
    say "camera permission added to AndroidManifest.xml"
  fi
else
  note "no AndroidManifest.xml found - add the CAMERA permission by hand"
fi

# -------------------------------------------------------------- proguard rules
PRO="android/app/proguard-rules.pro"
if ! grep -qs 'com.google.ai.edge.litert' "$PRO" 2>/dev/null; then
  cat >> "$PRO" <<'RULES'

# ultralytics_yolo / LiteRT - keep classes reached by JNI in release builds
-keep class com.google.ai.edge.litert.** { *; }
-keep interface com.google.ai.edge.litert.** { *; }
-dontwarn com.google.ai.edge.litert.**
-keep class org.tensorflow.** { *; }
-keep class com.ultralytics.** { *; }
-dontwarn org.tensorflow.**
RULES
  say "proguard rules appended (harmless if unused)"
fi

# ------------------------------------------------------------------ packages
flutter pub get >/dev/null
say "flutter pub get"

# -------------------------------------------------------------------- report
echo
if [ -f assets/models/leaf.tflite ]; then
  say "found assets/models/leaf.tflite - the app will use YOUR model"
else
  note "no assets/models/leaf.tflite found"
  note "the app will start anyway on a demo model and say so on screen"
  note "drop your trained model in as assets/models/leaf.tflite when ready"
fi

echo
echo "Now plug in an Android phone (USB debugging on) and run:"
echo
echo "    flutter run --release"
echo
echo "Use --release, not debug. Debug builds run the model several times slower"
echo "and will make your demo look bad."
echo

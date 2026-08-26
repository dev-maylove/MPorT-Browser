#!/usr/bin/env bash
# Fix Android toolchain after `flutter create` (Flutter 3.47+).
# AGP 9.1.1 | Kotlin 2.2.20 | Gradle 9.3.1 | builtInKotlin=true
set -euo pipefail
cd "$(dirname "$0")/.."

find android -name "*.gradle.kts" -type f -delete 2>/dev/null || true

cat > android/settings.gradle << 'SETEOF'
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "9.1.1" apply false
    id "org.jetbrains.kotlin.android" version "2.2.20" apply false
}

include ":app"
SETEOF

# App module: no kotlin-android plugin (Built-in Kotlin via AGP)
cat > android/app/build.gradle << 'APPEOF'
plugins {
    id "com.android.application"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "id.mport.browser"
    compileSdk flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId "id.mport.browser"
        minSdk 24
        targetSdk flutter.targetSdkVersion
        versionCode 3
        versionName "2.0.1"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled false
            shrinkResources false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {}
APPEOF

if [ -f android/app/src/main/AndroidManifest.xml ]; then
  sed -i 's/android:label="[^"]*"/android:label="MPorT Browser"/' android/app/src/main/AndroidManifest.xml || true
fi

cat > android/gradle.properties << 'GPEOF'
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
android.builtInKotlin=true
kotlin.version=2.2.20
GPEOF

mkdir -p android/gradle/wrapper
cat > android/gradle/wrapper/gradle-wrapper.properties << 'GWEOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.3.1-all.zip
GWEOF

mkdir -p test
cat > test/widget_test.dart << 'TESTEOF'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mport_browser/app.dart';

void main() {
  testWidgets('MPorT Browser app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MporTBrowserApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
TESTEOF

echo "Android toolchain fixed: AGP 9.1.1, Kotlin 2.2.20, Gradle 9.3.1, builtInKotlin=true"

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.connectinno.notes.connectinno_notes_app"

    // Derleme hedefleri
    compileSdk = 35
    ndkVersion = "27.0.12077973"   // <- Hata mesajındaki sürüm

    defaultConfig {
        applicationId = "com.connectinno.notes.connectinno_notes_app"
        minSdk = 23                 // <- firebase_auth gereği 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Not: şimdilik debug imzası ile; prod’da kendi signingConfig'ini ekle
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Java 17 önerilir (AGP 8+ için)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
}

flutter {
    source = "../.."
}

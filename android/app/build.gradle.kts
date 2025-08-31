plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.appyoloikan"

    // WAJIB: ikuti requirement plugin
    compileSdk = 36

    // WAJIB: jangan pakai flutter.ndkVersion (masih 26.x)
    ndkVersion = "27.0.12077973"

    // Pakai Java 17 agar kompatibel dg AGP/dep modern
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.appyoloikan"

        // WAJIB: override nilai default Flutter
        minSdk = 26
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

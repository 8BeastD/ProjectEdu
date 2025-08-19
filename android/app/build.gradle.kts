plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yuknow.projectedu.projectedu"

    // Use Flutter-provided SDK versions; override NDK to 27.x as required by plugins
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.yuknow.projectedu.projectedu"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    /**
     * IMPORTANT:
     * Resource shrinking requires code shrinking (minify) to be enabled.
     * To avoid the error you're seeing, keep shrinkResources = false
     * whenever isMinifyEnabled = false.
     */
    buildTypes {
        debug {
            // Flutter debug builds do not minify; keep resource shrink OFF
            isMinifyEnabled = false
            // This line fixes your error:
            isShrinkResources = false
        }
        release {
            // You can enable minify + shrink later for smaller APKs.
            // For now keep both off for a painless build.
            isMinifyEnabled = false
            isShrinkResources = false

            // TODO: replace with your real release signing config when ready
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ============================================================================
// REFERENCE: Android build.gradle.kts Integration
// ============================================================================
// 
// This file shows how to integrate BuildConfig values into your Android
// build.gradle. Use these as templates in your actual build.gradle.kts
//
// File: android/app/build.gradle.kts
// ============================================================================

plugins {
    id("com.android.application")
    kotlin("android")
    kotlin("plugin.serialization")
}

android {
    // ========================================================================
    // APPLICATION NAMESPACE (Package Identifier)
    // ========================================================================
    // Unique identifier for your app across all Android devices.
    // 
    // From BuildConfig: androidNamespace
    // - DEBUG:      com.example.form_fields_example.debug
    // - BETA:       com.example.form_fields_example.beta
    // - PRODUCTION: com.example.form_fields_example
    //
    // ⚠️ IMPORTANT: 
    //   - Never change after initial app release
    //   - Must match packageName in AndroidManifest.xml
    //   - Must match signing configuration
    // ========================================================================
    namespace = "com.example.form_fields_example.debug"

    // ========================================================================
    // TARGET ANDROID VERSION (compileSdk)
    // ========================================================================
    // The Android SDK version your app compiles against.
    // Use latest stable version: 34, 33, 32, 31...
    //
    // From BuildConfig: androidCompileSdk = 34
    //
    // Update when Google releases new Android versions:
    // - Android 14 (API 34)
    // - Android 13 (API 33)
    // - Android 12 (API 32)
    // ========================================================================
    compileSdk = 34

    // ========================================================================
    // NATIVE DEVELOPMENT KIT (ndkVersion)
    // ========================================================================
    // Version of the NDK for compiling native (C/C++) code.
    // Leave blank to use Gradle's default, or specify explicitly.
    //
    // From BuildConfig: ndkVersion = "27.0.12077973"
    //
    // Common versions:
    // - 27.0.12077973 (Latest)
    // - 26.1.10909125
    // - 25.2.9519653
    // ========================================================================
    ndkVersion = "27.0.12077973"

    // ========================================================================
    // DEFAULT BUILD CONFIGURATION
    // ========================================================================
    defaultConfig {
        // Application ID (Package Name)
        applicationId = "com.example.form_fields_example.debug"

        // ====================================================================
        // MINIMUM SDK VERSION (minSdk)
        // ====================================================================
        // Lowest Android version your app supports.
        //
        // From BuildConfig: androidMinSdk = 21
        //
        // - API 21 (Android 5.0 Lollipop)  - ~75% of devices
        // - API 24 (Android 7.0 Nougat)    - ~85% of devices
        // - API 26 (Android 8.0 Oreo)      - ~90% of devices
        //
        // Lower minSdk = larger audience but older device support required
        // ====================================================================
        minSdk = 21

        // ====================================================================
        // TARGET SDK VERSION (targetSdk)
        // ====================================================================
        // The Android version your app is designed for (and tested on).
        //
        // From BuildConfig: androidTargetSdk = 34
        //
        // Must be >= minSdk and <= compileSdk
        // Recommendation: Keep targetSdk == compileSdk
        //
        // Impacts:
        // - App Store requirements (must be recent)
        // - Runtime permissions (Android 6.0+)
        // - Background restrictions (Android 8.0+)
        // - Notification channels (Android 8.0+)
        // ====================================================================
        targetSdk = 34

        // ====================================================================
        // VERSION CODE
        // ====================================================================
        // Internal version number for app store ranking.
        // MUST INCREASE for each release (even on same version name).
        //
        // From BuildConfig: versionCode = 1
        //
        // Format: Integer (positive, up to 2^31-1)
        // Example progression: 1, 2, 3, 4, 5...
        //
        // Common strategies:
        // - Sequential: 1, 2, 3, 4... (simplest, recommended)
        // - Date-based: 202603021 (YYYYMMDDHH)
        // - Version-based: 10001 (major=1, minor=0, patch=001)
        // ====================================================================
        versionCode = 1

        // ====================================================================
        // VERSION NAME
        // ====================================================================
        // User-visible version number using semantic versioning.
        //
        // From BuildConfig: versionName = "1.0.0"
        //
        // Format: major.minor.patch[+meta]
        // Examples:
        // - 1.0.0      (Initial release)
        // - 1.0.1      (Bug fix)
        // - 1.1.0      (New feature)
        // - 2.0.0      (Major update)
        // - 1.0.0-beta (Pre-release beta)
        // - 1.0.0-rc1  (Release candidate)
        // ====================================================================
        versionName = "1.0.0"

        // ====================================================================
        // MAPS API KEY (through manifestPlaceholders)
        // ====================================================================
        // Google Maps API key embedded in AndroidManifest.xml
        //
        // From BuildConfig: androidMapsApiKey
        // - DEBUG:      "DEBUG_GOOGLE_MAPS_API_KEY"
        // - BETA:       "BETA_GOOGLE_MAPS_API_KEY"
        // - PRODUCTION: "PROD_GOOGLE_MAPS_API_KEY"
        //
        // Used in: android/app/src/main/AndroidManifest.xml
        // <meta-data
        //     android:name="com.google.android.geo.API_KEY"
        //     android:value="${MAPS_API_KEY}" />
        //
        // ⚠️ SECURITY: Never commit actual API keys!
        // Store in:
        // - local.properties (gitignored)
        // - CI/CD environment variables
        // - Gradle secrets plugin
        // ====================================================================
        manifestPlaceholders = [
            "MAPS_API_KEY": "DEBUG_GOOGLE_MAPS_API_KEY"
        ]

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    // ========================================================================
    // BUILD TYPES (Debug/Release)
    // ========================================================================
    buildTypes {
        release {
            // Optimizations for release builds
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // Override for production environment
            manifestPlaceholders = [
                "MAPS_API_KEY": "PROD_GOOGLE_MAPS_API_KEY"
            ]
        }

        debug {
            // Debug configuration
            isDebuggable = true
            manifestPlaceholders = [
                "MAPS_API_KEY": "DEBUG_GOOGLE_MAPS_API_KEY"
            ]
        }
    }

    // ========================================================================
    // COMPILE OPTIONS
    // ========================================================================
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    // ========================================================================
    // BUILD FEATURES
    // ========================================================================
    buildFeatures {
        // Enable view binding (optional)
        viewBinding = false
    }

    // ========================================================================
    // FLAVOR DIMENSIONS (Optional: for Debug/Beta/Prod)
    // ========================================================================
    // Uncomment to create build variants for different environments
    /*
    flavorDimensions += "environment"
    productFlavors {
        create("debug") {
            dimension = "environment"
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            
            buildFeatures {
                buildConfig = true
            }
            
            buildConfigField("String", "BASE_URL", "\"https://dummyjson.com/\"")
            buildConfigField("String", "API_KEY", "\"DEBUG_KEY\"")
        }
        
        create("beta") {
            dimension = "environment"
            applicationIdSuffix = ".beta"
            versionNameSuffix = "-beta"
            
            buildConfigField("String", "BASE_URL", "\"https://beta-api.dummyjson.com/\"")
            buildConfigField("String", "API_KEY", "\"BETA_KEY\"")
        }
        
        create("prod") {
            dimension = "environment"
            buildConfigField("String", "BASE_URL", "\"https://api.dummyjson.com/\"")
            buildConfigField("String", "API_KEY", "\"PROD_KEY\"")
        }
    }
    */
}

dependencies {
    // Android Core
    implementation("androidx.core:core-splashscreen:1.0.1")
    implementation("androidx.core:core:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    
    // Material Design
    implementation("com.google.android.material:material:1.11.0")
    
    // Flutter
    implementation(project(":flutter"))
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}

// ============================================================================
// SIGNING CONFIGURATION (for release builds)
// ============================================================================
// Configure your keystore for signing release APKs/bundles
/*
android {
    signingConfigs {
        release {
            storeFile = file("${project.projectDir}/keystore/release.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "password"
            keyAlias = System.getenv("KEY_ALIAS") ?: "release"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "password"
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.release
        }
    }
}
*/

// ============================================================================
// NOTES
// ============================================================================
// 
// 1. VERSION MANAGEMENT STRATEGY
//    - Increment versionCode for EVERY release
//    - Update versionName following semantic versioning
//    - Example: v1.0.0 (code 1) → v1.0.1 (code 2) → v1.1.0 (code 3)
//
// 2. SDK VERSIONS
//    - compileSdk: Use latest Android SDK (currently 34)
//    - targetSdk: Match compileSdk for best features and compliance
//    - minSdk: Support at least 2 major Android versions back (API 21+)
//
// 3. NAMESPACE/PACKAGE NAME
//    - Must be unique across Google Play
//    - Cannot change after initial release (rename app instead)
//    - Must match AndroidManifest.xml package attribute
//    - Use reverse domain notation: com.company.appname
//
// 4. ENVIRONMENT-SPECIFIC BUILDS
//    - Use productFlavors for Debug/Beta/Production
//    - Each flavor can have different:
//      * Application ID (allows multiple installs)
//      * Version name suffix
//      * Build configuration fields (API keys, endpoints)
//      * Signing configuration
//
// 5. API KEY SECURITY
//    - NEVER commit API keys to repository
//    - Use local.properties for local development
//    - Use CI/CD secrets for automated builds
//    - Rotate keys periodically
//    - Monitor API usage for anomalies
//
// 6. RELEASE CHECKLIST
//    - ✅ Increment versionCode
//    - ✅ Update versionName
//    - ✅ Verify targetSdk is latest
//    - ✅ Check all API keys are production keys
//    - ✅ Test on minSdk device (e.g., API 21)
//    - ✅ Run ProGuard/R8 obfuscation
//    - ✅ Sign with release keystore
//    - ✅ Test APK/AAB before upload
//
// ============================================================================

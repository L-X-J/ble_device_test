import com.android.build.gradle.internal.cxx.configure.gradleLocalProperties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "xyz.icxl.flutter.ble_manager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    val keystoreProperties = gradleLocalProperties(rootDir, providers)
    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties.getProperty("PackageSignature.storeFile"))
            storePassword = keystoreProperties.getProperty("PackageSignature.storePassword")
            keyPassword = keystoreProperties.getProperty("PackageSignature.keyPassword")
            keyAlias = keystoreProperties.getProperty("PackageSignature.keyAlias")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "xyz.icxl.flutter.ble_manager"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use(localProperties::load)
}

fun resolveSigningValue(envName: String, propertyName: String): String? {
    return providers.environmentVariable(envName).orNull
        ?: keystoreProperties.getProperty(propertyName)
}

fun resolveLocalValue(envName: String, propertyName: String): String? {
    return providers.environmentVariable(envName).orNull
        ?: localProperties.getProperty(propertyName)
}

val releaseStoreFile = resolveSigningValue("ANDROID_KEYSTORE_PATH", "storeFile")
    ?: resolveSigningValue("ANDROID_KEYSTORE_FILE", "storeFile")
val releaseStorePassword = resolveSigningValue("ANDROID_KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = resolveSigningValue("ANDROID_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = resolveSigningValue("ANDROID_KEY_PASSWORD", "keyPassword")
val defaultDebugAdmobAppId = "ca-app-pub-3940256099942544~3347511713"
val admobAndroidAppId = resolveLocalValue("ADMOB_ANDROID_APP_ID", "admobAndroidAppId")
val isReleaseBuildRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("release", ignoreCase = true) ||
        taskName.contains("bundle", ignoreCase = true)
}
val hasReleaseSigning = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

check(!isReleaseBuildRequested || !admobAndroidAppId.isNullOrBlank()) {
    "Missing Android AdMob app ID. Set ADMOB_ANDROID_APP_ID or admobAndroidAppId in android/local.properties before Android release builds."
}

android {
    namespace = "com.qila.chessiq"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.qila.chessiq"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobApplicationId"] =
            admobAndroidAppId ?: defaultDebugAdmobAppId
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = rootProject.file(requireNotNull(releaseStoreFile))
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}

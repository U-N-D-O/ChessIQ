import java.util.Properties
import java.util.Base64

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

fun decodeDartDefines(rawValue: String?): Map<String, String> {
    if (rawValue.isNullOrBlank()) {
        return emptyMap()
    }

    return rawValue.split(',')
        .filter { it.isNotBlank() }
        .mapNotNull { encodedEntry ->
            val decodedEntry = String(Base64.getUrlDecoder().decode(encodedEntry))
            val separatorIndex = decodedEntry.indexOf('=')
            if (separatorIndex <= 0) {
                null
            } else {
                decodedEntry.substring(0, separatorIndex) to
                    decodedEntry.substring(separatorIndex + 1)
            }
        }
        .toMap()
}

fun resolveAdmobValue(envName: String, dartDefines: Map<String, String>): String? {
    return providers.environmentVariable(envName).orNull
        ?: dartDefines[envName]?.takeIf { it.isNotBlank() }
}

val releaseStoreFile = resolveSigningValue("ANDROID_KEYSTORE_PATH", "storeFile")
    ?: resolveSigningValue("ANDROID_KEYSTORE_FILE", "storeFile")
val releaseStorePassword = resolveSigningValue("ANDROID_KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = resolveSigningValue("ANDROID_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = resolveSigningValue("ANDROID_KEY_PASSWORD", "keyPassword")
val defaultDebugAdmobAppId = "ca-app-pub-3940256099942544~3347511713"
val dartDefines = decodeDartDefines(providers.gradleProperty("dart-defines").orNull)
val admobAndroidAppId = resolveAdmobValue("ADMOB_ANDROID_APP_ID", dartDefines)
val forceTestAds = resolveAdmobValue("ADMOB_FORCE_TEST_ADS", dartDefines)
    ?.equals("true", ignoreCase = true) == true
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

check(!isReleaseBuildRequested || forceTestAds || !admobAndroidAppId.isNullOrBlank()) {
    "Missing Android AdMob app ID. Set ADMOB_ANDROID_APP_ID with --dart-define or environment variables before Android release builds, or set ADMOB_FORCE_TEST_ADS=true for sample ads."
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

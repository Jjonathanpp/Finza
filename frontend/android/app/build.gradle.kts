import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// La clave de firma de las APK que se publican (t-1.8.5). En GitHub Actions viene de los secrets del
// repo, como variables de entorno; en una compu, de android/key.properties (git lo ignora). Sin ninguna
// de las dos, la release se firma con la clave debug: sirve para probar, pero esa APK no se publica.
val propiedadesDeFirma = Properties().apply {
    val archivo = rootProject.file("key.properties")
    if (archivo.exists()) archivo.inputStream().use { load(it) }
}

fun datoDeFirma(propiedad: String, variable: String): String? =
    System.getenv(variable) ?: propiedadesDeFirma.getProperty(propiedad)

android {
    namespace = "com.finza.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.finza.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            datoDeFirma("storeFile", "ANDROID_KEYSTORE_PATH")?.let { ruta ->
                storeFile = file(ruta)
                storePassword = datoDeFirma("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = datoDeFirma("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = datoDeFirma("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            val deFinza = signingConfigs.getByName("release")
            signingConfig = if (deFinza.storeFile != null) deFinza else signingConfigs.getByName("debug")
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

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.hidden_role_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.hidden_role_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // مهم: بدونِ این بلوک، هر ماشین (خصوصاً هر اجرای تازه‌ی GitHub
    // Actions که هیچ‌وقت home قبلی نداره) یه debug.keystore تصادفیِ
    // خودش می‌سازه. یعنی هر بیلدِ CI امضای متفاوتی داشت و اندروید
    // نصبِ آپدیت رو رد می‌کرد («خطا میده» — باید اول حذف بشه). با این
    // بلوک، همه‌ی بیلدها (لوکال یا CI) از همین یه کیستورِ ثابتِ
    // چک‌شده‌ی تو ریپو (android/app/debug.keystore) استفاده می‌کنن.
    signingConfigs {
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

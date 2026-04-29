plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.skripsi_keuangan"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.skripsi_keuangan"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/LICENSE.md",
                "META-INF/LICENSE-notice.md",
                "META-INF/DEPENDENCIES"
            )
        }
    }
}

// 🔹 Tambahan untuk menekan warning compiler
tasks.withType<JavaCompile> {
    options.compilerArgs.addAll(listOf(
        "-Xlint:-unchecked",
        "-Xlint:-deprecation", 
        "-Xlint:-options",
        "-Xlint:-processing"
    ))
}

// 🔹 Suppress Gradle warnings
gradle.projectsEvaluated {
    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-nowarn")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")

    // Firebase
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // ML Kit contoh
    implementation("com.google.mlkit:barcode-scanning:17.2.0")
}

flutter {
    source = "../.."
}

// 🔹 Fix untuk APK output path
afterEvaluate {
    tasks.named("assembleDebug").configure {
        doLast {
            copy {
                from("build/outputs/flutter-apk/app-debug.apk")
                into("../../build/app/outputs/flutter-apk/")
            }
        }
    }
    
    tasks.named("assembleRelease").configure {
        doLast {
            copy {
                from("build/outputs/flutter-apk/app-release.apk")
                into("../../build/app/outputs/flutter-apk/")
            }
        }
    }
}

import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "dev.piaf.app"
    compileSdk {
        version = release(36) {
            minorApiLevel = 1
        }
    }

    defaultConfig {
        applicationId = "dev.piaf.app"
        minSdk = 31
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildFeatures {
        viewBinding = true
    }
}

tasks.register<Exec>("buildRustLibrary") {
    workingDir("../..")
    val androidHome = System.getenv("ANDROID_HOME")
        ?: System.getenv("ANDROID_SDK_ROOT")
        ?: run {
            val localProps = Properties()
            val localPropsFile = rootProject.file("local.properties")
            if (localPropsFile.exists()) localProps.load(localPropsFile.inputStream())
            localProps.getProperty("sdk.dir") ?: ""
        }
    environment("ANDROID_HOME", androidHome)
    environment("ANDROID_JAR", "$androidHome/platforms/android-36/android.jar")
    // Release APKs: every ABI, fully optimised. Debug APKs (`just`): the device
    // ABI only, with the incremental `android-dev` profile (see Cargo.toml).
    val releaseBuild = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
    val targets = if (releaseBuild) {
        listOf("-t", "arm64-v8a", "-t", "x86_64-linux-android")
    } else {
        listOf("-t", "arm64-v8a")
    }
    val profile = if (releaseBuild) listOf("--release") else listOf("--profile", "android-dev")
    commandLine(
        listOf("cargo", "ndk", "-o", "AndroidApp/app/src/main/jniLibs/") +
            targets + listOf("--platform", "31", "build", "--lib") + profile
    )
}

tasks.named("preBuild") {
    dependsOn("buildRustLibrary")
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    implementation(libs.androidx.constraintlayout)
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    implementation(libs.androidx.startup.runtime)
    implementation(libs.unifiedpush.connector)
}

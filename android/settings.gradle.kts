import java.io.File

// Patch .flutter-plugins-dependencies to avoid "dev_dependency" check failure in Flutter 3.24.3
run {
    val pluginsFile = File(settingsDir.parentFile, ".flutter-plugins-dependencies")
    if (pluginsFile.exists()) {
        val contents = pluginsFile.readText()
        if (contents.contains("\"android\":") && !contents.contains("\"dev_dependency\":")) {
            val patchedContents = contents.replace("\"native_build\":true", "\"native_build\":true,\"dev_dependency\":false")
                                         .replace("\"native_build\":false", "\"native_build\":false,\"dev_dependency\":false")
            if (patchedContents != contents) {
                pluginsFile.writeText(patchedContents)
            }
        }
    }
}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}

include(":app")

plugins {
    // Add the Flutter plugin here to bridge the Flutter SDK to Android
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
    id("dev.flutter.flutter-gradle-plugin") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep your custom build directory logic if you need it, 
// but ensure it doesn't conflict with Flutter's default output
rootProject.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir("../../build").get())

subprojects {
    project.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir(project.name).get())
    
    // Only add this if you have a specific reason to force evaluation order
    // Often, this is not needed for Flutter apps
    // project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
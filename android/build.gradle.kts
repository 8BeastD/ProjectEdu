// Top-level Gradle build file.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

/**
 * (Optional) Move build outputs to a single /build dir at the repo root.
 * Safe to keep — remove if you prefer default per-module build folders.
 */
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// agora_rtc_engine's own android/build.gradle reads this via
// safeExtGet('compileSdkVersion', 31) — setting it here, before any
// subproject is evaluated, fixes its AAR metadata compileSdk mismatch
// without needing afterEvaluate/projectsEvaluated timing hacks.
rootProject.extra["compileSdkVersion"] = 36
rootProject.extra["buildToolsVersion"] = "36.0.0"

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
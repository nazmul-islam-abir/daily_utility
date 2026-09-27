allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Force a consistent compileSdk / targetSdk across every plugin so a
    // package that hard-codes `compileSdk 37` (which on Windows gets
    // installed as `android-37.0`) still finds a valid target.
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.13.1")
        }
    }
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val ext = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            if (ext != null) {
                ext.compileSdkVersion(36)
            }
        }
    }
}

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

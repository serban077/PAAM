allprojects {
    repositories {
        google()
        mavenCentral()
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

// Kotlin 2.x dropped support for languageVersion < 1.8.
// posthog_flutter 4.x explicitly sets languageVersion = "1.6" in its own
// kotlinOptions afterEvaluate block. A root subprojects{} configureEach fires
// BEFORE that afterEvaluate, so posthog_flutter wins. gradle.afterProject fires
// AFTER each project's afterEvaluate, so our configureEach action is registered
// last and overrides the plugin's languageVersion / apiVersion settings.
gradle.afterProject {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_9)
            apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_9)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

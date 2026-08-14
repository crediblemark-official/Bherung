allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val buildDirLocation = File(System.getProperty("user.home"), ".cache/bherung_build")
rootProject.layout.buildDirectory.set(buildDirLocation)

subprojects {
    val subprojectBuildDir = File(buildDirLocation, project.name)
    project.layout.buildDirectory.set(subprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

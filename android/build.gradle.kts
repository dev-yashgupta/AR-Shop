allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force all subprojects (plugins) to compile against SDK 36
// This fixes android:attr/lStar not found in google_mlkit_commons and similar
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val setCompileSdk = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                setCompileSdk.invoke(androidExt, 36)
            } catch (_: Exception) {
                try {
                    val setCompileSdk = androidExt.javaClass.getMethod("compileSdk", Int::class.java)
                    setCompileSdk.invoke(androidExt, 36)
                } catch (_: Exception) { /* ignore */ }
            }
        }
    }
}

subprojects {
    afterEvaluate {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            val javaTaskName = name.replace("Kotlin", "JavaWithJavac")
            val javaTask = project.tasks.findByName(javaTaskName) as? org.gradle.api.tasks.compile.JavaCompile
            val fallbackJavaTarget = tasks.withType<org.gradle.api.tasks.compile.JavaCompile>()
                .firstOrNull()
                ?.targetCompatibility
                ?: JavaVersion.VERSION_17.toString()
            val javaTarget = javaTask?.targetCompatibility ?: fallbackJavaTarget

            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(javaTarget))
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

// Fixed Namespace Injection for older plugins
subprojects {
    val fixNamespace = {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension != null) {
            val extensionClass = androidExtension.javaClass
            try {
                val getNamespaceMethod = extensionClass.getMethod("getNamespace")
                val setNamespaceMethod = extensionClass.getMethod("setNamespace", String::class.java)
                
                if (getNamespaceMethod.invoke(androidExtension) == null) {
                    val namespace = "com.ar_shop.${project.name.replace("-", "_")}"
                    setNamespaceMethod.invoke(androidExtension, namespace)
                }
            } catch (e: Exception) {
                // Ignore if method is not found
            }
        }
    }

    if (project.state.executed) {
        fixNamespace()
    } else {
        project.afterEvaluate {
            fixNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

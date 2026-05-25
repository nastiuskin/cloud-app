# ── Stage 1: Build ─────────────────────────────────────────────────────────────
# Use a full JDK image to compile the project and produce the fat JAR
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app

# Copy Gradle wrapper and dependency descriptor files first.
# Docker caches each layer — if these files don't change, the next RUN
# (dependency download) is skipped on subsequent builds, saving time.
COPY gradlew .
COPY gradle gradle
COPY build.gradle.kts .
COPY settings.gradle.kts .
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

# Now copy the source code and build the fat JAR
COPY src src
RUN ./gradlew bootJar --no-daemon

# ── Stage 2: Runtime ───────────────────────────────────────────────────────────
# Use a minimal JRE-only image — no compiler, no Gradle, no source code.
# Result is ~200MB instead of ~600MB, faster to pull and smaller attack surface.
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

COPY --from=build /app/build/libs/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]

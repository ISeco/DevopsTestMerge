FROM maven:3.8.5-openjdk-17 AS build
WORKDIR /build
COPY . .
RUN mvn clean package

FROM openjdk:17-jdk-slim-bullseye
RUN addgroup -system devopsc && useradd -G devopsc javams
USER javams:devopsc
ENV JAVA_OPTS=""
COPY --from=build /build/target/*.jar app.jar
VOLUME /tmp
EXPOSE 9090
ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app.jar" ]
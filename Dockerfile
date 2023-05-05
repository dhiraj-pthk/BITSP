##########
# Extract
##########
FROM adoptopenjdk:11-jre-hotspot as extract

ARG JAR_SOURCE_PATH=./target/*.jar
ARG JAR_FILE_NAME=application.jar
WORKDIR /application
COPY ${JAR_SOURCE_PATH} ${JAR_FILE_NAME}
RUN java -Djarmode=layertools -jar ${JAR_FILE_NAME} extract


##########
# Runtime
##########
FROM adoptopenjdk/openjdk11:alpine-jre as runtime


USER 65532:65532

WORKDIR /application

# include each of the jar layers used in the application
COPY --from=extract application/dependencies/ ./
COPY --from=extract application/spring-boot-loader ./
COPY --from=extract application/snapshot-dependencies/ ./
#COPY --from=extract application/resources/ ./
COPY --from=extract application/application/ ./

ENTRYPOINT ["java", "--enable-preview", "org.springframework.boot.loader.JarLauncher"]


# build time labels as defined in https://github.com/opencontainers/image-spec/blob/master/annotations.md#pre-defined-annotation-keys
ARG BUILD_DATE=unspecified
ARG SOURCE_URL=unspecified
ARG SOURCE_REVISION=unspecified
ARG SOURCE_VERSION=unspecified
LABEL org.opencontainers.image.build-date=${BUILD_DATE} \
      org.opencontainers.image.source=${SOURCE_URL} \
      org.opencontainers.image.revision=${SOURCE_REVISION} \
      org.opencontainers.image.version=${SOURCE_VERSION}
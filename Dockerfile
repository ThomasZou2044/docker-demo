# 使用Maven OpenJDK Docker镜像作为构建环境
FROM maven:3.8.1-openjdk-17-slim AS build

# 复制pom.xml和源代码到Docker环境中
COPY ./pom.xml ./pom.xml
COPY ./src ./src

# 执行Maven构建命令
RUN mvn clean package -DskipTests

# 使用OpenJDK运行时镜像作为运行环境
FROM openjdk:17-jre-slim

# 复制从构建环境生成的jar文件到运行环境中
COPY --from=build /target/*.jar app.jar

# 运行Spring Boot应用
ENTRYPOINT ["java","-jar","/app.jar"]
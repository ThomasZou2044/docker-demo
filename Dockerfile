# 使用基础镜像，可以根据你的需求选择不同的基础镜像
FROM openjdk:11-jdk

# 设置工作目录
WORKDIR /app

# 将构建目录下的所有内容复制到容器的工作目录
COPY . /app

# 构建项目，这里假设你的Spring Boot项目使用的是Maven
RUN ./mvnw package

# 暴露容器内部的端口，如果你的Spring Boot应用程序使用的是不同的端口，请相应地更改
EXPOSE 8080

# 设置容器启动时执行的命令
CMD ["java", "-jar", "./target/docker-demo.jar"]
########## 1) BUILD STAGE (Maven) ##########
FROM maven:3.9.6-eclipse-temurin-17 AS build

# Set working directory inside container
WORKDIR /app

# Copy pom.xml first (helps with caching)
COPY pom.xml .

# Download dependencies (only if pom.xml changed)
RUN mvn dependency:go-offline -B

# Copy full source code
COPY src ./src

# Build WAR file
RUN mvn clean package -DskipTests


########## 2) RUNTIME STAGE (Tomcat) ##########
FROM tomcat:10.1-jdk17

# Remove default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR from the build stage
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8081

CMD ["catalina.sh", "run"]

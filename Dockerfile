FROM eclipse-temurin:17-jdk-alpine

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
    
EXPOSE 8080
 
ENV APP_HOME /usr/src/app

RUN mkdir -p $APP_HOME && chown -R appuser:appgroup $APP_HOME

USER appuser

COPY target/*.jar $APP_HOME/app.jar

WORKDIR $APP_HOME

CMD ["java", "-jar", "app.jar"]

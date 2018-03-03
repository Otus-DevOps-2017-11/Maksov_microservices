FROM alpine:latest

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292
ENV APP_HOME /app

RUN mkdir "$APP_HOME"
WORKDIR $APP_HOME
COPY . $APP_HOME

RUN apk update \
 && apk add --no-cache build-base \
                       ruby \
                       ruby-bundler \
                       ruby-dev \
                       ruby-json \
 && gem install bundler --no-ri --no-rdoc \
 && bundle install && apk del build-base ruby-dev \
 && rm -rf /usr/share/terminfo/ \
 && rm -rf /root/.bundle/cache/

CMD ["puma"]

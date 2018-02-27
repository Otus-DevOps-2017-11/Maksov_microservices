FROM alpine:latest


ENV POST_SERVICE_HOST=post
ENV POST_SERVICE_PORT=5000
ENV COMMENT_SERVICE_HOST=comment
ENV COMMENT_SERVICE_PORT=9292

WORKDIR /app

COPY . /app


RUN apk add --no-cache build-base ruby ruby-bundler ruby-dev ruby-json && \
    gem install bundler --no-ri --no-rdoc && bundle install && apk del build-base ruby-dev && \
    rm -rf /usr/share/terminfo/ && rm -rf /root/.bundle/cache/

CMD ["puma"]

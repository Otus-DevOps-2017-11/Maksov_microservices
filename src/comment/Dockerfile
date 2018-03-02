FROM alpine:latest


ENV COMMENT_DATABASE_HOST=comment_db
ENV COMMENT_DATABASE=comments

WORKDIR /app

COPY . /app

RUN apk add --no-cache build-base ruby ruby-bundler ruby-dev ruby-json && \
    gem install bundler --no-ri --no-rdoc && bundle install && apk del build-base ruby-dev && \
    rm -rf /usr/share/terminfo/ && rm -rf /root/.bundle/cache/

CMD ["puma"]

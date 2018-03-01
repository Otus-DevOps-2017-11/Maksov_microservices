FROM alpine:3.7


WORKDIR /reddit

COPY . /reddit

RUN apk add --no-cache build-base ruby ruby-bundler ruby-dev ruby-json && \
    gem install bundler --no-ri --no-rdoc && bundle install && apk del build-base ruby-dev && \
    rm -rf /usr/share/terminfo/ && rm -rf /root/.bundle/cache/

CMD ["puma"]





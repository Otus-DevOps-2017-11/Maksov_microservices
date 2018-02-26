FROM alpine:latest

WORKDIR /app
COPY . /app
RUN apk add --update --no-cache ruby \
                                ruby-json \
                                ruby-bundler \
                                gcc \
                                make \
                                g++ \
                                ruby-dev; \
\
gem install bundler json sinatra sinatra-contrib haml bson_ext mongo rest-client puma prometheus prometheus-client rufus-scheduler rack tzinfo-data foreman  --no-ri --no-rdoc; \
gem cleanup; \
apk del gcc make g++ ruby-dev ruby-bundler; \
rm -rf /usr/lib/ruby/gems/*/cache/* /var/cache/apk/* /tmp;

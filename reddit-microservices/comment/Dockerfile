FROM maksov/ruby-reddit:1.0

WORKDIR /app

ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

COPY . /app

CMD ["puma"]

# Maksov_microservices
---

## Homework № 14 Технология конейнерезации. Введение в Docker
---

Использованные в ходе выполнени команды

```
docker version
docker run hello-world - Запуск контейнера из образа
docker ps - Список запущенных контейнеров
docker images - Список образов
docker run -it ubuntu:16.04 /bin/bash
docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Names}}"
docker start - запуск остановленного контейнера
docker attach - подсоединение терминала к контейнеру
docker exec - запуск нового процесса внутри контейнера
docker commit - создает image из контейнера
docker inspect - low -level information about docker object
docker kill - посылает SIGKILL (безусловное завершение процесса)
docker stop - SIGTERM (остановка приложения)
docker system df - информация о дисковом пространстве (сколько занято образами, контейнерами, volume)
docker rm - удаление контейнера Ex: docker rm $(docker ps -a -q)
docker  rmi - удаление образа Ex: docker rmi $(docker images -q)
```

## Homework № 15 Docker контейнеры
---

Ход выполнения работы

 - создание проекта GCE

 - docker-machine

 ```
 docker-machine create --driver google \
  --google-project docker-181710 \
  --google-zone europe-west1-b \
  --google-machine-type g1-small \
  --google-machine-image $(gcloud compute images list --filter ubuntu-1604-lts --uri) \
  docker-host
 ```

 - Namespaces. docker run --rm --pid host -ti tehbilly/htop Контейнер запускается с Namespace хоста. Документация: 'host': use the host's PID namespace inside the container

 - docker build. Потребовалось повторный build выполнить. Из кэша брал. Использовал ключ --no-cache
 ```
 Сборка
 docker build -t reddit:latest .

 Запуск контейнера
 docker run --name reddit -d --network=host reddit:latest
 ```

 - Docker Hub. -> https://hub.docker.com/r/maksov/otus-reddit/
 ```
docker tag reddit:latest maksov/otus-reddit:1.0

docker push maksov/otus-reddit:1.0

 ```
## Homework № 16 Docker-образа. Микросервисы.

Ход выполнения работы

### Сборка образов
---
Для уменьшения размера образа были применены следующие практики:
-  использование минимального базового образа (в данном задании использую Alpine Linux)
- уменьшение количества слоев за счет группировки команд
- чистка мусора (кэш пакетного менеджера, ненужные файлы, пакеты)
- использование .Dockerignore (исключение из образа ненужных файлов при сборке и т.п.)

```
@FOR /f "tokens=*" %i IN ('docker-machine env docker-host') DO @%i
```
### Сборка сервиса post-py
---

```
FROM python:3.6.0-alpine

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts
WORKDIR /app
COPY . /app
# оптимизация команд
RUN pip install -r /app/requirements.txt

ENTRYPOINT ["python3", "post_app.py"]
```

### Сборка образа Ruby для последующей сборки
---
ruby/
```
FROM alpine:latest

WORKDIR /app
COPY . /app
# Установка Ruby, bundle-essential и дополнительных библиотек
RUN apk add --update --no-cache ruby \
                                ruby-json \
                                ruby-bundler \
                                gcc \
                                make \
                                g++ \
                                ruby-dev; \
\
# Установка gem пакетов
gem install bundler sinatra sinatra-contrib haml bson_ext mongo rest-client puma prometheus prometheus-client rufus-scheduler rack tzinfo-data foreman  --no-ri --no-rdoc; \
# Чистилище
gem cleanup; \
rm -rf /usr/lib/ruby/gems/*/cache/*; \
apk del build-base ruby-dev; \
rm -rf /var/cache/apk/* /tmp;
```
Размер образа - 42.6 Мб
### Собираем сервисы comment и ui
---
comment/
```
FROM maksov/ruby-reddit:2.0

WORKDIR /app

ENV COMMENT_DATABASE_HOST comment_db \
    COMMENT_DATABASE comments

COPY . /app

CMD ["puma"]
```
Размер - 42.6 Мб

ui/
```
FROM maksov/ruby-reddit:2.0

ENV POST_SERVICE_HOST post \
    POST_SERVICE_PORT 5000 \
    COMMENT_SERVICE_HOST comment \
    COMMENT_SERVICE_PORT 9292

WORKDIR /app
COPY . /app

CMD ["puma"]
```
Размер образа - 42.7 Мб

[docker images](https://prnt.sc/i9q44j)
### Запуск контейнеров
---
```
docker network create reddit
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post maksov/post:1.0
docker run -d --network=reddit --network-alias=comment maksov/comment:2.0
docker run -d --network=reddit -p 9292:9292 maksov/ui:3.0
```

### Задание со * Запуск контейнеров с другими alias
---
```
docker run -d --network=reddit --network-alias=microservice_post_db --network-alias=microservice_comment_db mongo:latest
docker run -d --network=reddit --network-alias=microservice_post --env POST_DATABASE_HOST=microservice_post_db maksov/post:1.0
docker run -d --network=reddit --network-alias=microservice_comment --env COMMENT_DATABASE_HOST=microservice_comment_db maksov/comment:2.0
docker run -d --network=reddit -p 9292:9292 --env COMMENT_SERVICE_HOST=microservice_comment --env POST_SERVICE_HOST=microservice_post maksov/ui:3.0
```

### Задание со * Сборка Alpine Linux + (код описан выше)

### Способы по уменьшению +

- Оптимизация команд за счет группировки
- Очистка мусора сборки

Multistage не знаю на сколько оптимален в данном случае. Так как код не компилируется.

### Создание и подключение volume

```
docker volume create reddit_db
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mongo:latest
```

[docker ps](https://prnt.sc/i9qta1)

### Ответ на вопросы:
---
Ask: Cборка ui началась не с первого шага. Почему? Answ: 1 шаг скачивание образа. Образ Ruby остался в кэше с предыдущего действия по build сервиса Comment.

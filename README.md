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

ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

COPY . /app

CMD ["puma"]
```
Размер - 42.6 Мб

ui/
```
FROM maksov/ruby-reddit:2.0

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

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

## Домашняя работа № 17  Docker: сети, docker-compose
---

Ход работы

Запуск контейнера с None network driver

```
docker run --network none --rm -d --name net_test joffotron/docker-net-tools -c "sleep 100"

docker exec -ti net_test
```

Запуск контейнера с Host network driver
```
docker run --network host --rm -d --name net_test joffotron/docker-net-tools -c "sleep 100"

docker exec -ti net_test ifconfig
docker-machine ssh docker-host ifconfig
? Сравнить вывод команд: драйвер дает контейнеру доступ к собственному пространству хоста

```

```
docker run --network host -d nginx

При повторном запуске nginx пытается забиндится к адрессу 0.0.0.0:80. Но ошибка - Address already in use

```

Docker networks

```
 sudo ln -s /var/run/docker/netns /var/run/netns

 sudo ip netns

 Посмотреть как меняется список Namespace

 ip netns exec namespace command -  позволит выполнить команды в выбранном namespace

 При запуске с Host network driver  контейнер запускается с net-namespace default (Хост)

  При запуске с None network driver  контейнер запускается с новым net-namespace

```

Bridge network driver

```
docker-machine ssh docker-host
sudo apt-get update && sudo apt-get install  bridge-utils
docker network ls - спсиок созданных сетей
ifconfig | grep br - список bridge-интерфейсов

```

```
sudo iptables -nL -t nat (флаг -v даст чуть больше инфы)
```

```
docker run -d --network=front_net -p 9292:9292 --name ui maksov/ui:3.0
docker run -d --network=back_net --name comment maksov/comment:2.0
docker run -d --network=back_net --name post maksov/post:1.0
docker run -d --network=back_net --name mongo_db --network-alias=post_db --network-alias=comment_db mongo:latest

Коннект сетей к контейнеру
> docker network connect front_net post
> docker network connect front_net comment

root     11488  0.0  0.1 108312  2680 ?        Sl   16:14   0:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 9292 -container-ip 10.0.1.2 -container-port 9292
```

### Docker-compose
---
1) Для реализации кейса с множеством сетей, сетевых алиасов в секции composefile были определены сети и прописаны настройки сетей с типом драйвера bridge, а также определены подсети. Aliases определены в каждома сервисе
```
example

services:
  post_db:
    networks:
      back_net:
        aliases:
          - post_db
          - comment_db

networks:
  front_net:
    driver: bridge
      ipam:
        driver: default
        config:
          - subnet: 10.0.1.0/24
```
2) Параметризированы:
- порт публикации сервиса ui. Порт контейнера не стал параметризировать, т.к. его задали в билде образа точно на 9292. хотя и его можно поменять конечно. но тогда и переменную COMMENT_SERVICE_PORT при запуске менять необходимо.
- тэги сервисов
- имя проекта (к вопросу как его можно менять, изначально оно определяется по имени папки, в котором располагается файл)
- имя пользователя на hub docker
- имя докер файла для билда
- также в файл был добавлен параметр depend_on для определения порядка запуска сервисов

### Задание со * Docker-compose override
---

Может конкретно для этого задания можно было просто монтированием папок на хосте выполнить, предварительно скопировав.

Но решил попробовать контейнерезацией данных. Идея была в том, что доставлять контейнер с кодом можно на множество одинаковых сервисов (в случае балансировки). Может конечно есть более оптимальное решение по типу storage-driver и хранение кода в облаке или в одном из поддерживаемых внешних хранилищ.

В итоге для каждого микросервиса собираю образ from scratch И в docker-compose.override.yml  монтирую каталоги к volumes и volumes монтирую уже к микросервисам.

Для проверки поменял немного view сервиса ui.

Для истории knowledge: возникла проблема запуска контейнера со сылк на невозможности запустить команду, т.к. не найден исполняемый путь. А также ошибки docker-compose получения объекта.
Решение: 1. Удалить volume с неправильной точкой монтирования. 2. Удалить контейнер.

## Домашняя работа № 19. Устройство  Gitlab CI. Построение процесса непрерывной интеграции.

Ход работы

### Создание виртуальной машины на GCE

```
Docker-machine

docker-machine create --drive google \
--google-zone europe-west1-b \
--google-zone europe-west1-b \
--google-machine-type g1-small \
--google-disk-type pd-standart \
--google-disk-size 100Gb \
--google-machine-image $(gcloud compute images list --filter ubuntu-1604-lts --uri) \
gitlab-runner

```

#### Docker-compose

```
web:
 image: 'gitlab/gitlab-ce:latest'
 restart: always
 hostname: 'gitlab.example.com'
 environment:
 GITLAB_OMNIBUS_CONFIG: |
 external_url 'http://http://35.189.219.174'
 ports:
  - '80:80'
  - '443:443'
  - '2222:22'
 volumes:
  - '/srv/gitlab/config:/etc/gitlab'
  - '/srv/gitlab/logs:/var/log/gitlab'
  - ‘/srv/gitlab/data:/var/opt/gitlab'

docker-compose up -d
```

#### GITLAB_RUNNER

```
docker run -d --name gitlab-runner --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest 

root@gitlab-ci:~# docker exec -it gitlab-runner gitlab-runner register
Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
http://<YOUR-VM-IP>/
Please enter the gitlab-ci token for this runner:
<TOKEN>
Please enter the gitlab-ci description for this runner:
[38689f5588fe]: my-runner
Please enter the gitlab-ci tags for this runner (comma separated):
linux,xenial,ubuntu,docker
Whether to run untagged builds [true/false]:
[false]: true
Whether to lock the Runner to current project [true/false]:
[true]: false
Please enter the executor:
docker
Please enter the default Docker image (e.g. ruby:2.1):
alpine:latest
Runner registered successfully.
```

```
stages:
 - build
 - test
 - deploy

variables:
 DATABASE_URL: 'mongodb://mongo/user_posts'

before_script:
 - cd reddit
 - bundle install 

build_job:
 stage: build
 script:
 - echo 'Building'

test_unit_job:
 stage: test
 script:
 - echo 'Testing 1'

test_integration_job:
 stage: test
 script:
 - echo 'Testing 2'

deploy_job:
 stage: deploy
 script:
 - echo 'Deploy'
```

#### Задание со * Gitlab Runner Autoscaling

Крутое задание. В принципе сразу было очевидно, что необходимо использовать данный способ. Но в плане настройки та еще запара. Хотя уже после настройки понятно, что довольно стандартно. Только четко и последовательно необходимо было выполнять. + ждем kubernetes, чтоб запробовать))
Машинки создаются(создал 3), потом по IdleTime удаляются.

Autoscaling предоставляет возможность использовтаь ресурсы более гибко и динамично.

При Autoscaling runners инфраструктура содержит столько build instances, сколько необходимо на текущий момент.

Предварительные подготовка Docker Regisrty и Cache Server

Дополним docker-compose

```
web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  hostname: 'gitlab.example.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
       external_url 'http://35.189.219.174'
      # Add any other gitlab.rb configuration here, each on its own line
  ports:
    - '80:80'
    - '443:443'
    - '23:22'
  volumes:
    - '/srv/gitlab/config:/etc/gitlab'
    - '/srv/gitlab/logs:/var/log/gitlab'
    - '/srv/gitlab/data:/var/opt/gitlab'
    
registry:
  image: registry:2
  restart: always
  environment:
    REGISTRY_PROXY_REMOTEURL: https://registry-1.docker.io
  ports:
    - '6000:5000'

# не забыть создать bucket в export
# AccessKey и SecretKey в 
cache:
  image: minio/minio:latest
  restart: always
  ports:
    - '9005:9000'
  volumes:
    - '/srv/cache/.minio:/root/.minio'
    - '/srv/cache/export:/export'
  command: ["server", "/export"]
    
runner:
  image: 'gitlab/gitlab-runner:latest'
  restart: always
  environment:
    - GOOGLE_APPLICATION_CREDENTIALS=/etc/gitlab-runner/docker.json
  volumes:
    - '/srv/gitlab-runner/config:/etc/gitlab-runner'

```

```
concurrent = 4 #Limits how many jobs globally can be run concurrently.   All registered Runners can run up to 50 concurrent builds

[[runners]]
  url = "http://35.189.219.174"
  token = "PRIVATE_TOKEN"
  name = "build-runner"
  executor = "docker+machine"
  [runners.docker]
    image = "alpine:latest"
  [runners.cache]
    Type = "s3"
    ServerAddress = "http://GITLAB-IP:9005"
    AccessKey = "AccessKey"
    SecretKey = "SecretKey"
    BucketName = "runner"
    Insecure = true #if the s3 service is available by HTTP
  [runners.machine]
    IdleCount = 0
    IdleTime = 200
    MachineDriver = "google"
    MachineName = "gitlab-runner-%s"
    MachineOptions = [
      "google-project = project_name",
      "google-machine-type=g1-small",
      "google-machine-image=ubuntu-os-cloud/global/images/ubuntu-1604-xenial-v20180126",
      "google-tags=default-allow-ssh",
      "google-zone=europe-west1-d",
      "google-use-internal-ip = True, # It’s useful for managing docker machines from another machine on the same network, such as when deploying swarm.
      "engine-registry-mirror=http://MY_REGISTRY_IP:6000"
    ]

```

Дополнительные параметры

limit = 10 - # (build+IdleCount) This Runner can execute up to 10 builds (created machines)

IdleCount = 5  # There must be 5 machines in Idle state - when Off Peak time mode is off



#### *Настройка в Slack

Все стандратно.
В Slack создали incoming-webhook
В Gitlab Project Setiing>Integretions->Slack notofications добавили URL Slack incoming webhook


## Домашняя работа № 20. Устройство  Gitlab CI. Построение процесса непрерывной интеграции.


###  Описание окружения

```
deploy_dev_job:
 stage: review
 script:
 - echo 'Deploy'
 environment:
 name: dev
 url: http://dev.example.com

```

### Ручной запуск окружения

```
 stage: stage
 when: manual
 script:
 - echo 'Deploy'
 environment:
 name: stage
 url: https://beta.example.com 

```
### Условия и ограничения
```
stage:
 stage: stage
 when: manual
 only:
 - /^\d+\.\d+.\d+/
 script:
 - echo 'Deploy'
 environment:
 name: stage
 url: https://beta.example.com 

```

### Динамические окружения

```
branch review:
 stage: review
 script: echo "Deploy to $CI_ENVIRONMENT_SLUG"
 environment:
 name: branch/$CI_COMMIT_REF_NAME
 url: http://$CI_ENVIRONMENT_SLUG.example.com
 only:
 - branches
 except:
 - master 
```

Задания со *


Сборка образа

```
build_job:
  image: 
  stage: build
  script:
    - docker build -t reddit:latest ./reddit
    - commit=$(echo ${CI_COMMIT_SHA} | sed -e 's/^\(.\{8\}\).*/\1/') 
    - DOCKER_IMAGE_HUB=${DOCKER_IMAGE_HUB}-${commit}
    - echo ${DOCKER_IMAGE_HUB}
    - docker tag reddit:latest ${DOCKER_IMAGE_HUB}
    - docker login -u maksov -p Pilotka21
    - docker push ${DOCKER_IMAGE_HUB}
```

Создание и деплой в одном db

```
branch_review:
  cache:
    untracked: true
    key: ${CI_BUILD_REF_NAME}
    paths:
      - cache/docker
  stage: review
  script: 
    - echo "Deploy to" ${CI_ENVIRONMENT_SLUG}
    - echo ${GCE_FILE} > docker.json
    - apk update &&  apk add ca-certificates curl py-pip
    - curl -s -L https://github.com/docker/machine/releases/download/v0.13.0/docker-machine-`uname -s`-`uname -m` > /tmp/docker-machine
    - install /tmp/docker-machine docker-machine
    - pip install docker-compose
    - ./docker-machine version
    - ./docker-machine -s ${CI_BUILD_REF_NAME} status ${VM_NAME} || ./docker-machine -s ${CI_BUILD_REF_NAME} create --driver google --google-project ${GCE_PROJECT_ID} 
      --google-zone europe-west1-b --google-machine-type g1-small
      --google-tags gitlab-deploy-agent
      --google-machine-image ${GCE_IMAGE_PATH}
      ${VM_NAME}
    - ./docker-machine -s ${CI_BUILD_REF_NAME} ls
    - CI_ENVIRONMENT_URL=http://$(./docker-machine -s ${CI_BUILD_REF_NAME} ip ${VM_NAME})
    - ./docker-machine -s ${CI_BUILD_REF_NAME} env --shell sh ${VM_NAME}
    - eval $(./docker-machine -s CERT_PATH env --shell sh ${VM_NAME})
    - docker ps
    - commit=$(echo ${CI_COMMIT_SHA} | sed -e 's/^\(.\{8\}\).*/\1/') 
    - DOCKER_IMAGE_HUB=${DOCKER_IMAGE_HUB}-${commit}
    - docker network create reddit
    - docker run -d  --network=reddit --network-alias=mongo_db mongo:3.2 
    - docker run -d --network=reddit -p 80:9292 ${DOCKER_IMAGE_HUB} --env DATABASE_URL=mongo_db
  environment:
    name: ${CI_COMMIT_REF_SLUG}
    on_stop: stop_review_app
  only:
    - branches
  except:
    - master
```

















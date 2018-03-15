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


## Домашняя работа № 20. Устройство Gitlab CI. Непрерывная поставка


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

## HW21 Введение в мониторинг. Системы мониторинга.

### План 

 - prometheus: запуск, конфигурация, знакомство с Web UI
 - мониторинг состояния микросервисов
 - сбор метрик хоста с использованием экспортера

#### Откроем порты 

- gcloud compute firewall-rules create prometheus-default --allow tcp:9090

- gcloud compute firewall-rules create puma-default --allow tcp:9292

#### Создадим машинку 

```
docker-machine create --driver google --google-machine-image  https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/
global/images/family/ubuntu-1604-lts --google-machine-type n1-standart-1 vm1

eval $(docker-machine env vm1)
```

#### Запуск системы мониторинга Prometheus

```
docker run --rm -p 9090:9090 -d --name prometheus prom/prometheus:v2.1.0

docker ps

docker-machine ip vm1
```

#### Результат вывода 

```
prometheus_build_info{branch="HEAD",goversion="go1.9.1",instanc
e="localhost:9090", job="prometheus", revision=
"3a7c51ab70fc7615cd318204d3aa7c078b7c5b20",version="1.8.1"} 1
```

#### Docker образ

```
monitoring/prometheus/Dockerfile
FROM prom/prometheus:v2.1.0
ADD prometheus.yml /etc/prometheus/
```


#### Конфигурация Prometheus

```
---

global:
  scrape_interval: '5s'

scrape_configs:
  
  - job_name: 'prometheus'
  static_configs:
    -targets:
      - 'localhost:9090'
  
  - job_name: 'ui'
  static_configs:
    -targets:
      - 'ui:9292'

  - job_name: 'comment'
  static_configs:
    - targets:
      - 'comment:9292'

```

#### Образы микросервисов

```
for i in ui post-py comment; do cd src/$i; bash
docker_build.sh; cd -; done
```

#### Docker-compose

```
services:
...
  prometheus:
    image: ${USER_NAME}/prometheus
    ports:
      - '9090:9090'
    volumes:
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention=1d'
  volumes:
    prometheus_data:
```

#### Сбор метрик хоста

В ситуациях, когда не можем реализовать отдачу метрик Prometheus в коде приложения, мы можем использовать экспортер, который будет транслировать метрики приложения или системы в формате доступном для чтения Prometheus.

Node-xporter для сбора информации о работе Docker хоста
```
services:

  node-exporter:
    image: prom/node-exporter:v0.15.2
    user: root
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command;
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)"'

  ```

Конфиг Prometheus
```
scrape_configs:
...
- job_name: 'node'
  static_configs:
    - targets:
      - 'node-exporter:9100'
```



#### Задание со * MongoDB Exporter

Использую готовый экспортер eses/mongodb_exporter:latest
```
mongodb-exporter:
    image: eses/mongodb_exporter:latest
    command: ["-mongodb.uri", "post_db"]
    networks:
      monitoring_net:
```

#### Задание со * Мониторинг сервисов с помощью Blackbox Exporter

Тут решил собрать 

```
Сборка осуществляется по следующему пути $HOME/go/src/github.com/prometheus

git clone https://github.com/prometheus/blackbox_exporter.git

make
```

Конфиг Prometheus

```
 - job_name: 'blackbox'
      metrics_path: /probe
      params:
        module: [http_2xx]
      static_configs:
        - targets:
          - http://comment:9292/healthcheck
          - http://post:5000/healthcheck
          - http://ui:9292
      relabel_configs:
        - source_labels: [__address__]
          target_label: __param_target
        - source_labels: [__param_target]
          target_label: instance
        - target_label: __address__
          replacement: blackbox-exporter:9115

```


Конфиг Docker Compose

```
blackbox-exporter:
    image: ${DOCKER_HUB_USERNAME}/blackbox_exporter:latest
    command:
      - '--config.file=/etc/blackbox_exporter/config.yml'
    networks:
      monitoring_net:

```

Дополнительно выделил в отдлебную сеть. Идею подсмотрел немного у andywow. Т.к. согласен, что мониторинг желательно вынести в отдедьную сеть. Но без алиасов. Все обращения по именам сервисов.

#### Задание со * Makefile


Сделан простейший топорный Makefile. К сожелению не хватает опыта.  Так кончено идеи есть что-нибудь униварсальное сделать. По типу указать директории по котрым должен проходить считывать список директорий (имена образов), а затем билдить образы.

## HW23 Введение в мониторинг. Системы мониторинга.

#### Подготовка окружения

```
export GOOGLE_PROJECT=_ваш_проект_
docker-machine create --driver google \
--google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
--google-machine-type n1-standard-1 \
vm1

eval $(docker-machine env vm1)

docker-machine ip vm1
```

#### cAdvisor

```
services:
...
  cadvisor:
    image: google/cadvisor:v0.29.0
    volumes:
      - '/:/rootfs:ro'
      - '/var/run:/var/run:rw'
      - '/sys:/sys:ro'
      - '/var/lib/docker/:/var/lib/docker:ro'
    ports:
      - '8080:8080'
```
#### Визуализация метрик
```
docker-compose -f docker-compose-monitoring.yml up -d grafana
```

#### Дашборды

Мониторинг работы приложения

```
scrape_configs:
...
 - job_name: 'post'
   static_configs:
    - targets:
    - 'post:5000'

```

```
Запрос перцентиля
rate(ui_request_count{http_status=~"^[45].*"}[1m])
```

95-й перцентиль
```
histogram_quantile(0.95, sum(rate(ui_request_latency_seconds_bucket[5m]) by (le)))
```

Бизнес метрики

```
rate(post_count[1h])
rate(comment_count[1h])

```


Alertmanager:

```
services:
...
alertmanager:
  image: ${USER_NAME}/alertmanager
  command:
    - '--config.file=/etc/alertmanager/config.yml'
  ports:
    - 9090:9093
```

Alerts.yml

```
groups:
  - name: alert.rules
    rules:
    - alert: InstanceDown
      expr: up
      for: 1m
      labels:
        severiity: page
      annotations:
        description: '{{ $labels.instance }} of job {{ $ $labels.job }} has been down for more than 1 minute'
        summary: 'Instance {{ $labels.instance }} down'
```


#### Задание со * Отдача Docker метрик в Prometheus

На Docker Host скопирован файл с настройкой 
{

  "metrics-addr": "0.0.0.0:9323",
  "experimental": true

}

#### Задание со * Алерты

```
groups:
 - name: alert.rules
   rules:
   - alert: InstanceDown
     expr: up == 0
     for: 1m
     labels:
      severity: page
     annotations:
      descriptions: '{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute'
      summary: 'Instance {{ $labels.instance }} down'
   - alert: UIResponseHigh
     expr: histogram_quantile(0.95, sum(rate(ui_request_latency_seconds_bucket[5m])) by (le)) > 0.5
     for: 1m
     annotations:
      descriptions: 'UI service takes long http responses'
      summary: 'High response time of UI service'
   - alert: DBLatency
     expr: histogram_quantile(0.95, sum(rate(post_read_db_seconds_bucket[5m])) by (le)) > 0.5
     for: 1m
     annotations:
      descriptions: '{{ $labels.instance }} has high latency from db'
      summary: 'High latency of db request on {{ $labels.instance }}'
```


#### Задание со * Интеграция Alertmanager

```
global:
  slack_api_url: 'https://hooks.slack.com/services/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'
  smtp_from: 'maksovotus@gmail.com'
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_auth_username: 'maksovotus@gmail.com'
  smtp_auth_identity: 'maksovotus@gmail.com'
  smtp_auth_password: 'secret'

route:
  receiver: 'notifications'


receivers:
  - name: 'notifications'
    slack_configs:
    - channel: '#maks-ovchinnikov'
    email_configs:
    - to: 'classic12@mail.ru'
```

#### Задание со * Автоматическое добавление в Grafana

Собираем образ с datasources и dashboards

Добавим пременную окружения DS_PROMETHEUS_SERVER чтоб подтянулись дашборды



#### Задание со * Реализуйте сбор метрик

Реализован VOUTE_COUNT

Можно еще бы время пребывания на странице (неплохая метрика). Но с ruby не знаком

```
<script language="JavaScript">
<!--//
startday = new Date();
clockStart = startday.getTime();

function initStopwatch() { 
var myTime = new Date();         
var timeNow = myTime.getTime();          
var timeDiff = timeNow - clockStart;         
this.diffSecs = timeDiff/1000;         
return(this.diffSecs); } 

function getSecs() {        
var mySecs = initStopwatch();         
var mySecs1 = ""+mySecs;         
mySecs1= mySecs1.substring(0,mySecs1.indexOf(".")) + " сек.";         
document.forms[0].timespent.value = mySecs1         
window.setTimeout('getSecs()',1000); }
// -->
</script>
```

#### Задание со * Сбор со Stackdriver


Сбор метрик стандартный по инструкции + network

```
  stackdriver:
    image: frodenas/stackdriver-exporter:latest
    environment:
      - GOOGLE_APPLICATION_CREDENTIALS=/tmp/docker-193409.json
      - STACKDRIVER_EXPORTER_GOOGLE_PROJECT_ID=docker-193409
      - STACKDRIVER_EXPORTER_MONITORING_METRICS_TYPE_PREFIXES=compute.googleapis.com/instance/cpu,compute.googleapis.com/instance/disk,compute.googleapis.com/instance/network
      - STACKDRIVER_EXPORTER_WEB_LISTEN_ADDRESS=stackdriver:9255
    volumes:
      - '/tmp/docker-193409.json:/tmp/docker-193409.json'
    networks:
      monitoring_net:

```
















































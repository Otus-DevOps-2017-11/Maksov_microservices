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

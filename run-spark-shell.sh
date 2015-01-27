#!/bin/bash

function master_hostname {
  echo `docker inspect -f '{{ .Config.Hostname }}' sparkmaster`
}

docker exec -t -i sparkmaster sh -c \
  "cd /usr/local/spark && ./bin/spark-shell --master spark://$(master_hostname):7077"

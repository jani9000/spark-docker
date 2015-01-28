#!/bin/bash

set -e

SLAVE_COUNT=2

# Run slaves.

for((i=1; i<=SLAVE_COUNT; i++))
do
  docker run \
    --name sparkslave$i \
    -p 22 \
    -p 7078 \
    -p 8081 \
    -d \
    -v $(pwd)/data:/var/spark/data \
    jani9000/spark-docker /sbin/my_init -- sh -c "tail -f /dev/null"
done

# Run master and link slaves.

function slave_links {
  for((i=1; i<=SLAVE_COUNT; i++))
  do
    echo "--link sparkslave$i:sparkslave$i "
  done
}

docker run \
  --name sparkmaster \
  -p 4040 \
  -p 7077 \
  -p 8080 \
  -d \
  $(slave_links) \
  -v ~/apps:/var/spark/apps \
  jani9000/spark-docker /sbin/my_init -- sh -c "cd /usr/local/spark && sbin/start-master.sh && tail -f /dev/null"

for((i=1; i<=SLAVE_COUNT; i++))
do
  docker exec -i sparkmaster sh -c "echo sparkslave$i >> /usr/local/spark/conf/slaves"
done

# Create master ssh key and distribute public key to slaves.

docker exec -i sparkmaster sh -c "ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"

docker cp sparkmaster:/root/.ssh/id_rsa.pub tmp/sparkmaster.pub

sparkmaster_hostname=`docker inspect -f '{{ .Config.Hostname }}' sparkmaster`
sparkmaster_ip=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' sparkmaster`

for((i=1; i<=SLAVE_COUNT; i++))
do
  docker exec -i sparkslave$i sh -c "cat >> /root/.ssh/authorized_keys" < tmp/sparkmaster.pub/id_rsa.pub
  docker exec -i sparkslave$i sh -c "dpkg-reconfigure openssh-server" # Create host keys.
  docker exec -i sparkslave$i sh -c "/usr/sbin/sshd"
  docker exec -i sparkslave$i sh -c "echo $sparkmaster_ip $sparkmaster_hostname >> /etc/hosts"
done

# Ask master to start slaves.

docker exec -i sparkmaster sh -c "cd /usr/local/spark && sbin/start-slaves.sh"

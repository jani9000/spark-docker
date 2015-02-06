#!/bin/bash

set -e

SLAVE_COUNT=2

echo "Starting spark slave containers."

for((i=1; i<=SLAVE_COUNT; i++))
do
  docker run \
    --name sparkslave$i \
    -p 22 \
    -p 7078 \
    -p 8081 \
    -p 50075 \
    -p 50010 \
    -p 50020 \
    -d \
    -v $(pwd)/data:/var/spark/data \
    jani9000/spark-docker /sbin/my_init -- sh -c "tail -f /dev/null"
done

echo "Starting spark master container."

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

echo "Starting Hadoop namenode container."

docker run \
  --name hadoopnamenode \
  -p 50070 \
  -p 9000 \
  -d \
  $(slave_links) \
  jani9000/spark-docker /sbin/my_init -- sh -c "tail -f /dev/null"

docker exec -i hadoopnamenode sh -c "rm \$HADOOP_CONF_DIR/slaves"

echo "Configuring slaves file for Spark."

for((i=1; i<=SLAVE_COUNT; i++))
do
  docker exec -i sparkmaster sh -c "echo sparkslave$i >> /usr/local/spark/conf/slaves"
done

echo "Configuring slaves file for Hadoop."

for((i=1; i<=SLAVE_COUNT; i++))
do
  docker exec -i hadoopnamenode sh -c "echo sparkslave$i >> /usr/local/hadoop/etc/hadoop/slaves"
done

echo "Configuring passwordless SSH from Spark master to Spark slaves."

docker exec -i sparkmaster sh -c "ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"

docker cp sparkmaster:/root/.ssh/id_rsa.pub tmp/sparkmaster.pub

sparkmaster_hostname=`docker inspect -f '{{ .Config.Hostname }}' sparkmaster`
sparkmaster_ip=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' sparkmaster`

for((i=1; i<=SLAVE_COUNT; i++))
do
  docker exec -i sparkslave$i sh -c "cat >> /root/.ssh/authorized_keys" < tmp/sparkmaster.pub/id_rsa.pub
  docker exec -i sparkslave$i sh -c "dpkg-reconfigure openssh-server" # Create host keys.
  docker exec -i sparkslave$i sh -c "/usr/sbin/sshd"
done

echo "Adding Spark master to slaves' hosts file."

for((i=1; i<=SLAVE_COUNT; i++))
do
  docker exec -i sparkslave$i sh -c "echo $sparkmaster_ip $sparkmaster_hostname >> /etc/hosts"
done

echo "Adding Hadoop namenode to hosts files on HDFS cluster."

hadoop_namenode_ip=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' hadoopnamenode`

docker exec -i hadoopnamenode sh -c "echo $hadoop_namenode_ip hadoopnamenode >> /etc/hosts"

for((i=1; i<=SLAVE_COUNT; i++))
do
  docker exec -i sparkslave$i sh -c "echo $hadoop_namenode_ip hadoopnamenode >> /etc/hosts"
done

echo "Formatting HDFS on Hadoop namenode."

docker exec -i hadoopnamenode sh -c "\$HADOOP_CONF_DIR/hadoop-init.sh"

echo "Starting HDFS datanodes."

for((i=1; i<=SLAVE_COUNT; i++))
do
  docker exec -i sparkslave$i sh -c "export USER=root; \$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config \$HADOOP_CONF_DIR --script hdfs start datanode"
done

echo "Starting HDFS namenode."

docker exec -i hadoopnamenode sh -c "export USER=root; \$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config \$HADOOP_CONF_DIR --script hdfs start namenode"

echo "Asking Spark master to start slaves."

docker exec -i sparkmaster sh -c "cd /usr/local/spark && sbin/start-slaves.sh"

#!/bin/bash
# Steps/commands for creating GP single node image. 


docker build --no-cache --pull -t='dockerfile0' -f dockerfile0 .

ID=`docker run -d --privileged dockerfile0 bash /gpinit.sh`

sleep 240 # let gpinit run

docker commit $ID dockerfile1

HOST=`echo -n $ID | cut -c-12`
cat >bash/docker_transient_hostname_workaround.sh <<EOF
echo "127.0.0.1 $HOST" >> /etc/hosts
EOF

docker build -f dockerfile2 -t registry.dataeng.io/docker-greenplum-singlenode:latest .


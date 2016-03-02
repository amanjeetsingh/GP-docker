#!/bin/bash
service sshd start >/dev/null 2>&1 &&\
chown -R gpadmin:gpadmin /home/gpadmin &&\
su gpadmin -l -c "gpssh-exkeys -h localhost" >/tmp/gpssh-exkeys.log 2>&1 &&\
sysctl -w kernel.shmmax=2147483648 >/tmp/sysctl.log 2>&1 &&\
cat /proc/sys/kernel/shmmax >>/tmp/sysctl.log 2>&1 &&\
su gpadmin -l -c "gpinitsystem -a -D -c /home/gpadmin/gpinitsystem_singlenode;exit 0" >/tmp/gpinit.log 2>&1

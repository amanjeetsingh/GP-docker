#!/bin/bash
set -e
# start sshd as GP communicates over ssh
service sshd start >/dev/null 2>&1
# make sure all files in /home/gpadmin belongs to gpadmin
chown -R gpadmin:gpadmin /home/gpadmin
# redo a ssh keyexchange
su gpadmin -l -c "gpssh-exkeys -h localhost" >/tmp/gpssh-exkeys.log 2>&1
# force shared memory settings to 2GB
sysctl -w kernel.shmmax=2147483648 >/tmp/sysctl.log 2>&1
cat /proc/sys/kernel/shmmax >>/tmp/sysctl.log 2>&1
# initialise gp
su gpadmin -l -c "gpinitsystem -a -D -c /home/gpadmin/gpinitsystem_singlenode;exit 0" >/tmp/gpinit.log 2>&1
# download and install postgis
curl -o /tmp/postgis-ossv2.0.3_pv2.0.1_gpdb4.3orca-rhel5-x86_64.gppkg http://copperfiles/fs/greenplum/postgis-ossv2.0.3_pv2.0.1_gpdb4.3orca-rhel5-x86_64.gppkg >>/tmp/curl.log 2>&1
su gpadmin -l -c "/usr/local/greenplum-db/bin/gppkg --install /tmp/postgis-ossv2.0.3_pv2.0.1_gpdb4.3orca-rhel5-x86_64.gppkg; exit 0" >/tmp/postgis_install.log 2>&1
rm -f /tmp/postgis-ossv2.0.3_pv2.0.1_gpdb4.3orca-rhel5-x86_64.gppkg
# cleanly stop
su gpadmin -l -c "gpstop -a" >/tmp/gpstop.log 2>&1

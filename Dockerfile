# Greenplum Database (GPDB) "Single Node" Docker container
# Forked from https://github.com/kevinmtrowbridge/greenplumdb_singlenode_docker

FROM centos:6.6
MAINTAINER "I&A Team"

ENV iag_proxy http://10.139.234.210:8080
ENV archive greenplum-db-4.3.5.2-build-1-RHEL5-x86_64.bin
ENV installPath /usr/local/greenplum-db-4.3.5.2

RUN http_proxy=$iag_proxy https_proxy=$iag_proxy yum update -y &&\
    http_proxy=$iag_proxy https_proxy=$iag_proxy yum install -y ed which tar sed openssh-server openssh-clients perl &&\
    yum clean all

# CUE GPADMIN USER
RUN groupadd -g 8000 gpadmin &&\
     useradd -m -s /bin/bash -d /home/gpadmin -g gpadmin -u 8000 gpadmin &&\
     mkdir -p /data/gpmaster /data/gpdata1 /data/gpdata2 &&\
     chown -R gpadmin:gpadmin /data

# NECESSARY: key exchange with ourselves - needed by single-node greenplum
RUN service sshd start && ssh-keygen -t rsa -q -f /root/.ssh/id_rsa -P "" &&\
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys &&\
  ssh-keyscan -t rsa localhost >> /etc/ssh/ssh_known_hosts


# get the greenplum archive and extract it
RUN curl -o ${archive} http://copperfiles.auiag.corp/fs/greenplum/${archive} &&\
    service sshd start &&\
    mkdir -p $installPath &&\
    tail -n +`awk '/^__END_HEADER__/ {print NR + 1; exit 0; }' "${archive}"` "${archive}" | tar zxf - -C ${installPath} &&\
    if [ ! -e `dirname ${installPath}`/greenplum-db ]; then ln -s ./`basename ${installPath}` `dirname ${installPath}`/greenplum-db;fi &&\
    sed -i "s,^GPHOME.*,GPHOME=${installPath}," ${installPath}/greenplum_path.sh &&\
    chown gpadmin.gpadmin ${installPath} &&\
    rm ${archive}

ENV GPHOME /usr/local/greenplum-db

WORKDIR /home/gpadmin
COPY bash/.gpadmin_bash_profile .bash_profile
COPY gpdb/hostlist_singlenode hostlist_singlenode
COPY gpdb/gpinitsystem_singlenode gpinitsystem_singlenode

RUN chown -R gpadmin:gpadmin /home/gpadmin &&\
    service sshd start &&\
    su gpadmin -l -c "gpssh-exkeys -h localhost"

# INITIALIZE GPDB SYSTEM
# HACK: note, capture of unique docker hostname -- at this point, the hostname gets embedded into the installation ... :(
RUN service sshd start &&\
 hostname > /docker_hostname_at_moment_of_gpinitsystem &&\
 su gpadmin -l -c "gpinitsystem -a -D -c /home/gpadmin/gpinitsystem_singlenode;"; exit 0;


# HACK: docker_transient_hostname_workaround, explanation:
#
# When gpinitsystem runs, it embeds the hostname (at that moment) into the installation.  Since Docker generates a new
# random hostname each time it runs, the hostname that is embedded, will never work again.  When you run `gpstart`, if
# the embedded hostname is not a valid DNS name, it will fail with this error:
#
# gpadmin-[ERROR]:-gpstart failed.  exiting...
# <snip>
#    addrinfo = socket.getaddrinfo(hostToPing, None)
# gaierror: [Errno -2] Name or service not known
#
# (You can reproduce this by removing the `docker_transient_hostname_workaround` bit from the CMD at the bottom.)
#
# So what we do here is to capture the random hostname at the moment that gpinitsystem is run, and later we can append
# it to /etc/hosts when we run `gpstart` -- this seems to keep it happy.
#
COPY bash/docker_transient_hostname_workaround.sh docker_transient_hostname_workaround.sh
RUN chmod +x docker_transient_hostname_workaround.sh

# install postgis extension
COPY postgis-ossv2.0.3_pv2.0.1_gpdb4.3orca-rhel5-x86_64.gppkg /tmp/
RUN ./docker_transient_hostname_workaround.sh && service sshd start &&\
    su gpadmin -l -c "gpstart -a --verbose" &&\
    sleep 120 &&\
    su gpadmin -l -c "/usr/local/greenplum-db/bin/gppkg --install /tmp/postgis-ossv2.0.3_pv2.0.1_gpdb4.3orca-rhel5-x86_64.gppkg; exit 0" &&\
    rm -f /tmp/postgis-ossv2.0.3_pv2.0.1_gpdb4.3orca-rhel5-x86_64.gppkg

# WIDE OPEN GPDB ACCESS PERMISSIONS
COPY gpdb/allow_all_incoming_pg_hba.conf /data/gpmaster/gpsne-1/pg_hba.conf
COPY gpdb/postgresql.conf /data/gpmaster/gpsne-1/postgresql.conf

EXPOSE 5432

# THIS DOCKER IMAGE WILL BE USED FOR TESTING SO WE DON'T CARE ABOUT THE DATA, AT ALL
# VOLUME ["/data"]


CMD ./docker_transient_hostname_workaround.sh && service sshd start &&\
    su gpadmin -l -c "gpstart -a --verbose" && sleep 86400 # HACK: it's difficult to get Docker to attach to the GPDB process(es) ... so, instead attach to process "sleep for 1 day"

# Greenplum Database (GPDB) 4.3.7.1 "Single Node" Dockerized (for testing purposes only)

Created in the persuit of an easily recreated test environment for a complicated application, which needs to communicate with a GPDB instance while running tests.

So, I jammed it into Docker, but this isn't something you'd want to use in a production
application.  But it seems to work for testing where you just want something that tests 
can execute against.

This is on Docker Hub here: https://hub.docker.com/r/kevinmtrowbridge/greenplumdb_singlenode/


## Running it

    docker run -i -p 5432:5432 -t kevinmtrowbridge/greenplumdb_singlenode

Proof -- login with psql:

    psql -h <docker machine ip / localhost> -p 5432 -U gpadmin template1


## Docker build

Download greenplum-db-appliance-4.3.7.1-build-1-RHEL5-x86_64.bin from Pivotal Network
https://network.pivotal.io/products/pivotal-gpdb#/releases/1377  
(This was working on 1/28/2016) ... and just place it in the repo root.

Then:

    docker build -t greenplumdb_singlenode .


## Discussion

Please see the Dockerfile for comments regarding the problems I had installing it on Docker and
how I hacked around them ...

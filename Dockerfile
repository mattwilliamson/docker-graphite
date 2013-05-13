FROM         ubuntu:12.04
MAINTAINER   Silas Sewell "silas@sewell.org"

RUN          echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN          apt-get update
INSERT       https://raw.github.com/silas/docker-graphite/master/setup.sh  /tmp/setup.sh
RUN          /bin/bash /tmp/setup.sh &> /tmp/setup.log

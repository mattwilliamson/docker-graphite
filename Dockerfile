from  ubuntu:12.04

run echo "deb http://archive.ubuntu.com/ubuntu precise main universe" >> /etc/apt/sources.list
run apt-get update
run apt-get install -y python-software-properties
insert https://raw.github.com/silas/docker-graphite/master/setup.sh /tmp/setup.sh
run bash /tmp/setup.sh

from         ubuntu:12.04
maintainer   Silas Sewell "silas@sewell.org"

#run          echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
#run          apt-get update
add       setup.sh /tmp/setup.sh
run          /bin/bash /tmp/setup.sh

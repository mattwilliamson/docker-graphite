#!/usr/bin/env bash

# https://gist.github.com/bhang/2703599

set -o errexit
set -o verbose

apt-get install -y python-software-properties python g++ make
apt-add-repository -y ppa:chris-lea/node.js
apt-get update

apt-get install -y \
  build-essential \
  git \
  libcairo2 \
  libcairo2-dev \
  memcached \
  pkg-config \
  python-cairo \
  python-dev \
  python-setuptools \
  git \
  sudo \
  wget \
  libssl-dev \
  sqlite3


easy_install pip

mkdir -p /usr/local/src/node
pushd /usr/local/src/node
wget http://nodejs.org/dist/v0.6.17/node-v0.6.17.tar.gz
tar -xzvf node-v0.6.17.tar.gz
cd node-v0.6.17
./configure
make
make install
popd



depsfile=$( tempfile )

cat << EOF > $depsfile
carbon==0.9.10
django-tagging
django==1.3
graphite-web==0.9.10
python-memcached
twisted
gunicorn
whisper==0.9.10
EOF

pip install -r $depsfile

rm -f $depsfile

pushd /opt/graphite/conf

cp -f carbon.conf.example carbon.conf

cat << EOF > storage-schemas.conf
[stats]
priority = 110
pattern = ^stats\..*
retentions = 10s:6h,1m:7d,10m:1y
EOF

popd

mkdir -p /opt/graphite/storage/log/webapp

pushd /opt/graphite/webapp/graphite

cp -f local_settings.py.example \
      local_settings.py

python manage.py syncdb --noinput

popd

git clone git://github.com/etsy/statsd.git /opt/statsd

pushd /opt/statsd

npm install

cat << EOF > config.js
{
  graphitePort: 2003,
  graphiteHost: "127.0.0.1",
  port: 8125,
  deleteCounters: true,
  flushInterval: 10 * 1000,
  graphite: {
    legacyNamespace: false,
  }
}
EOF

popd

chown -R www-data.www-data /opt/graphite/storage

cat << EOF > /etc/init/graphite-web.conf
description "graphite-web"

start on startup
stop on shutdown
respawn

script
    exec gunicorn_django \\
      --user www-data \\
      --group www-data \\
      --bind 0.0.0.0:80 \\
      --pid /tmp/gunicorn.pid \\
      /opt/graphite/webapp/graphite/settings.py
end script
EOF

cat << EOF > /etc/init/statsd.conf
description "statsd"

start on startup
stop on shutdown

script
    chdir /opt/statsd
    exec sudo -u www-data /opt/statsd/bin/statsd config.js
end script
EOF

cat << EOF > /etc/init/graphite-carbon-cache.conf
description "graphite-carbon-cache"

start on startup
stop on shutdown

expect daemon
respawn

exec start-stop-daemon \\
  --oknodo \\
  --chdir /opt/graphite \\
  --user www-data \\
  --chuid www-data \\
  --pidfile /opt/graphite/storage/carbon-cache-a.pid \\
  --name carbon-cache \\
  --startas /opt/graphite/bin/carbon-cache.py \\
  --start start
EOF

# Upstart+Docker Hack
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

service graphite-carbon-cache start
service graphite-web start
service statsd start

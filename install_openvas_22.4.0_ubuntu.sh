#!/bin/bash
set -x

#Creating a gvm system user and group
sudo useradd -r -M -U -G sudo -s /usr/sbin/nologin gvm || echo 'User already exists'

#Add current user to gvm group
sudo usermod -aG gvm $USER || echo 'User already in group'
#su $USER

#Setting an install prefix environment variable
export INSTALL_PREFIX=/usr/local

#Adjusting PATH for running gvmd
export PATH=$PATH:$INSTALL_PREFIX/sbin

#Choosing a source directory
export SOURCE_DIR=$HOME/source
mkdir -p $SOURCE_DIR

#Choosing a build directory
export BUILD_DIR=$HOME/build
mkdir -p $BUILD_DIR

#Choosing a temporary install directory
export INSTALL_DIR=$HOME/install
mkdir -p $INSTALL_DIR

#Installing common build dependencies
sudo apt update
sudo apt install --no-install-recommends --assume-yes \
  build-essential \
  curl \
  cmake \
  pkg-config \
  python3 \
  python3-pip \
  gnupg

#Importing the Greenbone Community Signing key
curl -f -L https://www.greenbone.net/GBCommunitySigningKey.asc -o /tmp/GBCommunitySigningKey.asc
gpg --import /tmp/GBCommunitySigningKey.asc

#Setting the trust level for the Greenbone Community Signing key
echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" > /tmp/ownertrust.txt
gpg --import-ownertrust < /tmp/ownertrust.txt

#Setting a GVM version as environment variable
export GVM_VERSION=22.4.1

#Setting the gvm-libs version to use
export GVM_LIBS_VERSION=22.4.4

#Required dependencies for gvm-libs
sudo apt install -y \
  libglib2.0-dev \
  libgpgme-dev \
  libgnutls28-dev \
  uuid-dev \
  libssh-gcrypt-dev \
  libhiredis-dev \
  libxml2-dev \
  libpcap-dev \
  libnet1-dev \
  libpaho-mqtt-dev

#Optional dependencies for gvm-libs
sudo apt install -y \
  libldap2-dev \
  libradcli-dev

#Downloading the gvm-libs sources
curl -f -L https://github.com/greenbone/gvm-libs/archive/refs/tags/v$GVM_LIBS_VERSION.tar.gz -o $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz

#Building gvm-libs
mkdir -p $BUILD_DIR/gvm-libs && cd $BUILD_DIR/gvm-libs

cmake $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DSYSCONFDIR=/etc \
  -DLOCALSTATEDIR=/var

make -j$(nproc)

#Installing gvm-libs
mkdir -p $INSTALL_DIR/gvm-libs
make DESTDIR=$INSTALL_DIR/gvm-libs install
sudo cp -rv $INSTALL_DIR/gvm-libs/* /

#Setting the gvmd version to use
export GVMD_VERSION=22.4.2

#Required dependencies for gvmd
sudo apt install -y \
  libglib2.0-dev \
  libgnutls28-dev \
  libpq-dev \
  postgresql-server-dev-14 \
  libical-dev \
  xsltproc \
  rsync \
  libbsd-dev \
  libgpgme-dev

#Optional dependencies for gvmd
sudo apt install -y --no-install-recommends \
  texlive-latex-extra \
  texlive-fonts-recommended \
  xmlstarlet \
  zip \
  rpm \
  fakeroot \
  dpkg \
  nsis \
  gnupg \
  gpgsm \
  wget \
  sshpass \
  openssh-client \
  socat \
  snmp \
  python3 \
  smbclient \
  python3-lxml \
  gnutls-bin \
  xml-twig-tools

#Downloading the gvmd sources
curl -f -L https://github.com/greenbone/gvmd/archive/refs/tags/v$GVMD_VERSION.tar.gz -o $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz

#Building gvmd
mkdir -p $BUILD_DIR/gvmd && cd $BUILD_DIR/gvmd

cmake $SOURCE_DIR/gvmd-$GVMD_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DLOCALSTATEDIR=/var \
  -DSYSCONFDIR=/etc \
  -DGVM_DATA_DIR=/var \
  -DGVMD_RUN_DIR=/run/gvmd \
  -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
  -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock \
  -DSYSTEMD_SERVICE_DIR=/lib/systemd/system \
  -DLOGROTATE_DIR=/etc/logrotate.d \
  -DPostgreSQL_TYPE_INCLUDE_DIR=/usr/include/postgresql

  make -j$(nproc)

#Installing gvmd
mkdir -p $INSTALL_DIR/gvmd
make DESTDIR=$INSTALL_DIR/gvmd install
sudo cp -rv $INSTALL_DIR/gvmd/* /

#Setting the pg-gvm version to use
export PG_GVM_VERSION=22.4.0

#Required dependencies for pg-gvm
sudo apt install -y \
  libglib2.0-dev \
  postgresql-server-dev-14 \
  libical-dev

#Downloading the pg-gvm sources
curl -f -L https://github.com/greenbone/pg-gvm/archive/refs/tags/v$PG_GVM_VERSION.tar.gz -o $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz

#Building pg-gvm
mkdir -p $BUILD_DIR/pg-gvm && cd $BUILD_DIR/pg-gvm

cmake $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION \
  -DCMAKE_BUILD_TYPE=Release \
  -DPostgreSQL_TYPE_INCLUDE_DIR=/usr/include/postgresql

make -j$(nproc)

#Installing pg-gvm
mkdir -p $INSTALL_DIR/pg-gvm
make DESTDIR=$INSTALL_DIR/pg-gvm install
sudo cp -rv $INSTALL_DIR/pg-gvm/* /

#Setting the GSA version to use
export GSA_VERSION=$GVM_VERSION

#Install nodejs 14
export NODE_VERSION=node_14.x
export KEYRING=/usr/share/keyrings/nodesource.gpg
export DISTRIBUTION="$(lsb_release -s -c)"

curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor | sudo tee "$KEYRING" >/dev/null
gpg --no-default-keyring --keyring "$KEYRING" --list-keys

echo "deb [signed-by=$KEYRING] https://deb.nodesource.com/$NODE_VERSION $DISTRIBUTION main" | sudo tee /etc/apt/sources.list.d/nodesource.list
echo "deb-src [signed-by=$KEYRING] https://deb.nodesource.com/$NODE_VERSION $DISTRIBUTION main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list

sudo apt update
sudo apt install -y nodejs

#Install yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt update
sudo apt install -y yarn

#Downloading the gsa sources
curl -f -L https://github.com/greenbone/gsa/archive/refs/tags/v$GSA_VERSION.tar.gz -o $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz

#Building gsa
cd $SOURCE_DIR/gsa-$GSA_VERSION

rm -rf build

yarn
yarn build

#Installing gsa
sudo mkdir -p $INSTALL_PREFIX/share/gvm/gsad/web/
sudo cp -rv build/* $INSTALL_PREFIX/share/gvm/gsad/web/

#Setting the GSAd version to use
export GSAD_VERSION=$GVM_VERSION

#Required dependencies for gsad
sudo apt install -y \
  libmicrohttpd-dev \
  libxml2-dev \
  libglib2.0-dev \
  libgnutls28-dev

#Downloading the gsad sources
curl -f -L https://github.com/greenbone/gsad/archive/refs/tags/v$GSAD_VERSION.tar.gz -o $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz

#Building gsad
mkdir -p $BUILD_DIR/gsad && cd $BUILD_DIR/gsad

cmake $SOURCE_DIR/gsad-$GSAD_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DSYSCONFDIR=/etc \
  -DLOCALSTATEDIR=/var \
  -DGVMD_RUN_DIR=/run/gvmd \
  -DGSAD_RUN_DIR=/run/gsad \
  -DLOGROTATE_DIR=/etc/logrotate.d

make -j$(nproc)

#Installing gsad
mkdir -p $INSTALL_DIR/gsad
make DESTDIR=$INSTALL_DIR/gsad install
sudo cp -rv $INSTALL_DIR/gsad/* /

#Setting the openvas-smb version to use
export OPENVAS_SMB_VERSION=22.4.0

#Required dependencies for openvas-smb
sudo apt install -y \
  gcc-mingw-w64 \
  libgnutls28-dev \
  libglib2.0-dev \
  libpopt-dev \
  libunistring-dev \
  heimdal-dev \
  perl-base

#Downloading the openvas-smb sources
curl -f -L https://github.com/greenbone/openvas-smb/archive/refs/tags/v$OPENVAS_SMB_VERSION.tar.gz -o $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz

#Building openvas-smb
mkdir -p $BUILD_DIR/openvas-smb && cd $BUILD_DIR/openvas-smb

cmake $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)

#Installing openvas-smb
mkdir -p $INSTALL_DIR/openvas-smb
make DESTDIR=$INSTALL_DIR/openvas-smb install
sudo cp -rv $INSTALL_DIR/openvas-smb/* /

#Setting the openvas-scanner version to use
export OPENVAS_SCANNER_VERSION=$GVM_VERSION

#Required dependencies for openvas-scanner
sudo apt install -y \
  bison \
  libglib2.0-dev \
  libgnutls28-dev \
  libgcrypt20-dev \
  libpcap-dev \
  libgpgme-dev \
  libksba-dev \
  rsync \
  nmap \
  libjson-glib-dev \
  libbsd-dev

#Debian optional dependencies for openvas-scanner
sudo apt install -y \
  python3-impacket \
  libsnmp-dev

#Downloading the openvas-scanner sources
curl -f -L https://github.com/greenbone/openvas-scanner/archive/refs/tags/v$OPENVAS_SCANNER_VERSION.tar.gz -o $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz

#Building openvas-scanner
mkdir -p $BUILD_DIR/openvas-scanner && cd $BUILD_DIR/openvas-scanner

cmake $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DSYSCONFDIR=/etc \
  -DLOCALSTATEDIR=/var \
  -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock \
  -DOPENVAS_RUN_DIR=/run/ospd

make -j$(nproc)

#Installing openvas-scanner
mkdir -p $INSTALL_DIR/openvas-scanner
make DESTDIR=$INSTALL_DIR/openvas-scanner install
sudo cp -rv $INSTALL_DIR/openvas-scanner/* /

#Setting the ospd and ospd-openvas versions to use
export OSPD_OPENVAS_VERSION=22.4.6

#Required dependencies for ospd-openvas
sudo apt install -y \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-packaging \
  python3-wrapt \
  python3-cffi \
  python3-psutil \
  python3-lxml \
  python3-defusedxml \
  python3-paramiko \
  python3-redis \
  python3-gnupg \
  python3-paho-mqtt

#Downloading the ospd-openvas sources
curl -f -L https://github.com/greenbone/ospd-openvas/archive/refs/tags/v$OSPD_OPENVAS_VERSION.tar.gz -o $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz

#Installing ospd-openvas
cd $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION
mkdir -p $INSTALL_DIR/ospd-openvas
python3 -m pip install --root=$INSTALL_DIR/ospd-openvas --no-warn-script-location .
sudo cp -rv $INSTALL_DIR/ospd-openvas/* /

#Setting the notus version to use
export NOTUS_VERSION=22.4.4

#Required dependencies for notus-scanner
sudo apt install -y \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-paho-mqtt \
  python3-psutil \
  python3-gnupg

#Downloading the notus-scanner sources
curl -f -L https://github.com/greenbone/notus-scanner/archive/refs/tags/v$NOTUS_VERSION.tar.gz -o $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz
tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz

#Installing notus-scanner
cd $SOURCE_DIR/notus-scanner-$NOTUS_VERSION
mkdir -p $INSTALL_DIR/notus-scanner
python3 -m pip install --root=$INSTALL_DIR/notus-scanner --no-warn-script-location .
sudo cp -rv $INSTALL_DIR/notus-scanner/* /

#Required dependencies for greenbone-feed-sync
sudo apt install -y \
  python3 \
  python3-pip

#Installing greenbone-feed-sync system-wide for all users
mkdir -p $INSTALL_DIR/greenbone-feed-sync
python3 -m pip install --root=$INSTALL_DIR/greenbone-feed-sync --no-warn-script-location greenbone-feed-sync
sudo cp -rv $INSTALL_DIR/greenbone-feed-sync/* /

#Required dependencies for gvm-tools
sudo apt install -y \
  python3 \
  python3-pip \
  python3-venv \
  python3-setuptools \
  python3-packaging \
  python3-lxml \
  python3-defusedxml \
  python3-paramiko

#Installing gvm-tools for the current user
python3 -m pip install --user gvm-tools

#Installing gvm-tools system-wide
mkdir -p $INSTALL_DIR/gvm-tools
python3 -m pip install --prefix=$INSTALL_PREFIX --root=$INSTALL_DIR/gvm-tools --no-warn-script-location gvm-tools
sudo cp -rv $INSTALL_DIR/gvm-tools/* /

#Installing gvm-tools system-wide
mkdir -p $INSTALL_DIR/gvm-tools
python3 -m pip install --root=$INSTALL_DIR/gvm-tools --no-warn-script-location gvm-tools
sudo cp -rv $INSTALL_DIR/gvm-tools/* /

#Installing the Redis server
sudo apt install -y redis-server

#Adding configuration for running the Redis server for the scanner
sudo cp $SOURCE_DIR/openvas-scanner-$GVM_VERSION/config/redis-openvas.conf /etc/redis/
sudo chown redis:redis /etc/redis/redis-openvas.conf
echo "db_address = /run/redis-openvas/redis.sock" | sudo tee -a /etc/openvas/openvas.conf

#Start redis with openvas config
sudo systemctl start redis-server@openvas.service

#Ensure redis with openvas config is started on every system startup
sudo systemctl enable redis-server@openvas.service

#Adding the gvm user to the redis group
sudo usermod -aG redis gvm

#Installing the Mosquitto broker
sudo apt install -y mosquitto

#Starting the broker and adding the server uri to the openvas-scanner configuration
sudo systemctl start mosquitto.service
sudo systemctl enable mosquitto.service
echo "mqtt_server_uri = localhost:1883\ntable_driven_lsc = yes" | sudo tee -a /etc/openvas/openvas.conf

#Adjusting directory permissions
sudo mkdir -p /var/lib/notus
sudo mkdir -p /run/gvmd

sudo chown -R gvm:gvm /var/lib/gvm
sudo chown -R gvm:gvm /var/lib/openvas
sudo chown -R gvm:gvm /var/lib/notus
sudo chown -R gvm:gvm /var/log/gvm
sudo chown -R gvm:gvm /run/gvmd

sudo chmod -R g+srw /var/lib/gvm
sudo chmod -R g+srw /var/lib/openvas
sudo chmod -R g+srw /var/log/gvm

#Adjusting gvmd permissions
sudo chown gvm:gvm /usr/local/sbin/gvmd
sudo chmod 6750 /usr/local/sbin/gvmd

#Adjusting feed sync script permissions
sudo chown gvm:gvm /usr/local/bin/greenbone-feed-sync
sudo chmod 740 /usr/local/bin/greenbone-feed-sync

#Creating a GPG keyring for feed content validation
export GNUPGHOME=/tmp/openvas-gnupg
mkdir -p $GNUPGHOME

gpg --import /tmp/GBCommunitySigningKey.asc
gpg --import-ownertrust < /tmp/ownertrust.txt

export OPENVAS_GNUPG_HOME=/etc/openvas/gnupg
sudo mkdir -p $OPENVAS_GNUPG_HOME
sudo cp -r /tmp/openvas-gnupg/* $OPENVAS_GNUPG_HOME/
sudo chown -R gvm:gvm $OPENVAS_GNUPG_HOME

#Setting up sudo for Scanning
echo '# allow users of the gvm group run openvas' >> /etc/sudoers
echo '%gvm ALL = NOPASSWD: /usr/local/sbin/openvas' >> /etc/sudoers

#Installing the PostgreSQL server
sudo apt install -y postgresql

#Starting the PostgreSQL database server
sudo systemctl start postgresql@14-main

#Setting up PostgreSQL user and database for the Greenbone Community Edition
sudo su - postgres -c 'createuser -DRS gvm'
sudo su - postgres -c 'createdb -O gvm gvmd'
sudo su - postgres -c 'psql gvmd -c "create role dba with superuser noinherit; grant dba to gvm;"'

#Creating an administrator user with generated password
/usr/local/sbin/gvmd --create-user=admin --password=admin

#Setting the Feed Import Owner
/usr/local/sbin/gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value `/usr/local/sbin/gvmd --get-users --verbose | grep admin | awk '{print $2}'`

#Systemd service file for ospd-openvas
cat << EOF > $BUILD_DIR/ospd-openvas.service
[Unit]
Description=OSPd Wrapper for the OpenVAS Scanner (ospd-openvas)
Documentation=man:ospd-openvas(8) man:openvas(8)
After=network.target networking.service redis-server@openvas.service mosquitto.service
Wants=redis-server@openvas.service mosquitto.service notus-scanner.service
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
Group=gvm
RuntimeDirectory=ospd
RuntimeDirectoryMode=2775
PIDFile=/run/ospd/ospd-openvas.pid
ExecStart=/usr/local/bin/ospd-openvas --foreground --unix-socket /run/ospd/ospd-openvas.sock --pid-file /run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-openvas.log --lock-file-dir /var/lib/openvas --socket-mode 0o770 --mqtt-broker-address localhost --mqtt-broker-port 1883 --notus-feed-dir /var/lib/notus/advisories
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

#Install systemd service file for ospd-openvas
sudo cp -v $BUILD_DIR/ospd-openvas.service /etc/systemd/system/

#Systemd service file for notus-scanner
cat << EOF > $BUILD_DIR/notus-scanner.service
[Unit]
Description=Notus Scanner
Documentation=https://github.com/greenbone/notus-scanner
After=mosquitto.service
Wants=mosquitto.service
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
RuntimeDirectory=notus-scanner
RuntimeDirectoryMode=2775
PIDFile=/run/notus-scanner/notus-scanner.pid
ExecStart=/usr/local/bin/notus-scanner --foreground --products-directory /var/lib/notus/products --log-file /var/log/gvm/notus-scanner.log
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

#Install systemd service file for notus-scanner
sudo cp -v $BUILD_DIR/notus-scanner.service /etc/systemd/system/

#Systemd service file for gvmd
cat << EOF > $BUILD_DIR/gvmd.service
[Unit]
Description=Greenbone Vulnerability Manager daemon (gvmd)
After=network.target networking.service postgresql.service ospd-openvas.service
Wants=postgresql.service ospd-openvas.service
Documentation=man:gvmd(8)
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
Group=gvm
PIDFile=/run/gvmd/gvmd.pid
RuntimeDirectory=gvmd
RuntimeDirectoryMode=2775
ExecStart=/usr/local/sbin/gvmd --foreground --osp-vt-update=/run/ospd/ospd-openvas.sock --listen-group=gvm
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

#Install systemd service file for gvmd
sudo cp -v $BUILD_DIR/gvmd.service /etc/systemd/system/

#Systemd service file for gsad
cat << EOF > $BUILD_DIR/gsad.service
[Unit]
Description=Greenbone Security Assistant daemon (gsad)
Documentation=man:gsad(8) https://www.greenbone.net
After=network.target gvmd.service
Wants=gvmd.service

[Service]
Type=exec
User=gvm
Group=gvm
RuntimeDirectory=gsad
RuntimeDirectoryMode=2775
PIDFile=/run/gsad/gsad.pid
ExecStart=/usr/local/sbin/gsad --foreground --listen=0.0.0.0 -port=9392 --http-only
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
Alias=greenbone-security-assistant.service
EOF

#Install systemd service file for gsad
sudo cp -v $BUILD_DIR/gsad.service /etc/systemd/system/

#Making systemd aware of the new service files
sudo systemctl daemon-reload

#Ensuring services are run at every system startup
sudo systemctl enable notus-scanner
sudo systemctl enable ospd-openvas
sudo systemctl enable gvmd
sudo systemctl enable gsad

#Downloading the data from the Greenbone Community Feed
sudo -u gvm greenbone-nvt-sync
sudo -u gvm greenbone-feed-sync --type GVMD_DATA
sudo -u gvm greenbone-feed-sync --type SCAP
sudo -u gvm greenbone-feed-sync --type CERT

#Once you've finished the feed synchronisation, generate GVM certificates.
sudo -u gvm gvm-manage-certs -a

#Finally starting the services
sudo systemctl start notus-scanner
sudo systemctl start ospd-openvas
sudo systemctl start gvmd
sudo systemctl start gsad

#!/bin/sh

source /usr/local/bin/env_secrets_expand.sh

set -e

ROOT=/var/www/html
CONFIG_BIN=${ROOT}/phorge/bin/config
REPO_USER=$(stat -c '%U' /var/repo)

# PHP Configuration
# -------------------------------------------------------------------------------

echo "creating PHP config files"

# https://github.com/php/php-src/blob/master/php.ini-production
# https://www.php.net/manual/en/ini.list.php
cat > "/usr/local/etc/php/conf.d/php-ph.ini" <<EOF
[PHP]
post_max_size = ${POST_MAX_SIZE:-32M}
upload_max_filesize = ${UPLOAD_MAX_FILESIZE:-32M}
memory_limit = ${MEMORY_LIMIT:-1024M}
expose_php = ${EXPOSE_PHP:-off}
opcache.memory_consumption=${OPCACHE_MEMORY_CONSUMPTION:-128}
opcache.max_accelerated_files=${OPCACHE_MAX_ACCELERATED_FILES:-10000}
opcache.enable_cli=${OPCACHE_ENABLE_CLI:-1}
opcache.validate_timestamps=${OPCACHE_VALIDATE_TIMESTAMPS:-0}
[Date]
date.timezone = ${DATE_TIMEZONE:-America/Los_Angeles}
[mysqli]
mysqli.allow_local_infile = ${MYSQLI_ALLOW_LOCAL_INFILE:-0}
EOF

# https://www.php.net/manual/en/install.fpm.configuration.php
sed -i "s/pm =.*/pm = ${FPM_PM:-ondemand}/" /usr/local/etc/php-fpm.d/www.conf
sed -i "s/pm.max_children =.*/pm.max_children = ${FPM_MAX_CHILDREN:-10}/" /usr/local/etc/php-fpm.d/www.conf
sed -i "s/pm.start_servers =.*/pm.start_servers = ${FPM_START_SERVERS:-3}/" /usr/local/etc/php-fpm.d/www.conf
sed -i "s/pm.min_spare_servers =.*/pm.min_spare_servers = ${FPM_MIN_SPARE_SERVERS:-1}/" /usr/local/etc/php-fpm.d/www.conf
sed -i "s/pm.max_spare_servers =.*/pm.max_spare_servers = ${FPM_MAX_SPARE_SERVERS:-2}/" /usr/local/etc/php-fpm.d/www.conf
sed -i "s/;pm.max_requests =.*/pm.max_requests = ${FPM_MAX_REQUESTS:-500}/" /usr/local/etc/php-fpm.d/www.conf
sed -i "s/;pm.process_idle_timeout =.*/pm.process_idle_timeout = ${FPM_PROCESS_IDLE_TIMEOUT:-10s}/" /usr/local/etc/php-fpm.d/www.conf

# -------------------------------------------------------------------------------

echo "creating other config files"

# create sudo config
cat > "/etc/sudoers.d/vcs-sudo" <<EOF
vcs ALL=(phuser) SETENV: NOPASSWD: /usr/bin/git, /usr/bin/git-upload-pack, /usr/bin/git-receive-pack, /usr/bin/svnserve, /usr/bin/hg
www-data ALL=(phuser) SETENV: NOPASSWD: /usr/bin/git, /usr/bin/git-http-backend, /usr/bin/hg
EOF

# create sshd config
# https://www.ssh.com/academy/ssh/sshd_config
# https://www.freebsd.org/cgi/man.cgi?sshd_config(5)
cat > "/etc/ssh/sshd_config.phorge" <<EOF
AuthorizedKeysCommand /usr/libexec/phorge_ssh_hook.sh
AuthorizedKeysCommandUser vcs
AllowUsers vcs

HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

Port ${PH_DIFFUSION_SSH_PORT:-2530}
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
MaxAuthTries ${PH_SSH_MAX_AUTH_TRIES:-3}
LoginGraceTime ${PH_SSH_LOGIN_GRACE_TIME:-30}
AuthorizedKeysFile none
AllowAgentForwarding no
AllowTcpForwarding no
AllowStreamLocalForwarding no
GatewayPorts no
PermitTunnel no
PrintMotd no
PermitUserEnvironment no
PermitTTY no

PidFile /var/run/sshd-phorge.pid
EOF

# create ssh hook
cat > "/usr/libexec/phorge_ssh_hook.sh" <<'EOF'
#!/bin/sh

if [ "$1" != "vcs" ];
then
  exit 1
fi

exec "/var/www/html/phorge/bin/ssh-auth" $@
EOF

if [ ! -d "${ROOT}/arcanist" ]; then
   echo "cloning arcanist"
   sudo -n -u www-data git clone --branch master --depth 1 --shallow-submodules https://we.phorge.it/source/arcanist.git
fi

if [ ! -d "${ROOT}/phorge" ]; then
   echo "cloning phorge"
   sudo -n -u www-data git clone --branch master --depth 1 --shallow-submodules https://we.phorge.it/source/phorge.git
fi

# upgrade repos
if [ "${UPGRADE_ON_RESTART}" = "true" ]; then
   echo "updating arcanist and phorge"
  
   cd $ROOT/arcanist
   sudo -n -u www-data git pull

   cd $ROOT/phorge
   sudo -n -u www-data git pull
fi

# -------------------------------------------------------------------------------

echo "configuring phorge"

# start configuration of phorge with docker environment variables
sudo -n -u www-data ${CONFIG_BIN} set phd.user phuser

sudo -n -u www-data ${CONFIG_BIN} set diffusion.ssh-port ${PH_DIFFUSION_SSH_PORT:-2530}

sudo -n -u www-data ${CONFIG_BIN} set diffusion.ssh-user vcs

sudo -n -u www-data ${CONFIG_BIN} set phabricator.base-uri ${PH_BASE_URI:-https://phorge.yourdomain.test}

sudo -n -u www-data ${CONFIG_BIN} set mysql.pass ${PH_MYSQL_PASS:-CHANGEME}

sudo -n -u www-data ${CONFIG_BIN} set mysql.user ${PH_MYSQL_USER:-root}

sudo -n -u www-data ${CONFIG_BIN} set mysql.host ${PH_MYSQL_HOST:-mariadb}

sudo -n -u www-data ${CONFIG_BIN} set storage.mysql-engine.max-size ${PH_STORAGE_MYSQL_ENGINE_MAX_SIZE:-8388608}

sudo -n -u www-data ${CONFIG_BIN} set pygments.enabled true

if [ "${PH_METAMTA_DEFAULT_ADDRESS}" != "" ]
then
    sudo -n -u www-data ${CONFIG_BIN} set metamta.default-address ${PH_METAMTA_DEFAULT_ADDRESS}
fi

if [ "${PH_CLUSTER_MAILERS}" = "true" ]
then
    sudo -n -u www-data ${CONFIG_BIN} set --stdin cluster.mailers < /usr/src/docker_ph/mailers.json
fi

# set permissions for ssh hook
chown root /usr/libexec/phorge_ssh_hook.sh
chmod 755 /usr/libexec/phorge_ssh_hook.sh

# set permissions for sudo
chmod 440 /etc/sudoers.d/vcs-sudo

# storage upgrade
echo "updating ${PH_MYSQL_HOST:-mariadb}"
echo "waiting for ${PH_MYSQL_HOST:-mariadb}:3306"
/usr/local/bin/wait-for.sh ${PH_MYSQL_HOST:-mariadb}:3306 -- echo 'success'
echo "let ${PH_MYSQL_HOST:-mariadb} warm up"
sleep 10s
$ROOT/phorge/bin/storage upgrade --force

# generate ssh keys if needed
if [ ! -e /etc/ssh/ssh_host_rsa_key ] || [ ! -e /etc/ssh/ssh_host_ecdsa_key ] || [ ! -e /etc/ssh/ssh_host_ed25519_key ]
then
   ssh-keygen -A
fi

# change owner of repo directory
if [ "${REPO_USER}" != "phuser" ]; then
  chown -R phuser /var/repo/
fi

# start sshd
/usr/sbin/sshd -e -f /etc/ssh/sshd_config.phorge

# start phorge tasks
sudo -E -n -u phuser /var/www/html/phorge/bin/phd start

exec "$@"

#!/usr/bin/env bash

# Set password variables
DB_ROOT_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c32 | tr -d '-')
MEMCACHED_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c16 | tr -d '-')
PHPMYADMIN_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c32 | tr -d '-')
DEFAULT_ROOT_PASSWORD='vagrant'
NEW_ROOT_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c32 | tr -d '-')

# Environment settings
POSTFIX_HOSTNAME='nullclient.com'
EMAIL_ADDRESS='chase@nullclient.com'

# Set folder structure/version variables
SOURCE_FOLDER='/usr/local/src'
NGINX_CONF_FOLDER='/etc/nginx'
NGINX_WEB_ROOT='/usr/local/nginx/html'
PAGESPEED_VERSION='1.9.32.3'
NGINX_VERSION='1.8.0'

# Set functions
function outputMessage {
	echo "$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)#/\ $(tput sgr0)$(tput setab 0)$(tput setaf 7)$(tput smul)$1$(tput sgr0)"
}

function execCommand {
	echo "$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)-----> $(tput sgr0)$(tput setab 0)$(tput setaf 7)$1$(tput sgr0)"
	eval $1
}

function outputForComplicatedCommand {
	echo "$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)-----> $(tput sgr0)$(tput setab 0)$(tput setaf 7)$1$(tput sgr0)"
}

# Update server
outputMessage 'Updating the server'
execCommand "apt-get update > /dev/null"

# Install dependencies
outputMessage 'Installing dependencies'
execCommand "apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev unzip libssl-dev curl git software-properties-common > /dev/null 2>&1"

# Compile, and install nginx/pagespeed
# See https://developers.google.com/speed/pagespeed/module/build_ngx_pagespeed_from_source
# pagespeed version 1.9.32.3, psol version 1.9.32.3, nginx version 1.8.0
outputMessage 'Downloading, compiling and installing nginx with pagespeed from source'
execCommand "cd $SOURCE_FOLDER"
execCommand "wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${PAGESPEED_VERSION}-beta.zip > /dev/null 2>&1"
execCommand "unzip release-${PAGESPEED_VERSION}-beta.zip > /dev/null"
execCommand "cd ngx_pagespeed-release-${PAGESPEED_VERSION}-beta"
execCommand "wget https://dl.google.com/dl/page-speed/psol/${PAGESPEED_VERSION}.tar.gz > /dev/null 2>&1"
execCommand "tar -xzvf ${PAGESPEED_VERSION}.tar.gz > /dev/null"
execCommand "cd $SOURCE_FOLDER"
execCommand "wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz > /dev/null 2>&1"
execCommand "tar -xvzf nginx-${NGINX_VERSION}.tar.gz > /dev/null"
execCommand "cd nginx-${NGINX_VERSION}"
execCommand "./configure --user=www-data --group=www-data --conf-path=${NGINX_CONF_FOLDER}/nginx.conf --with-pcre-jit --with-http_ssl_module --with-http_spdy_module --with-http_realip_module --add-module=${SOURCE_FOLDER}/ngx_pagespeed-release-${PAGESPEED_VERSION}-beta > /dev/null"
execCommand "make > /dev/null"
execCommand "make install > /dev/null"

# Clone base files from git repo
outputMessage 'Cloning base files from https://github.com/TimeTravelersHackMe/Ubuntu-Development-Server-Setup.git'
execCommand "cd $SOURCE_FOLDER"
execCommand "rm -rf ubuntu-server-setup"
execCommand "git clone -q --depth=1 https://github.com/TimeTravelersHackMe/Ubuntu-Development-Server-Setup.git ubuntu-server-setup"
execCommand "cd ubuntu-server-setup/files"
execCommand "cp -rf * /"

# Make nginx init script executable and add nginx to upstart
# See https://github.com/JasonGiedymin/nginx-init-ubuntu (file included in server configuration file boilerplate)
outputMessage 'Setting up nginx init script and adding nginx to startup'
execCommand "chmod +x /etc/init.d/nginx"
execCommand "update-rc.d -f nginx defaults > /dev/null"

# Enable default configuration file and start nginx
outputMessage 'Symlinking default nginx configuration to sites-enabled'
execCommand "cd $NGINX_CONF_FOLDER/sites-enabled"
execCommand "ln -s ../sites-available/default default"

# Install PHP-FPM
# See: http://www.maketecheasier.com/setup-lemh-stack-in-ubuntu/
outputMessage 'Installing PHP-FPM'
execCommand "apt-get install -y php5-fpm php5-mysql php5-curl > /dev/null 2>&1"

# Install HHVM
# See https://github.com/facebook/hhvm/wiki/Prebuilt-packages-on-Ubuntu-14.04
# See https://rtcamp.com/tutorials/php/hhvm-with-fpm-fallback/
outputMessage 'Installing HHVM'
execCommand "apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449 > /dev/null 2>&1"
execCommand "add-apt-repository 'deb http://dl.hhvm.com/ubuntu trusty main'"
execCommand "apt-get update > /dev/null"
execCommand "apt-get install -y hhvm > /dev/null 2>&1"
execCommand "service nginx start > /dev/null"
execCommand "service hhvm restart > /dev/null"

# Add HHVM to startup
# See: https://github.com/fideloper/Vaprobash/blob/master/scripts/php.sh
outputMessage 'Adding HHVM to startup'
execCommand "update-rc.d hhvm defaults > /dev/null"

# Install MariaDB
# See: http://www.ubuntugeek.com/install-mariadb-on-ubuntu-14-04-trusty-server.html
# See: http://stackoverflow.com/questions/7739645/install-mysql-on-ubuntu-without-password-prompt
outputMessage 'Installing MariaDB'
execCommand "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db > /dev/null 2>&1"
execCommand "add-apt-repository 'deb http://download.nus.edu.sg/mirror/mariadb/repo/10.0/ubuntu trusty main'"
execCommand "export DEBIAN_FRONTEND=noninteractive"
execCommand "debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password password '$DB_ROOT_PASSWORD"
execCommand "debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password_again password '$DB_ROOT_PASSWORD"
execCommand "apt-get update > /dev/null"
execCommand "apt-get install -y mariadb-server > /dev/null 2>&1"

# Adding root password to /root/.my.cnf
outputMessage "Adding database root password to ~/.my.cnf"
execCommand "echo [client] >> ~/.my.cnf"
execCommand "echo user=root >> ~/.my.cnf"
execCommand "echo password=${DB_ROOT_PASSWORD} >> ~/.my.cnf"

# Install PHPMyAdmin
# See: https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-phpmyadmin-with-nginx-on-an-ubuntu-14-04-server
outputMessage 'Installing PHPMyAdmin'
execCommand "debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect none'"
execCommand "debconf-set-selections <<< 'phpmyadmin phpmyadmin/dbconfig-install boolean true'"
execCommand "debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password '$DB_ROOT_PASSWORD"
execCommand "debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password '$PHPMYADMIN_PASSWORD"
execCommand "debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password '$PHPMYADMIN_PASSWORD"
execCommand "apt-get install -y phpmyadmin > /dev/null 2>&1"
execCommand "ln -s /usr/share/phpmyadmin /usr/local/nginx/html"

# Updating database port in PHPMyAdmin configuration file
outputMessage 'Updating database port in PHPMyAdmin configuration file'
execCommand "cd /etc/phpmyadmin"
outputForComplicatedCommand "sed -i \"s/\$dbport='';/\$dbport='3308';/g\" config-db.php"
sed -i "s/\$dbport='';/\$dbport='3306';/g" config-db.php

# Installing new PHPMyAdmin theme
outputMessage 'Updating PHPMyAdmin theme'
execCommand "cd /usr/share/phpmyadmin/themes"
execCommand "cp $SOURCE_FOLDER/ubuntu-server-setup/phpmyadmin/metro-2.3.zip metro-2.3.zip"
execCommand "unzip metro-2.3.zip > /dev/null"
execCommand "rm metro-2.3.zip"

# Install Postfix
# See: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-ubuntu-14-04
outputMessage 'Installing Postfix'
execCommand "debconf-set-selections <<< 'postfix postfix/mailname string '$POSTFIX_HOSTNAME"
execCommand "debconf-set-selections <<< 'postfix postfix/main_mailer_type string \"Internet Site\"'"
execCommand "apt-get install -y mailutils > /dev/null 2>&1"

# Change Postfix to send-only mode
outputMessage 'Changing Postfix to only accept emails from localhost'
execCommand 'cd /etc/postfix'
execCommand "sed -i 's/inet_interfaces = all/inet_interfaces = localhost/g' main.cf"

# Modify DNS server Postfix uses to Google DNS (some host DNS servers do not allow outgoing e-mail for whatever reason)
# See: http://ubuntuforums.org/showthread.php?t=882203
outputMessage 'Modify the DNS server that Postfix uses'
execCommand 'cd /var/spool/postfix/etc'
execCommand "sed -i 's/nameserver 10.0.2.3/nameserver 8.8.8.8/g' resolv.conf"

# Forwarding root mail messages to specified e-mail
outputMessage "Forwarding root mail to ${EMAIL_ADDRESS}"
execCommand "echo \"root: ${EMAIL_ADDRESS}\" >> /etc/aliases"

# Install WP-CLI
outputMessage "Installing WP-CLI"
execCommand "curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar > /dev/null"
execCommand "chmod +x wp-cli.phar"
execCommand "sudo mv wp-cli.phar /usr/local/bin/wp"

# Install Node.js
# See https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager#debian-and-ubuntu-based-linux-distributions
outputMessage 'Installing the latest stable release of Node.js'
execCommand "curl -sL https://deb.nodesource.com/setup | bash - > /dev/null"
execCommand "apt-get install -y nodejs > /dev/null 2>&1"

# Update NPM
# Note: Should use NVM to manage Node/NPM
outputMessage 'Updating NPM'
execCommand "npm install -g npm > /dev/null"

# Installs Browser Sync
outputMessage 'Installing Browser Sync'
execCommand "npm install -g browser-sync > /dev/null 2>&1"

# Install Gulp
# See: https://github.com/gulpjs/gulp/blob/master/docs/getting-started.md
outputMessage 'Installing Gulp'
execCommand "npm install -g gulp > /dev/null"

# Install Bower (required for Foundation)
# See: http://foundation.zurb.com/apps/getting-started.html
outputMessage 'Installing Bower'
execCommand "npm install -g bower > /dev/null"

# Install Foundation for Apps CLI
# See: http://foundation.zurb.com/apps/getting-started.html
#outputMessage 'Installing Foundation CLI'
#execCommand "npm install -g foundation-cli > /dev/null"

# Install Bundler Gem (required for Foundation)
# See: http://foundation.zurb.com/apps/getting-started.html
#outputMessage 'Installing Bundler'
#execCommand "gem install bundler"

 # Install Mono (for ASP support)
 # See: http://www.mono-project.com/
 outputMessage 'Installing Mono'
 execCommand "apt-get install -y mono-complete > /dev/null"
 execCommand "apt-get install -y mono-fastcgi-server4 > /dev/null"

# Add aliases and functions to global bashrc file
outputMessage 'Adding aliases to global bashrc file'
execCommand "cat /etc/bash.bashrc.additions >> /etc/bash.bashrc"

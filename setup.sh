#!/bin/bash

# Set password variables
DB_ROOT_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c32 | tr -d '-')
MEMCACHED_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c16 | tr -d '-')
PHPMYADMIN_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c32 | tr -d '-')
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
NVM_VERSION='0.26.1'
MONO_DB_CONNECTOR_VERSION='6.9.7'
TOMCAT_VERSION='8.0.26'
TOMCAT_VERSION_NUMBER='8'

# Set functions
function outputMessage {
	STRING=$1
	MAX_LENGTH=52
	# Test is string is odd and add a space to it if so
	STRING_CHARS=${#STRING}
	EXTRA_SPACE=""
	if [ $((STRING_CHARS%2)) -ne 0 ];
	then
		EXTRA_SPACE=" "
	fi
	((STRING_LENGTH=4+${#STRING}))
	((TOTAL_SPACES_TO_ADD=($MAX_LENGTH-$STRING_LENGTH)/2))
	# Create variable with TOTAL_SPACES amount of spaces
	SPACES=''
	for (( i=1; i <= $TOTAL_SPACES_TO_ADD; i++ ))
	do
        	SPACES=" $SPACES"
        done
        # Output message with colors to terminal
	echo "$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)+------------------------------------------------------+$(tput sgr0)"
	echo "$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)|                                                      |$(tput sgr0)"
	echo "$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)| $SPACES#/\ $(tput sgr0)$(tput setab 0)$(tput setaf 7)$(tput smul)$STRING$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)$EXTRA_SPACE$SPACES |$(tput sgr0)"
	echo "$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)|                                                      |$(tput sgr0)"
	echo "$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)+------------------------------------------------------+$(tput sgr0)"
	# Output message without colors to max.log
	echo "+------------------------------------------------------+" >> ~/max.log
	echo "|                                                      |" >> ~/max.log
	echo "| $SPACES#/\ $STRING$$EXTRA_SPACE$SPACES |" >> ~/max.log
	echo "|                                                      |" >> ~/max.log
	echo "+------------------------------------------------------+" >> ~/max.log

}

function execCommand {
	# Output message to terminal with colors
	echo "$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)+-----> $(tput sgr0)$(tput setab 0)$(tput setaf 7)$1$(tput sgr0)"
	# Output message to max.log without colors
	echo "+-----> $1" >> ~/max.log
	# Sends STDERR and STDOUT to max.log and displays STDERR to screen
	# http://unix.stackexchange.com/questions/79996/how-to-redirect-stdout-and-stderr-to-a-file-and-display-stderr-to-console
	eval $1 2>&1 >>~/max.log | tee --append ~/max.log
	# Source: http://stackoverflow.com/questions/32671814/eval-commands-with-stderr-stdout-redirection-causing-problems?noredirect=1#comment53199328_32671814
	# if command starts with "cd ", execute it once more, but in the current shell:
	#[[ "$1" == cd\ * ]] && $1
}

# Handles special commands that do not work with execCommand (e.g. the NVM and RVM installations)
function execSpecialCommand {
	# Output message to terminal with colors
	echo "$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)+-----> $(tput sgr0)$(tput setab 0)$(tput setaf 7)$1$(tput sgr0)"
	# Output message to max.log without colors
	echo "+-----> $1" >> ~/max.log
	eval $1
}
function changeDir {
	# Output message to terminal with colors
	echo "$(tput sgr0)$(tput setab 0)$(tput bold)$(tput setaf 6)+-----> $(tput sgr0)$(tput setab 0)$(tput setaf 7)$1$(tput sgr0)"
	# Output message to max.log without colors
	echo "+-----> $1" >> ~/max.log
	eval $1
	# Can not figure out how to pipe STDERR/STDOUT from the cd command so the following line adds the current directory after the cd command is evaluated
	pwd >> ~/max.log
}

# Update server
outputMessage 'Updating the server'
execCommand "apt-get update"

# Install dependencies
outputMessage 'Installing dependencies'
execCommand "apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev unzip libssl-dev curl git software-properties-common"

# Compile, and install nginx/pagespeed
# Source: https://developers.google.com/speed/pagespeed/module/build_ngx_pagespeed_from_source
# pagespeed version 1.9.32.3, psol version 1.9.32.3, nginx version 1.8.0
outputMessage 'Installing nginx with pagespeed from source'
changeDir "cd $SOURCE_FOLDER"
# Would like to use curl -# -o for the download but unzipping messes up when curl is used to download a zip so wget is used
execCommand "wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${PAGESPEED_VERSION}-beta.zip"
execCommand "unzip release-${PAGESPEED_VERSION}-beta.zip"
changeDir "cd ngx_pagespeed-release-${PAGESPEED_VERSION}-beta"
execCommand "curl -# -o ${PAGESPEED_VERSION}.tar.gz https://dl.google.com/dl/page-speed/psol/${PAGESPEED_VERSION}.tar.gz"
execCommand "tar -xzvf ${PAGESPEED_VERSION}.tar.gz"
changeDir "cd $SOURCE_FOLDER"
execCommand "curl -# -o nginx-${NGINX_VERSION}.tar.gz http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
execCommand "tar -xvzf nginx-${NGINX_VERSION}.tar.gz"
changeDir "cd nginx-${NGINX_VERSION}"
execCommand "./configure --user=www-data --group=www-data --conf-path=${NGINX_CONF_FOLDER}/nginx.conf --with-pcre-jit --with-http_ssl_module --with-http_spdy_module --with-http_realip_module --add-module=${SOURCE_FOLDER}/ngx_pagespeed-release-${PAGESPEED_VERSION}-beta"
execCommand "make"
execCommand "make install"

# Clone base files from git repo
outputMessage 'Cloning base files from GitHub'
changeDir "cd $SOURCE_FOLDER"
execCommand "rm -rf ubuntu-server-setup"
execCommand "git clone -q --depth=1 https://github.com/TimeTravelersHackMe/Ubuntu-Development-Server-Setup.git ubuntu-server-setup"
changeDir "cd ubuntu-server-setup/files"
execCommand "cp -rf * /"

# Make nginx init script executable and add nginx to start up
# Source: https://github.com/JasonGiedymin/nginx-init-ubuntu (file included in server configuration file boilerplate)
outputMessage 'Setting up nginx init script'
execCommand "chmod +x /etc/init.d/nginx"
execCommand "update-rc.d -f nginx defaults"

# Enable default configuration file and start nginx
outputMessage 'Setting up default nginx configuration'
changeDir "cd $NGINX_CONF_FOLDER/sites-enabled"
execCommand "ln -s ../sites-available/default default"

# Install PHP-FPM
# Source: http://www.maketecheasier.com/setup-lemh-stack-in-ubuntu/
outputMessage 'Installing PHP-FPM'
execCommand "apt-get install -y php5-fpm php5-mysql php5-curl"

# Install HHVM
# Source: https://github.com/facebook/hhvm/wiki/Prebuilt-packages-on-Ubuntu-14.04
# Source: https://rtcamp.com/tutorials/php/hhvm-with-fpm-fallback/
outputMessage 'Installing HHVM'
execCommand "apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449"
execCommand "add-apt-repository 'deb http://dl.hhvm.com/ubuntu trusty main'"
execCommand "apt-get update"
execCommand "apt-get install -y hhvm"
execCommand "service nginx start"
execCommand "service hhvm restart"

# Add HHVM to startup
# Source: https://github.com/fideloper/Vaprobash/blob/master/scripts/php.sh
outputMessage 'Adding HHVM to startup'
execCommand "update-rc.d hhvm defaults"

# Install MariaDB
# Source: http://www.ubuntugeek.com/install-mariadb-on-ubuntu-14-04-trusty-server.html
# Source: http://stackoverflow.com/questions/7739645/install-mysql-on-ubuntu-without-password-prompt
outputMessage 'Installing MariaDB'
execCommand "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db"
execCommand "add-apt-repository 'deb http://download.nus.edu.sg/mirror/mariadb/repo/10.0/ubuntu trusty main'"
execCommand "export DEBIAN_FRONTEND=noninteractive"
execCommand "debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password password '$DB_ROOT_PASSWORD"
execCommand "debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password_again password '$DB_ROOT_PASSWORD"
execCommand "apt-get update"
execCommand "apt-get install -y mariadb-server"

# Adding root password to /root/.my.cnf
outputMessage "Adding database root password to ~/.my.cnf"
execCommand "echo [client] >> ~/.my.cnf"
execCommand "echo user=root >> ~/.my.cnf"
execCommand "echo password=${DB_ROOT_PASSWORD} >> ~/.my.cnf"

# Install Adminer
# See: https://extremeshok.com/5385/ubuntu-debian-redhat-centos-nginx-adminer-lite-phpmyadmin-alternative/
outputMessage 'Installing Adminer'
execCommand "mkdir $NGINX_WEB_ROOT/adminer"
changeDir "cd $NGINX_WEB_ROOT/adminer"
execCommand "curl -# -o index.php http://www.adminer.org/latest.php"
execCommand "curl -# -o adminer.css https://raw.githubusercontent.com/pappu687/adminer-theme/master/adminer.css"
execCommand "chown -R www-data:www-data $NGINX_WEB_ROOT/adminer"

# Install Postfix
# Source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-ubuntu-14-04
outputMessage 'Installing Postfix'
execCommand "debconf-set-selections <<< 'postfix postfix/mailname string '$POSTFIX_HOSTNAME"
execCommand "debconf-set-selections <<< 'postfix postfix/main_mailer_type string \"Internet Site\"'"
execCommand "apt-get install -y mailutils"

# Change Postfix to send-only mode
outputMessage 'Changing Postfix to only accept emails from localhost'
changeDir "cd /etc/postfix"
execCommand "sed -i 's/inet_interfaces = all/inet_interfaces = localhost/g' main.cf"

# Modify DNS server Postfix uses to Google DNS (some host DNS servers do not allow outgoing e-mail for whatever reason)
# Source: http://ubuntuforums.org/showthread.php?t=882203
outputMessage 'Modify the DNS server that Postfix uses'
changeDir "cd /var/spool/postfix/etc"
execCommand "sed -i 's/nameserver 10.0.2.3/nameserver 8.8.8.8/g' resolv.conf"

# Forwarding root mail messages to specified e-mail
outputMessage "Forwarding root mail to ${EMAIL_ADDRESS}"
execCommand "echo \"root: ${EMAIL_ADDRESS}\" >> /etc/aliases"

# Install WP-CLI
outputMessage "Installing WP-CLI"
execCommand "curl -# -o wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
execCommand "chmod +x wp-cli.phar"
execCommand "sudo mv wp-cli.phar /usr/local/bin/wp"

# Install NVM
# Source: https://github.com/creationix/nvm
# Source: https://www.digitalocean.com/community/tutorials/how-to-install-node-js-with-nvm-node-version-manager-on-a-vps
outputMessage "Installing NVM"
execCommand "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.26.1/install.sh | bash"
execSpecialCommand "source $HOME/.nvm/nvm.sh"
execSpecialCommand "nvm install stable"
execCommand "n=$(which node)"
execCommand "n=${n%/bin/node}"
execCommand "chmod -R 755 $n/bin/*"
execCommand "sudo cp -r $n/{bin,lib,share} /usr/local"

# Install MongoDB
# Source: https://www.digitalocean.com/community/tutorials/how-to-install-mongodb-on-ubuntu-14-04
outputMessage 'Installing MongoDB'
execCommand "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10"
execCommand 'echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list'
execCommand "apt-get update"
execCommand "apt-get install -y mongodb-org"

# Installs Browser Sync
#outputMessage 'Installing Browser Sync'
#execCommand "npm install -g browser-sync"

# Install Gulp
# Source: https://github.com/gulpjs/gulp/blob/master/docs/getting-started.md
outputMessage 'Installing Gulp'
execCommand "npm install -g gulp"

# Install Grunt CLI
#outputMessage 'Installing Grunt CLI'
#execCommand "npm install -g grunt-cli"

# Install Bower (required for Foundation)
# Source: http://foundation.zurb.com/apps/getting-started.html
#outputMessage 'Installing Bower'
#execCommand "npm install -g bower"

# Install Foundation for Apps CLI
# Source: http://foundation.zurb.com/apps/getting-started.html
#outputMessage 'Installing Foundation CLI'
#execCommand "npm install -g foundation-cli"

# Install Mono (for ASP support)
# Source: http://www.mono-project.com/
outputMessage 'Installing Mono'
execCommand "apt-get install -y mono-complete"
execCommand "apt-get install -y mono-fastcgi-server4"

# Add MySQL database connector for Mono
outputMessage 'Add Mono MySQL database connector'
changeDir "cd /usr/local/src"
# Would like to use curl -# -o to download the .zip file but for whatever reason unzip does not work when zips are downloaded with curl -# -o so wget is used in this case
execCommand "wget http://dev.mysql.com/get/Downloads/Connector-Net/mysql-connector-net-${MONO_DB_CONNECTOR_VERSION}-noinstall.zip"
execCommand "unzip mysql-connector-net-${MONO_DB_CONNECTOR_VERSION}-noinstall.zip -f mysql-connector-net"
changeDir "cd mysql-connector-net"
execCommand "gacutil /i MySql.Data.dll"

# Add Mono startup script
outputMessage 'Add Mono startup script'
changeDir "cd /etc/init.d"
execCommand "chmod +x /etc/init.d/monoserve"

# Install Oracle's JDK 8
# Source: https://vpsineu.com/blog/how-to-set-up-tomcat-8-with-nginx-reverse-proxy-on-an-ubuntu-14-04-vps/
outputMessage "Installing Oracle's JDK"
execCommand "add-apt-repository ppa:webupd8team/java -y"
execCommand "apt-get update"
# Source: http://www.webupd8.org/2014/03/how-to-install-oracle-java-8-in-debian.html
execCommand "echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections"
execCommand "apt-get install -y oracle-java8-installer"
execCommand "apt-get install -y oracle-java8-set-default"

# Install Apache Tomcat 8
outputMessage "Installing Apache Tomcat 8"
changeDir "cd $SOURCE_FOLDER"
execCommand "curl -# -o apache-tomcat-${TOMCAT_VERSION}.tar.gz http://ftp.wayne.edu/apache/tomcat/tomcat-${TOMCAT_VERSION_NUMBER}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
execCommand "tar zxf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt"
execCommand "ln -s /opt/apache-tomcat-${TOMCAT_VERSION} /opt/tomcat8-latest"
execCommand "adduser --system --ingroup www-data --home /opt/tomcat8-latest tomcat8"
execCommand "chown -hR tomcat8:www-data /opt/tomcat8-latest /opt/apache-tomcat-${TOMCAT_VERSION}"
execCommand "service tomcat8 start"

# Install PostgreSQL
outputMessage 'Installing PostgreSQL'
execCommand "apt-get install -y postgresql postgresql-contrib"

# Install RVM (Ruby Version Manager)
# Source: https://rvm.io/rvm/install
outputMessage 'Installing RVM (Ruby Version Manager)'
execCommand "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3"
execCommand "curl -sSL https://get.rvm.io | bash"
execCommand "echo progress-bar >> ~/.curlrc"
execSpecialCommand "source /usr/local/rvm/scripts/rvm"

# Install Ruby
# For whatever reason RVM needs to be compiled from source to install compass
outputMessage 'Using RVM to install Ruby from source'
execSpecialCommand "rvm install 2.2 --disable-binary"

# Install Compass
#outputMessage 'Installing Compass'
#execCommand "gem install compass"

# Install Bundler Gem (required for Foundation)
# Source: http://foundation.zurb.com/apps/getting-started.html
#outputMessage 'Installing Bundler'
#execCommand "gem install bundler"

# Add aliases and functions to global bashrc file
outputMessage 'Adding aliases to global bashrc file'
execCommand "cat /etc/bash.bashrc.additions >> /etc/bash.bashrc"

#!/bin/bash

# Set password variables
DB_ROOT_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c32 | tr -d '-')
NEW_ROOT_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c32 | tr -d '-')

# Environment settings
POSTFIX_HOSTNAME='nullclient.com'
EMAIL_ADDRESS='chase@nullclient.com'
SWAP_SIZE_IN_GIGABYTES='4'

# Set folder structure/version variables
SOURCE_FOLDER='/usr/local/src'
NGINX_CONF_FOLDER='/etc/nginx'
NGINX_WEB_ROOT='/usr/local/nginx/html'
PAGESPEED_VERSION='1.9.32.3'
NGINX_VERSION='1.8.0'
NVM_VERSION='0.26.1'
MONO_DB_CONNECTOR_VERSION='6.9.7'
TOMCAT_VERSION='8.0.28'
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

# Set to noninteractive mode
# Source: http://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory
# outputMessage 'Changing to noninteractive mode'
# execCommand "export DEBIAN_FRONTEND=noninteractive"

# Update server
function update_server {
	outputMessage 'Updating the server'
	execCommand "apt-get update && apt-get upgrade"
}

# Add swap file
# Source: https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04
function add_swap {
	outputMessage 'Adding swap memory'
	execCommand "fallocate -l ${SWAP_SIZE_IN_GIGABYTES}G /swapfile"
	execCommand "chmod 600 /swapfile"
	execCommand "mkswap /swapfile"
	execCommand "swapon /swapfile"
	execCommand "echo '/swapfile   none    swap    sw    0   0' >> /etc/fstab"
}

# Install dependencies
function install_dependencies {
	outputMessage 'Installing dependencies'
	execCommand "sudo apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev unzip libssl-dev curl git software-properties-common"
}

# Compile, and install nginx/pagespeed
# Source: https://developers.google.com/speed/pagespeed/module/build_ngx_pagespeed_from_source
function install_nginx {
	outputMessage 'Installing nginx with pagespeed from source'
	changeDir "cd $SOURCE_FOLDER"
	execCommand "wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${PAGESPEED_VERSION}-beta.zip"
	execCommand "unzip release-${PAGESPEED_VERSION}-beta.zip"
	changeDir "cd ngx_pagespeed-release-${PAGESPEED_VERSION}-beta"
	execCommand "curl -# -o ${PAGESPEED_VERSION}.tar.gz https://dl.google.com/dl/page-speed/psol/${PAGESPEED_VERSION}.tar.gz"
	execCommand "tar -xvzf ${PAGESPEED_VERSION}.tar.gz"
	changeDir "cd $SOURCE_FOLDER"
	execCommand "curl -# -o nginx-${NGINX_VERSION}.tar.gz http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
	execCommand "tar -xvzf nginx-${NGINX_VERSION}.tar.gz"
	changeDir "cd nginx-${NGINX_VERSION}"
	execCommand "./configure --user=www-data --group=www-data --conf-path=${NGINX_CONF_FOLDER}/nginx.conf --with-pcre-jit --with-http_ssl_module --with-http_spdy_module --with-http_realip_module --add-module=${SOURCE_FOLDER}/ngx_pagespeed-release-${PAGESPEED_VERSION}-beta"
	execCommand "make"
	execCommand "make install"
}

# Clone base files from git repo
function install_setup_files {
	outputMessage 'Cloning base files from GitHub'
	changeDir "cd $SOURCE_FOLDER"
	execCommand "rm -rf ubuntu-server-setup"
	execCommand "git clone -q --depth=1 https://github.com/TimeTravelersHackMe/MaX-Development-Server.git ubuntu-server-setup"
	changeDir "cd ubuntu-server-setup/files"
	execCommand "cp -rf * /"
}

# Make nginx init script executable and add nginx to start up
# Source: https://github.com/JasonGiedymin/nginx-init-ubuntu (file included in server configuration file boilerplate)
function nginx_init_script {
	outputMessage 'Setting up nginx init script'
	execCommand "chmod +x /etc/init.d/nginx"
	execCommand "update-rc.d -f nginx defaults"
}

# Install ImageMagick
function install_image_magick {
	outputMessage 'Installing ImageMagick'
	execCommand "apt-get install imagemagick"
}

# Install PHP-FPM
# Source: http://www.maketecheasier.com/setup-lemh-stack-in-ubuntu/
function install_php_fpm {
	outputMessage 'Installing PHP-FPM'
	execCommand "apt-get install -y php5-fpm php5-mysql php5-curl php5-pgsql php5-cli php5-imagick"
	# Fixes security issue with PHP via FastCGI
	# See: http://cnedelcu.blogspot.com/2010/05/nginx-php-via-fastcgi-important.html
	execCommand 'sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini'
}

# Install HHVM
# Source: https://github.com/facebook/hhvm/wiki/Prebuilt-packages-on-Ubuntu-14.04
# Source: https://rtcamp.com/tutorials/php/hhvm-with-fpm-fallback/
function install_hhvm {
	outputMessage 'Installing HHVM'
	execCommand "apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449"
	execCommand "add-apt-repository 'deb http://dl.hhvm.com/ubuntu trusty main'"
	execCommand "apt-get update"
	execCommand "apt-get install -y hhvm"
	execCommand "service nginx start"
	execCommand "service hhvm restart"
	# Source: https://github.com/fideloper/Vaprobash/blob/master/scripts/php.sh
	execCommand "update-rc.d hhvm defaults"
}

# Install MariaDB
# Source: http://www.ubuntugeek.com/install-mariadb-on-ubuntu-14-04-trusty-server.html
# Source: http://stackoverflow.com/questions/7739645/install-mysql-on-ubuntu-without-password-prompt
function install_mariadb {
	outputMessage 'Installing MariaDB'
	execCommand "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db"
	execCommand "add-apt-repository 'deb http://download.nus.edu.sg/mirror/mariadb/repo/10.0/ubuntu trusty main'"
	execCommand "debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password password '$DB_ROOT_PASSWORD"
	execCommand "debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password_again password '$DB_ROOT_PASSWORD"
	execCommand "apt-get update"
	execCommand "apt-get install -y mariadb-server"
}

# Adding root password to /root/.my.cnf
function configure_my_cnf {
	outputMessage "Adding database root password to ~/.my.cnf"
	execCommand "echo [client] >> ~/.my.cnf"
	execCommand "echo user=root >> ~/.my.cnf"
	execCommand "echo password=${DB_ROOT_PASSWORD} >> ~/.my.cnf"
}

# Install Adminer
# See: https://extremeshok.com/5385/ubuntu-debian-redhat-centos-nginx-adminer-lite-phpmyadmin-alternative/
function install_adminer {
	outputMessage 'Installing Adminer'
	execCommand "mkdir $NGINX_WEB_ROOT/adminer"
	changeDir "cd $NGINX_WEB_ROOT/adminer"
	execCommand "wget http://www.adminer.org/latest.php"
	execCommand "curl -# -o adminer.css https://raw.githubusercontent.com/pappu687/adminer-theme/master/adminer.css"
	execCommand "chown -R www-data:www-data $NGINX_WEB_ROOT/adminer"
}

# Install Postfix
# Source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-ubuntu-14-04
function install_postfix {
	outputMessage 'Installing Postfix'
	execCommand "debconf-set-selections <<< 'postfix postfix/mailname string '$POSTFIX_HOSTNAME"
	execCommand "debconf-set-selections <<< 'postfix postfix/main_mailer_type string \"Internet Site\"'"
	execCommand "apt-get install -y mailutils"
}

# Change Postfix to send-only mode
function configure_postfix_nullclient {
	outputMessage 'Accept emails from localhost only'
	changeDir "cd /etc/postfix"
	execCommand "sed -i 's/inet_interfaces = all/inet_interfaces = localhost/g' main.cf"
}

# Modify DNS server Postfix uses to Google DNS (some host DNS servers do not allow outgoing e-mail for whatever reason)
# Source: http://ubuntuforums.org/showthread.php?t=882203
function configure_postfix_dns {
	outputMessage 'Modify the DNS server that Postfix uses'
	changeDir "cd /var/spool/postfix/etc"
	execCommand "sed -i 's/nameserver 10.0.2.3/nameserver 8.8.8.8/g' resolv.conf"
}

# Forwarding root mail messages to specified e-mail
function forward_root_mail_to_admin_email {
	outputMessage "Forwarding root mail to ${EMAIL_ADDRESS}"
	execCommand "echo \"root: ${EMAIL_ADDRESS}\" >> /etc/aliases"
}

# Install WP-CLI
function install_wp_cli {
	outputMessage "Installing WP-CLI"
	# Source: http://wp-cli.org/
	execCommand "curl -# -o wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
	execCommand "chmod +x wp-cli.phar"
	execCommand "mv wp-cli.phar /usr/local/bin/wp"
	# Source: http://wp-cli.org/#complete
	changeDir "cd /usr/local/share"
	execCommand "curl -# -o wp-completion.bash https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash"
}

# Install NodeJS and NPM
function install_node {
	outputMessage "Installing NodeJS and NPM"
	execCommand "apt-get install nodejs"
	execCommand "apt-get install npm"
}

# Install N (node version manager)
# Source: https://www.npmjs.com/package/n
function install_n {
	outputMessage "Installing n"
	execCommand "npm install -g n"
}

# Install MongoDB
# Source: https://www.digitalocean.com/community/tutorials/how-to-install-mongodb-on-ubuntu-14-04
function install_mongodb {
	outputMessage 'Installing MongoDB'
	execCommand "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10"
	execCommand 'echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list'
	execCommand "apt-get update"
	execCommand "apt-get install -y mongodb-org"
}

# Install Mono (for ASP support)
# Source: http://www.mono-project.com/
function install_mono {
	outputMessage 'Installing Mono'
	execCommand "apt-get install -y mono-complete"
	execCommand "apt-get install -y mono-fastcgi-server4"
}

# Add MySQL database connector for Mono
function install_mono_mysql_database_connector {
	outputMessage 'Add Mono MySQL database connector'
	changeDir "cd /usr/local/src"
	# Would like to use curl -# -o to download the .zip file but for whatever reason unzip does not work when zips are downloaded with curl -# -o so wget is used in this case
	execCommand "wget http://dev.mysql.com/get/Downloads/Connector-Net/mysql-connector-net-${MONO_DB_CONNECTOR_VERSION}-noinstall.zip"
	execCommand "unzip mysql-connector-net-${MONO_DB_CONNECTOR_VERSION}-noinstall.zip -d mysql-connector-net"
	changeDir "cd mysql-connector-net"
	execCommand "gacutil /i MySql.Data.dll"
}

# Add Mono startup script
function mono_init_script {
	outputMessage 'Add Mono startup script'
	changeDir "cd /etc/init.d"
	execCommand "chmod +x /etc/init.d/monoserve"
}

# Install Oracle's JDK 8
# Source: https://vpsineu.com/blog/how-to-set-up-tomcat-8-with-nginx-reverse-proxy-on-an-ubuntu-14-04-vps/
function install_oracle_jdk {
	outputMessage "Installing Oracle's JDK"
	execCommand "add-apt-repository ppa:webupd8team/java -y"
	execCommand "apt-get update"
	# Source: http://www.webupd8.org/2014/03/how-to-install-oracle-java-8-in-debian.html
	execCommand "echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections"
	execCommand "apt-get install -y oracle-java8-installer"
	execCommand "apt-get install -y oracle-java8-set-default"
}

# Install Apache Tomcat 8
# Source: http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.28/bin/apache-tomcat-8.0.28.tar.gz
function install_apache_tomcat {
	outputMessage "Installing Apache Tomcat 8"
	changeDir "cd $SOURCE_FOLDER"
	execCommand "curl -# -o apache-tomcat-${TOMCAT_VERSION}.tar.gz http://archive.apache.org/dist/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
	execCommand "tar -xvzf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt"
	execCommand "ln -s /opt/apache-tomcat-${TOMCAT_VERSION} /opt/tomcat8-latest"
	execCommand "adduser --system --ingroup www-data --home /opt/tomcat8-latest tomcat8"
	execCommand "chown -hR tomcat8:www-data /opt/tomcat8-latest /opt/apache-tomcat-${TOMCAT_VERSION}"
	execCommand "service tomcat8 start"
}

# Install PostgreSQL
function install_postgresql {
	outputMessage 'Installing PostgreSQL'
	execCommand "apt-get install -y postgresql postgresql-contrib"
}

# Install RVM (Ruby Version Manager)
# Source: https://rvm.io/rvm/install
function install_rvm {
	outputMessage 'Installing RVM (Ruby Version Manager)'
	execCommand "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3"
	execCommand "curl -sSL https://get.rvm.io | bash"
	execCommand "echo progress-bar >> ~/.curlrc"
	execSpecialCommand "source /usr/local/rvm/scripts/rvm"
}

# Install Ruby
# For whatever reason RVM needs to be compiled from source to install compass
function install_ruby {
	outputMessage 'Using RVM to install Ruby from source'
	execSpecialCommand "rvm install 2.2 --disable-binary"
	execSpecialCommand "rvm use 2.2"
}

# Add aliases and functions to global bashrc file
function add_global_bashrc_aliases {
	outputMessage 'Adding aliases to global bashrc file'
	execCommand "cat /etc/bash.bashrc.additions >> /etc/bash.bashrc"
}

# Give vagrant user root priviledges
function grant_vagrant_sudo {
	outputMessage 'Granting vagrant user sudo priviledges'
	execCommand "adduser vagrant sudo"
}

# Switch user to vagrant
function switch_to_vagrant_user {
	outputMessage 'Switching user to vagrant'
	execCommand "su vagrant"
}

# Install gulp
function install_gulp {
	outputMessage "Installing gulp"
	execCommand "npm install -g gulp"
}

# Install Cordova
function install_cordova {
	outputMessage "Installing Cordova"
	execCommand "npm install -g cordova"
}

# Install Iconic
# Source: http://ionicframework.com/getting-started/
function install_ionic {
	outputMessage "Installing Ionic"
	execCommand "npm install -g ionic"
}

grant_vagrant_sudo
switch_to_vagrant_user
update_server
add_swap
install_dependencies
install_nginx
install_setup_files
nginx_init_script
install_image_magick
install_php_fpm
install_hhvm
install_mariadb
configure_my_cnf
install_adminer
install_postfix
configure_postfix_nullclient
configure_postfix_dns
forward_root_mail_to_admin_email
install_wp_cli
install_node
install_n
install_mongodb
install_mono
install_mono_mysql_database_connector
mono_init_script
install_oracle_jdk
install_apache_tomcat
install_postgresql
install_rvm
install_ruby
install_gulp
install_cordova
install_ionic
add_global_bashrc_aliases

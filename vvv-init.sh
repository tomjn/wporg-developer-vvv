#!/bin/bash
#
# This script is run by the VVV provisioning process, and loads
# all the various files into place to run a Glow Blogs 
# development environment.
#
# This script is free software, and is released under the 
# terms of the GPL version 2 or (at your option) any 
# later version.

# Just a human readable description of this site
SITE_NAME="WordPress Devhub Blogs"
# The name (to be) used by MySQL for the DB
DB_NAME="wpdevhub"

# ----------------------------------------------------------------
# You should not need to edit below this point. Famous last words.

echo "Commencing $SITE_NAME setup"

# Add GitHub and GitLab to known_hosts, so we don't get prompted
# to verify the server fingerprint.
# The fingerprints in [this repo]/ssh/known_hosts are generated as follows:
#
# As the starting point for the ssh-keyscan tool, create an ASCII file 
# containing all the hosts from which you will create the known hosts 
# file, e.g. sshhosts.
# Each line of this file states the name of a host (alias name or TCP/IP 
# address) and must be terminated with a carriage return line feed 
# (Shift + Enter), e.g.
# 
# bitbucket.org
# github.com
# gitlab.com
# 
# Execute ssh-keyscan with the following parameters to generate the file:
# 
# ssh-keyscan -t rsa,dsa -f ssh_hosts >ssh/known_hosts
# The parameter -t rsa,dsa defines the host’s key type as either rsa 
# or dsa.
# The parameter -f /home/user/ssh_hosts states the path of the source 
# file ssh_hosts, from which the host names are read.
# The parameter >ssh/known_hosts states the output path of the 
# known_host file to be created.
# 
# From "Create Known Hosts Files" at: 
# http://tmx0009603586.com/help/en/entpradmin/Howto_KHCreate.html
mkdir -p ~/.ssh
touch ~/.ssh/known_hosts
IFS=$'\n'
for KNOWN_HOST in $(cat "ssh/known_hosts"); do
	if ! grep -Fxq "$KNOWN_HOST" ~/.ssh/known_hosts; then
	    echo "Adding host to SSH known_hosts for user: $KNOWN_HOST"
	    echo $KNOWN_HOST >> ~/.ssh/known_hosts
	fi
done

# Make a database, if we don't already have one
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS $DB_NAME; GRANT ALL PRIVILEGES ON $DB_NAME.* TO wp@localhost IDENTIFIED BY 'wp';"

# If there's no WordPress, then assume we're starting from scratch
if [[ ! -f htdocs/wp-load.php ]]; then
	cd htdocs
	wp core download
	extra_php="
	#define( 'WPORGPATH', __DIR__ . '/wp-content/themes/' );
	"
	wp core config --dbname=wpdevhub --dbuser=wp --dbpass=wp --extra-php "$extra-php"
	wp core install --url="http://developer.wordpress.dev" --title="WordPress Local Developer Hub" --admin_user="admin" --admin_password="password" --admin_email="example@example.com"
	cd ..
	git clone git@github.com:rmccue/WP-Parser.git htdocs/wp-content/plugins/wp-parser
	git clone git@github.com:Rarst/wporg-developer.git htdocs/wp-content/themes/wporg-developer
	svn co https://meta.svn.wordpress.org/sites/trunk/wordpress.org/public_html/wp-content/plugins/handbook/ htdocs/wp-content/plugins/handbook
	cd htdocs/wp-content/plugins/wp-parser
	composer install
	cd -
	cd htdocs
	wp plugin activate wp-parser
	wp plugin activate handbook
	wp theme activate wporg-developer
	cd ..
fi


# The Vagrant site setup script will restart Nginx for us

echo "$SITE_NAME site is now installed, don\'t forget to visit the devhub instructions page to add the WPORGPATH variable and the latest .org header.php and footer.php";

#!/bin/bash

#
# Variables
#
PUB_KEY_STRING="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA7dPnn+j7/70ri+RwEo3jMZKm1mdjLDXO42ODRxW0LJMmbyZ6Uma/9+eopHnIJPgiDXhjcWSHcrm8Xz0V0ZBP4HnTznKLCMPJN3F9oMrHGi1eg00TfkJ2B6AEdbaZPSJ79MbJyGdNnJulInGWRMVk0ssOBWNhu0NJqfIEWX2NpqDUyCWo6Nut9I6UXFauoNmDY6LFxrTOyhRzSjlsnfT4S10opBa7bRnvukwK0H/2dHVYOQqQGxUUrcu5QFNurdLv+7vn8IbwFn3edTT60LPmHJSK9FlVO9FfiHAN1LyDDrBxKqbYcLqDkENpyTkk/Q/hdqiYH152OqoS5kr/yoNRSQ== root@hdpclustermstr0"
SSH_DIR=/root/.ssh
AUTH_KEYS=$SSH_DIR/authorized_keys

#
# Create the .ssh directory
#
echo -e "\n####  Creating $SSH_DIR and setting perms"
mkdir -p $SSH_DIR
chmod 700 $SSH_DIR
echo "SUCCESS"

#
# Add the key
#
echo -e "\n####  Adding the public key to $AUTH_KEYS"
echo "$PUB_KEY_STRING" >>$AUTH_KEYS
echo "SUCCESS"

#
# Fix ownership of the .ssh directory
#
echo -e "\n####  Fixing ownership of the .ssh directory"
chown -R root:root $SSH_DIR
echo "SUCCESS"

#
# Disable SELinux temporarily to allow for SSH
# 
echo -e "\n####  Disabling SELinux to allow SSH key auth to work"
setenforce 0
echo "SUCCESS"

#
# Display contents of authorized_keys
#
echo -e "\n####  Displaying the contents of $AUTH_KEYS"
cat $AUTH_KEYS


exit 0

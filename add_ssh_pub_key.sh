#!/bin/bash

#
# Variables
#
PUB_KEY_STRING="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAohhodeDv6Az0SP+17TKEso+rUXSqf96jS0cPLJ0INX1HYORXDVFFstVS0lwjTXkd2pU2mrkjoGJyXg4cLM2KHb0SPWt9bxrz64xlJM5zEAWX6V42Jx4ezyjt9Y/0WMaTYDulsC+6vFIIbD1sEothBV5G7y7jO/PkncVjuxdU4nuDQ7PyCDYfZP++BZd8knCpieAs+rqV8Ur3vfKTZPpUbYc1oUFXBclndxk/UaCT/k5JdOH7LdQX4H2enfe6wmP+jlNtvMrfjPZlefRh5XFYjnaPa+G3UQmuYghSGJwElVeixG7HTAvKqvLnqTkzMJ2t9gY83HBEdr+srakPO2MhKQ== root@ahdpclustermstr1"
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
# Display contents of authorized_keys
#
echo -e "\n####  Displaying the contents of $AUTH_KEYS"
cat $AUTH_KEYS

exit 0

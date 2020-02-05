#!/bin/sh

# Generating default ssh key
ssh-keygen -t rsa -N "" -f /home/jonas/.ssh/id.rsa

echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo -e 'Jonas1\!\nJonas1\!' | (passwd root)
reboot
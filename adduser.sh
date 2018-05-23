#!/usr/bin/env bash

USERNAME_1='paras'
KEY_1="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAdPncTfVBeqtsTkg4bFZKD8hNs/TwGBlPwiUYVn4T2HcTvYJh+Kl+tv+mkBqSucv44cVMITcYTF3LAlsJRaP00Q7HG+kbUt+c0lP6H/L37Hf85r77Uqxux8S9aVUfNEraosTz8190cIBnu1VMTINUNF63Dz3C2VFDkQCyssTnvSh0yVLIgXEXu619p2bA0r+CvCud4cnuv5+sn0g0ahuzJ6Wu/M2FhRcoeYJH9K9DmEC2rn0JimjK8aMa59XFkZgsjWp6nmoVs5XmgKF7h8HaKPVqwcYSMtAlPnqjjSyNM4t6SFlknH5jwIgYdv44vAO6WCy3/DTW2N5KjOe7uAi5"

USERNAME_2='lkogler'
KEY_2="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCaSVSLKZ4dnw2KrwGExsTf1ZHd5d3VhhxFAWZi9kK/gi02U2bebsxHlBUcIYhU/q49A6zod/3hve8kUH5GGfbvLn/Gnjp4ivDG6vQPQdbTHYFYjNb3sIs+1wKdCDyXKhTdhkEjGyAa20sxbKezjRlzNo+RT7NbBk3l4ASX6uU3IDdmwXP3pRVsi14ao3KsXo1zaeC8LtWxNAoCMH0uWNhVdCtXssyEmMHE0s4yJFLGhKVyxaAsZkw6ADM7zRcRY5CXIeXVvXwD2HQ3m4FBiqQuioeYp0JO8CwldPoONuahMehTv7dMaP5xybXVY2kyAp/UU7sZRWANwGmpB6t7yrlL"

function set_up_user() {
  USERNAME=$1
  KEY=$2

  if ! id -u ${USERNAME}
  then
    echo "setting up $USERNAME"
    sudo adduser ${USERNAME}
    sudo su - ${USERNAME} <<COMMAND
      mkdir .ssh
      chmod 700 .ssh
      touch .ssh/authorized_keys
      chmod 600 .ssh/authorized_keys
      echo ${KEY} >> .ssh/authorized_keys
COMMAND
  fi
}

set_up_user ${USERNAME_1} "${KEY_1}"
set_up_user ${USERNAME_2} "${KEY_2}"

#!/usr/bin/env bash

USERNAME_1='lkogler'
KEY_1="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCaSVSLKZ4dnw2KrwGExsTf1ZHd5d3VhhxFAWZi9kK/gi02U2bebsxHlBUcIYhU/q49A6zod/3hve8kUH5GGfbvLn/Gnjp4ivDG6vQPQdbTHYFYjNb3sIs+1wKdCDyXKhTdhkEjGyAa20sxbKezjRlzNo+RT7NbBk3l4ASX6uU3IDdmwXP3pRVsi14ao3KsXo1zaeC8LtWxNAoCMH0uWNhVdCtXssyEmMHE0s4yJFLGhKVyxaAsZkw6ADM7zRcRY5CXIeXVvXwD2HQ3m4FBiqQuioeYp0JO8CwldPoONuahMehTv7dMaP5xybXVY2kyAp/UU7sZRWANwGmpB6t7yrlL"

USERNAME_2='zak'
KEY_2="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDlgG+Yepuof2fQwAQHK8Nc/fIddk3oTJTONXvGx0O0f3hKid31rsAPqM7+nIKYXL4fb9QVdWOyi0a/AquOms4yPFbDFFTKH/uCPaEAxu338lGtbuCEvvUMF48p5cZvXc0ELVOtag7VJ+RCTcyv2WOW8c7tZuyUM/IZjnq4KWVv25TtBOwmOxk0xiQop9Y1lMyS+VQSmSTUCoIc/lF6YRQ3t9yb5pMgQ5UKyPJupWxu1PTkOiO08+7DgOlRNpvv/LdyGnP6q5m5XQPXHKmpSQUKZ7hHmDYzUXrkhYBIm2sUiFITBaILUvJCCeNbAHJKU9X5mqw/BMchfVi7E0EHNNAD zak@zaksoup.com"

USERNAME_3='symonnesingleton'
KEY_3="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDgK94ygoI90a9poDk7kVO7w2nvulPNGMbJGcK68vx6BJC6ekjHchYiITI7PdjqAz4rZ/sEHzE75DlHeetMOis9hZewjgdNegdA0v0ms7cuDScKICPOzct4ylskotMyfEcLCmqGZwKzKCG7YDr5LpQ6SUVK6o+4zNY4G/nUzW+Lhk+Uu6xg16IH21Nzzk7bhhqG3hqrQa9wgMji0pQdsTyuJb0RYJnhh/2vM8VV4xwI9YtTesunLMaKrJuGnL3CyXWx8AZ0vV2QRkKp/TzW52P16r0MmGQ2TSoNtw4iMMC3fmRg73VzT8zWI8NSP2qen+TKx63xWDAsiNX6BTD8nlWl0+fnFOsormILwzuW+yaOPpV7M8SL1L25Zrmb1TbEPfGHNNUdWmq1Yzvtq5d4awNPFmGMGQtayX3iZDSqluaG1F5cRBq3Pox21FFHYkPG3V7spSZe9h5I0qfEKr8dV3OFzakpONQGdAW74Egab9xiFPSr4IUQb3EiwAjNFhC0c4V1V25XCtmcUKeTgvBK2j/Jn60hj6jJVdWypjMYaJMN2o1lK/whIoCqN1KSaJo+GjMFO0oDrG3wn2cnt8r+4+21+UrIoWfvRZwg6MKtxqEvrP13L3wk5GYvKg7s1DxXQwdZmUv+1IHtHUFO447NAXuytn00s1sgPcgBOGE1ldilw== symonne@codeforamerica.org"

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
set_up_user ${USERNAME_3} "${KEY_3}"

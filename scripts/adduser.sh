#!/usr/bin/env bash

declare -A users=(
  ["lkogler"]="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCaSVSLKZ4dnw2KrwGExsTf1ZHd5d3VhhxFAWZi9kK/gi02U2bebsxHlBUcIYhU/q49A6zod/3hve8kUH5GGfbvLn/Gnjp4ivDG6vQPQdbTHYFYjNb3sIs+1wKdCDyXKhTdhkEjGyAa20sxbKezjRlzNo+RT7NbBk3l4ASX6uU3IDdmwXP3pRVsi14ao3KsXo1zaeC8LtWxNAoCMH0uWNhVdCtXssyEmMHE0s4yJFLGhKVyxaAsZkw6ADM7zRcRY5CXIeXVvXwD2HQ3m4FBiqQuioeYp0JO8CwldPoONuahMehTv7dMaP5xybXVY2kyAp/UU7sZRWANwGmpB6t7yrlL"
  ["symonnesingleton"]="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDgK94ygoI90a9poDk7kVO7w2nvulPNGMbJGcK68vx6BJC6ekjHchYiITI7PdjqAz4rZ/sEHzE75DlHeetMOis9hZewjgdNegdA0v0ms7cuDScKICPOzct4ylskotMyfEcLCmqGZwKzKCG7YDr5LpQ6SUVK6o+4zNY4G/nUzW+Lhk+Uu6xg16IH21Nzzk7bhhqG3hqrQa9wgMji0pQdsTyuJb0RYJnhh/2vM8VV4xwI9YtTesunLMaKrJuGnL3CyXWx8AZ0vV2QRkKp/TzW52P16r0MmGQ2TSoNtw4iMMC3fmRg73VzT8zWI8NSP2qen+TKx63xWDAsiNX6BTD8nlWl0+fnFOsormILwzuW+yaOPpV7M8SL1L25Zrmb1TbEPfGHNNUdWmq1Yzvtq5d4awNPFmGMGQtayX3iZDSqluaG1F5cRBq3Pox21FFHYkPG3V7spSZe9h5I0qfEKr8dV3OFzakpONQGdAW74Egab9xiFPSr4IUQb3EiwAjNFhC0c4V1V25XCtmcUKeTgvBK2j/Jn60hj6jJVdWypjMYaJMN2o1lK/whIoCqN1KSaJo+GjMFO0oDrG3wn2cnt8r+4+21+UrIoWfvRZwg6MKtxqEvrP13L3wk5GYvKg7s1DxXQwdZmUv+1IHtHUFO447NAXuytn00s1sgPcgBOGE1ldilw== symonne@codeforamerica.org"
  ["christa"]="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCltgOMIM/3Pi3xZaGF2GzbAciFdv+d7Vz3dT6Ak15eJj/IQfgqi3TeGA0WHobx/OP7yLNE8Z119srGVDVsMyMm6zfUGXMBLL53RpJvKeXBe5rIjVyrzFPnWvu2cOj32HJA6ZMDPbWy47TMuaRzgDlY5bGeb9nV40pQbL0np1bDo+yafEf51uSeiSuXBdtFSeogBBOuGDuCa5O9gUe0J6OIkr5+t7UuG5dgxf7DfnZiAl1O77L5PxMyCJun+9dvbOmC7+bx4dk2Ce+u7fFbgDfT+e7HWkh96U6Ae0PZEFcKD2dKEzfJI8iopykrWei0jNOCc8EXmZDFkvHtgLqHK8ox christa@Christas-MacBook-Pro.local"
  ["vraj"]="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/bXvjyUZ8KCxkkOeSozMcoJm2qgLiec5jI5ervGnJXQJESEeVk90xTkLySh5Ec98JADQrTEHt0KpmteBkLNX3gpWqKPLB/I0M8CwX8yfa3YWVWPmm0xkvvQT1HV5E17tqPLNc0rOe8+6QkSlj4+m9ZNoKVYvSXUv7ul13wpIBrV7QqLRZL0MdIYKzLlpP7xC27YhXBo8CdQe57hwRUDph25Y0J0/r7nnv8xc3D8lH06LoRqRr59X8sgnZOsEfWQjkF1XBfzGc8aVGO8LE5DY+qEVWoiInpZ7TAs0TEN1pBrB5ZPzAr4zHdoDWTuo+T6OaDL/0Mqq8hB0zMTZMNm6Z vrajmohan@Vrajs-MacBook-Pro.local"
)

function set_up_users() {
  for USERNAME in "${!users[@]}"; do
    KEY="${users[$USERNAME]}"

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
  done
}

set_up_users

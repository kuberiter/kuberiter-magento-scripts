#!/bin/bash

USER="$1"

MAGENTO2_PATH=/home/$USER/MYMAGENTO2/

cd $MAGENTO2_PATH && ./kill

if [ $? -eq 0 ]; then
    sudo rm -rf $MAGENTO2_PATH
    echo SUCCESS
else
    echo FAIL
fi

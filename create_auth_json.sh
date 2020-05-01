#!/bin/bash

USER="$1"
AUTH_USER="$2"
AUTH_PASS="$3"

AUTH_JSON={\"http-basic\":{\"repo.magento.com\":{\"username\":\"$AUTH_USER\",\"password\":\"$AUTH_PASS\"}}}

AUTH_JSON_PATH=/home/$USER/auth.json

do_create_file() {
    echo -e $AUTH_JSON > $AUTH_JSON_PATH
}

do_create_file

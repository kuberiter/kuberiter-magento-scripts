#!/bin/bash

MAGENTO2_REPO=https://raw.githubusercontent.com/kuberiter/kuberiter-magento2/master/init

#$1 is function name
FN="$1"
USER="$2"
IP="$3"

MAGENTO2_PATH=/home/$USER/

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

do_pull_containers () {
    if command_exists curl; then
        cd $MAGENTO2_PATH && curl -s $MAGENTO2_REPO | bash -s MYMAGENTO2 clone
        return 0
    else
        return 1
    fi
}

do_remove_index () {
    cd $MAGENTO2_PATH/MYMAGENTO2
    docker-compose exec -T --user www-data apache rm index.php
    return 0
}

do_add_auth () {
    cd $MAGENTO2_PATH/MYMAGENTO2
    docker cp $MAGENTO2_PATH/auth.json "$(docker-compose ps -q apache)":/var/www/.composer/auth.json
    return 0
}

do_install_magento () {
    cd $MAGENTO2_PATH/MYMAGENTO2
    docker-compose exec -T --user www-data apache install-magento2 2.3
    return 0
}

do_setup_mariadb () {
    if command_exists docker ps; then
        MARIADB_CONTAINER=$(docker ps --format "{{.ID}}:{{.Image}}" | grep mariadb |cut -d ':' -f 1)
        docker container exec $MARIADB_CONTAINER bash -c "mysql -umagento -hdb -pmagento magento -e 'UPDATE core_config_data SET VALUE=\"http://$IP/\" WHERE config_id = 2;'"
        return 0
    else
        return 1
    fi
}

do_clean_magento_cache () {
    cd $MAGENTO2_PATH/MYMAGENTO2
    docker-compose exec -T --user www-data apache bin/magento cache:clean

    return 0
}

main () {

    case $FN in

    pull)
        do_pull_containers
    ;;
    remove_index)
        do_remove_index
    ;;
    add_auth)
        do_add_auth
    ;;
    install)
        do_install_magento
    ;;
    setup_mariadb)
        do_setup_mariadb
    ;;
    clean_cache)
        do_clean_magento_cache
    ;;
    *)
        echo "Invalid Choice"
    ;;
    esac
}

main

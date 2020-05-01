#!/bin/bash

set -eu

get_distribution () {
    lsb_dist=""
    # Every system that we officially support has /etc/os-release
    if [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi
    # Returning an empty string here should be alright since the
    # case statements don't act unless you provide an actual value
    echo "$lsb_dist"
}

do_docker_compose_install () {
    echo #Executing Python Install script
    sh_c='sudo -E sh -c'
    lsb_dist=$( get_distribution )
    lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

    case "$lsb_dist" in

    centos)
       if [ "$lsb_dist" = "fedora" ]; then
            pkg_manager="dnf"
            config_manager="dnf config-manager"
            enable_channel_flag="--set-enabled"
            disable_channel_flag="--set-disabled"
            pre_reqs="dnf-plugins-core"
            pkg_suffix="fc$dist_version"
        else
            pkg_manager="yum"
            config_manager="yum-config-manager"
            enable_channel_flag="--enable"
            disable_channel_flag="--disable"
            pre_reqs="yum-utils"
            pkg_suffix="el"
        fi
        (
            $sh_c "$pkg_manager install -y -q epel-release"
            $sh_c "$pkg_manager install -y -q python3"
            $sh_c "$pkg_manager install -y -q python3-pip"
            $sh_c "pip3 install docker-compose"
            $sh_c "$pkg_manager upgrade -y -q python*"
            echo #Executing git install command
            $sh_c "$pkg_manager install -y -q git"
        )
    ;;
    *)
        echo
        echo "ERROR: Unsupported distribution '$lsb_dist'"
        echo
        exit 1
    ;;

    esac
}

do_docker_compose_install
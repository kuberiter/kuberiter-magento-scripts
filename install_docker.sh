#!/bin/bash

set -e

DEFAULT_DOWNLOAD_URL="https://download.docker.com"
if [ -z "$DOWNLOAD_URL" ]; then
	DOWNLOAD_URL=$DEFAULT_DOWNLOAD_URL
fi

DEFAULT_REPO_FILE="docker-ce.repo"
if [ -z "$REPO_FILE" ]; then
	REPO_FILE="$DEFAULT_REPO_FILE"
fi

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

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

semverParse() {
	major="${1%%.*}"
	minor="${1#$major.}"
	minor="${minor%%.*}"
	patch="${1#$major.$minor.}"
	patch="${patch%%[-.]*}"
}


do_install () {
    echo "# Executing docker install script"
    if command_exists docker; then
		docker_version="$(docker -v | cut -d ' ' -f3 | cut -d ',' -f1)"
		MAJOR_W=1
		MINOR_W=10

		semverParse "$docker_version"
        
		shouldWarn=0
		if [ "$major" -lt "$MAJOR_W" ]; then
			shouldWarn=1
		fi

		if [ "$major" -le "$MAJOR_W" ] && [ "$minor" -lt "$MINOR_W" ]; then
			shouldWarn=1
		fi
        # if [ $shouldWarn -eq 1 ]; then
        #     # install_docker
		# else
        #     # install_docker
		# fi
	fi
	sh_c='sudo -E sh -c'
	lsb_dist=$( get_distribution )
	lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

	case "$lsb_dist" in

	centos)
		if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
			dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
		fi
	;;
	*)
		if command_exists lsb_release; then
			dist_version="$(lsb_release --release | cut -f2)"
		fi
		if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
			dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
		fi
	;;

	esac

	case "$lsb_dist" in

	centos)
		yum_repo="$DOWNLOAD_URL/linux/$lsb_dist/$REPO_FILE"
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
			echo #Executing script for installing utils
			$sh_c "$pkg_manager install -y -q $pre_reqs"
			echo #Executing script for adding repo
			$sh_c "$config_manager --add-repo $yum_repo"
			echo #Executing script for disable channel
			$sh_c "$config_manager $disable_channel_flag docker-ce-*"
			echo #Executing script for enable stable channel
			$sh_c "$config_manager $enable_channel_flag docker-ce-stable"
			echo #Executing script for makecache
			$sh_c "$pkg_manager makecache"
			echo #Executing script for installing docker
			$sh_c "$pkg_manager install -y -q docker-ce"
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

do_install
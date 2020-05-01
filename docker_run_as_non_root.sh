#!/bin/bash

sh_c='sudo'
docker_run_as_non_root () {
    $sh_c usermod -aG docker $(whoami)
    echo #Non root added to docker group
    $sh_c systemctl enable docker.service
    $sh_c systemctl start docker.service
    echo #Docker Daemon Started
}

docker_run_as_non_root
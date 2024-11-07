#!/usr/bin/env bash

set -euo pipefail

credentials_file=/var/lib/fogdata/PAT.pat

if [ ! -f ${credentials_file} ]; then
    echo "Docker credentials file not found"
    exit 2
fi

credentials=$(cat ${credentials_file})
docker_user=$(echo ${credentials} | awk '{print $1}')
docker_pwd=$(echo ${credentials} | awk '{print $2}')

echo ${docker_pwd} | docker login ghcr.io --username ${docker_user} --password-stdin

if (( $(grep "auth" ${HOME}/.docker/config.json | wc -l) < 2 )); then
    echo "Docker login failed"
    exit 2
fi

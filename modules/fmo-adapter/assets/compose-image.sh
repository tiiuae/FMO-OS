#!/usr/bin/env bash

set -euo pipefail

DEFAULT_IMAGE="ghcr.io/tiiuae/tii-fmo-adapter-files"

for i in {1..3}; do
    COMPOSE_IMAGE=""

    read -p "Enter adapter image [${DEFAULT_IMAGE}]: " COMPOSE_IMAGE
    COMPOSE_IMAGE=${COMPOSE_IMAGE:-${DEFAULT_IMAGE}}

    if (( $(awk -F: '{print length($1)}' <<< "${COMPOSE_IMAGE}") == $(awk '{print length($1)}' <<< "${COMPOSE_IMAGE}") )); then
        TAG=""
        read -p "Enter tag for \"${COMPOSE_IMAGE}\": " TAG
        COMPOSE_IMAGE="${COMPOSE_IMAGE}:${TAG}"
    fi

    docker pull ${COMPOSE_IMAGE}

    if (( $? == 0 )); then
        container_id=$(docker create ${COMPOSE_IMAGE})

        docker cp $container_id:/data/ ${PWD}
        docker cp $container_id:/templates/ ${PWD}
        docker cp $container_id:/scripts/ ${PWD}

        docker rm $container_id

        exit 0
    fi

    echo "Fetching adapter image \"${COMPOSE_IMAGE}\" failed."
done

exit 2

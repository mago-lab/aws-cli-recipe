#!/bin/bash

# Audion에서 사용되는 container를 관리 및 실행하는 스크립트
# 실행 방법: ./launch_audion.sh [start|stop|restart|status]

# Declare an associative array (dictionary) for microservices
declare -A service_map


# Add microservices to the dictionary
service_map["mago-signal-processing"]="release-1.0.0"
service_map["mago-voice-separation"]="release-1.3.1"
service_map["mago-speaker-diarization"]="release-0.2.1"
service_map["mago-s2t-basic"]="release-1.2.0"
service_map["mago-s2t-postproc"]="release-1.1.0"
service_map["mago-vocal-biomarker"]="release-0.1.0"
service_map["mago-emotion"]="release-0.3.1"
service_map["mago-vad"]="develop"
service_map["mago-epd"]="develop"
service_map["mago-mllm"]="release-0.1.0"


# Iterate over keys
for key in "${!service_map[@]}"; do
    version=${service_map[$key]}

    # Check if the container is running
    if [ "$(docker ps -q -f name=$key)" ]; then
        printf "🟢 %-25s : %-13s : running\n" "$key" "$version"
        continue
    else
        printf "🔴 %-25s : %-13s : not running\n" "$key" "$version"
    fi

    # Check if the folder exists of the microservice
    # If it exists, git checkout the version and run docker-compose up -d
    # TODO:
    #   - git pull
    #   - docker-compose up -d --build

    # step 1: check if the folder exists and if not, clone the repository
    if [ ! -d "$key" ]; then
        # Overwrite `printf` the previous line
        printf "\033[A\033[K"
        printf "🔴 %-25s : %-13s : folder not found\n" "$key" "$version"

        # Clone the repository
        # git clone https://github.com/holamago/${key}.git
        continue
    fi

    # step 2: git checkout the version
    cd $key
    git checkout $version > /dev/null 2>&1

    # step 3: check version of the git repository
    git_version=$(git rev-parse --abbrev-ref HEAD)
    if [ "$git_version" != "$version" ]; then
        # Overwrite `printf` the previous line
        printf "\033[A\033[K"
        printf "🔴 %-25s : %-13s : version mismatch\n" "$key" "$version"
        cd -
        continue
    fi

    # step 4: build the docker image and run the container
    docker compose up -d > /dev/null 2>&1

    # step 5: check if the container is running
    if [ "$(docker ps -q -f name=$key)" ]; then
        printf "\033[A\033[K"
        printf "🟢 %-25s : %-13s : running\n" "$key" "$version"
    else
        printf "\033[A\033[K"
        printf "🔴 %-25s : %-13s : not running\n" "$key" "$version"
    fi

    cd -

done
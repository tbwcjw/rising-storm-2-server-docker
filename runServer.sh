#/bin/bash

# Title: runServer.sh
# Author: Christian Wiles <tbwcjw>
# Email: christian@sp00py.online
# Created: 10/15/2024
# Description: This script is used to manage a Rising Storm 2 Multiplayer Dedicated Server docker instance.
# Usage: see usage(), or README.md
# Arguments: $# accepted only
# Dependencies: zip, docker, docker-compose, openssl
# Exit Codes: 0 - Success 1 - Invalid arguments, Lock presence, Invalid selection
# License: MIT License

usage() {
echo "usage $0 <build|run|attach|backup|restore|debug|regencerts|hackerman|status|stop>

commands:

build       - builds the container
run         - PROD: runs server with docker-compose, leading to less resource usage but less flexibility. better for production.
attach      - attach to running containers.
debug       - DEBUG: runs the server with docker compose. higher mem usage but doesn't require a rebuild anytime the composer yaml is edited.
regencerts  - regenerate the ssl certificates for the nginx proxy
backup      - backs up the ./server and ./steamcmd directories into ./backups/ directory as a zip
restore	    - launch restore utility. will stop the server.
hackerman   - launches into the containers bash shell.
status      - returns the docker ps status for the container.
stop        - stops the server and container.
"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

build() {
    mkdir -p ./server ./steamcmd 
    mkdir -p ./proxy/img ./proxy/certs

    USER_ID=$(whoami)
    GROUP_ID=$(whoami)

    chown -R "$USER_ID":"$GROUP_ID" ./server ./steamcmd ./proxy/img ./proxy/certs 
    
    sudo chmod +x rs2server.sh

    sudo docker build --no-cache -t rs2server .

    regencerts

    echo "build complete. use 'run' to start the instance"
    exit 0
}

SCRIPT_DIR="$(dirname "$0")"

SERVER_LOCKFILE="$SCRIPT_DIR/server.container.id"
PROXY_LOCKFILE="$SCRIPT_DIR/proxy.container.id"

SERVER_CONTAINER_ID=$(docker ps -aqf "name=rs2server")
PROXY_CONTAINER_ID=$(docker ps -aqf "name=rs2proxy")

check_lock() {
    if [ -e "$SERVER_LOCKFILE" ]; then
        echo "server.container.id is lock. is the server already running?"
        exit 1
    fi
    if [ -e "$PROXY_LOCKFILE" ]; then
        echo "proxy.container.id is lock. is the server already running?"
        exit 1
    fi
}

regencerts() {
    mkdir -p ./proxy/certs
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout proxy/certs/nginx-selfsigned.key -out proxy/certs/nginx-selfsigned.crt
}

run() {
    check_lock
    rm server.container.id
    rm proxy.container.id

    docker-compose -f rs2server.yaml up -d
    echo "$SERVER_CONTAINER_ID" >> server.container.id
    echo "$PROXY_CONTAINER_ID" >> proxy.container.id
    
    sudo docker logs -f --tail 10 "${SERVER_CONTAINER_ID}" &
    sudo docker logs -f --tail 10 "${PROXY_CONTAINER_ID}" &
    wait
}

attach() {
    sudo docker logs -f --tail 10 "${SERVER_CONTAINER_ID}" &
    sudo docker logs -f --tail 10 "${PROXY_CONTAINER_ID}" &
    wait
    echo "the server is not running"
}

debug() {
    check_lock
    rm server.container.id
    rm proxy.container.id
    
    sudo chmod 777 -R server/server/ROGame/Config/
    docker compose -f rs2server.yaml up -d 
    echo "$SERVER_CONTAINER_ID" >> server.container.id
    echo "$PROXY_CONTAINER_ID" >> proxy.container.id
    
    sudo docker logs -f --tail 10 "${SERVER_CONTAINER_ID}" &
    sudo docker logs -f --tail 10 "${PROXY_CONTAINER_ID}" &
    wait
    echo "the server is not running"
}

stop() {
    rm server.container.id
    rm proxy.container.id
    
    docker stop "$SERVER_CONTAINER_ID"
    docker stop "$PROXY_CONTAINER_ID"
}

backup() {
    now=$(date +"%Y%m%d_%H%M%S")
    archive_dir="./backup/$now"
    mkdir -p "$archive_dir"

    cp --verbose -r ./server/server/ROGame/Config "$archive_dir/Config"  #config files for ROGame
    cp --verbose -r ./steamcmd "$archive_dir/steamcmd"                     #steamcmd directory
    cp --verbose -r ./proxy "$archive_dir/proxy"                        #proxy files
	
    (cd "$archive_dir" && zip -r "../${now}.zip" .)
    
    rm -rf "$archive_dir"
    echo "Backup complete"
}
restore() {
    stop
    #find zips
    zips=$(ls "backup/"*.zip 2>/dev/null)
    #no zips? exit
    if [ -z "$zips" ]; then
        echo "No zip files found in backup/"
        exit 0
    fi
    #numerate zips
    i=1
    for zip_file in $zips; do
        echo "$i) $(basename "$zip_file")"
        i=$((i+1))
    done
    #get user input
    read -p "Enter the number of the zip file: " selection
    #validate input
    if [ "$selection" -lt 1 ] || [ "$selection" -gt "$((i-1))" ]; then
        echo "Invalid selection."
        exit 1
    fi
    #selected zip to restore from
    selected_zip=$(echo "$zips" | sed -n "${selection}p")

    echo "restoring from $selected_zip"
    #move selected zip to root
    sudo cp "$selected_zip" "$(basename "$selected_zip")"
    #temp dir
    mkdir -p target
    #unzip into temp
    unzip "$(basename "$selected_zip")" -d target
    #get the folder name inside the temp dir (filename of zip)
    folder=$(basename "$selected_zip" .zip)
    #remove the compressed zip
    sudo rm "$(basename "$selected_zip")" 
    #copy all the shit
    cp --verbose -r target/Config/* server/server/ROGame/Config 
    cp --verbose -r target/steamcmd/ ./
    cp --verbose -r target/proxy/ ./
    #delete the temp file
    rm -rf target
    echo "restoration complete"
}
hackerman() {
    sudo docker exec -it "$SERVER_CONTAINER_ID" /bin/bash
}

case $1 in
    build)
        echo "Building..."
        build
        ;;
    run)
        echo "Running in PROD..."
        run
        ;;
    attach)
        echo "Attaching to containers..."
        attach
        ;;
    debug)
        echo "Running in DEBUG..."
        debug
        ;;
    regencerts)
        echo "Regenerating certificate files..."
        regencerts
        ;;
    stop)
        echo "Stopping..."
        stop
        exit 0
        ;;
    status)
        docker-compose -f rs2server.yaml ps
        ;;
    hackerman)
        echo "Entering container bash shell..."
        hackerman
        ;;
    backup)
        echo "Backing up volumes..."
        backup
        ;;
    restore)
    	echo "Launching restore utility..."
    	restore
    	;;
    *)
        usage
        ;;
esac

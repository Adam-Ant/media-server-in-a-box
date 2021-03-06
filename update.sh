#!/bin/bash
### Script for building and running a media processing system using docker
### Adam Dodman <adam.dodman@gmx.com>
# Prereqs: docker, docker-compose, curl (https), git

export VOLDIR="/volumes/media-server"
SERVICES=("radarr" "deluge" "nzbget" "plex" "plexpy" "sickrage" "nginx" "hydra") 
SERVICEUID=("901" "902" "904" "900" "905" "906" "0" "907")

[[ $EUID -ne 0 ]] && echo "Please run this script as root" && exit 1

#Check if docker is installed and running
docker version &> /dev/null
[[ $? -ne 0 ]] && echo "Cannot connect to Docker daemon. Please check your configuration." && exit 1
#Check if docker-compose is installed
docker-compose version &> /dev/null
[[ $? -ne 0 ]] && echo "docker-compose not found. Please check your configuration." && exit 1
# Check if media container is configured
[[ $(docker ps -a --filter="name=media" | wc -l) != "2" ]] && echo "Cannot find a media container - please configure one with your media mounted at /media inside the container. to keep the size down use tianon/true)" && exit 1

# Check if volumes folder exists
[[ ! -d $VOLDIR ]] && echo "Creating volumes folder..." && mkdir -p $VOLDIR

slen=${#SERVICES[@]}
for ((i=0; i<$slen; i++)); do
 [[ ! -d $VOLDIR/${SERVICES[$i]} ]] && echo "Creating folder $VOLDIR/${SERVICES[$i]}" && mkdir -p $VOLDIR/${SERVICES[$i]}
 [[ $( ls -dn $VOLDIR/${SERVICES[$i]} | awk '{print $3}') != ${SERVICEUID[$i]} ]] && echo "Chowning $VOLDIR/${SERVICES[$i]} to user ${SERVICEUID[$i]}" && chown -R ${SERVICEUID[$i]}:${SERVICEUID[$i]} $VOLDIR/${SERVICES[$i]}
done

#Since we are not using net=host, we need to whitelist the subnet in plex. ##TODO## Make this overrideable with commandline argument
[[ ! -a $VOLDIR/plex/Preferences.xml ]] && echo Adding subnet to Plex Whitelist... && \
	echo -e "<?xml version="1.0" encoding="utf-8"?>\n<Preferences allowedNetworks="$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | grep -v '172.*')/255.255.0.0" />" > $VOLDIR/plex/Preferences.xml

[[ ! -a ./docker-compose.yml ]] && echo "Downloading Docker Compose config.." && curl -sSL https://raw.githubusercontent.com/Adam-Ant/media-server-in-a-box/master/docker-compose.yml > ./docker-compose.yml
[[ ! -a ./.env ]] && echo "Setting up env file..." &&  echo "VOLDIR=${VOLDIR}" > ./.env

[[ ! -a $VOLDIR/nginx/nginx.cfg ]] && echo "Downloading nginx.cfg..." && curl -sSL https://raw.githubusercontent.com/Adam-Ant/media-server-in-a-box/master/nginx.cfg > $VOLDIR/nginx/nginx.cfg

[[ ! -d $VOLDIR/nginx/Organizr ]] && echo "Downloading Organizr..." && git -C $VOLDIR/nginx clone https://github.com/causefx/Organizr && chown -R 82:82 $VOLDIR/nginx/Organizr

cd $VOLDIR/nginx/Organizr/ && git pull -q

echo "#####################################"
echo "# Config and directory struture OK! #"
echo "#####################################"
echo
echo "Run docker-compose up -d to start the containers..."

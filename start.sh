#!/bin/bash
### Script for building and running a media processing system using docker
### Adam Dodman <adam.dodman@gmx.com>
# Prereqs: docker, docker-compose, curl (https)

export VOLDIR="/volumes/media-server"
SERVICES=("couchpotato" "deluge" "headphones" "nzbget" "plex" "plexpy" "sickrage" "launcher")
SERVICEUID=("745" "647" "526" "236" "787" "426" "439" "0")

[[ $EUID -ne 0 ]] && echo "Please run this script as root" && exit 1

#Check if docker is installed and running
docker version &> /dev/null
[[ $? -ne 0 ]] && echo "Cannot connect to Docker daemon. Please check your configuration." && exit 1
#Check if docker-compose is installed
docker-compose version &> /dev/null
[[ $? -ne 0 ]] && echo "docker-compose not found. Please check your configuration." && exit 1
# Check if media container is configured
[[ $(docker ps -a --filter="name=media" | wc -l) != "2" ]] && echo "Cannot find a media container - please configure one with your media mounted at /media inside the container before running this script (to keep the size down use tianon/true)" && exit 1

# Check if volumes folder exists
[[ ! -d $VOLDIR ]] && echo "Creating volumes folder..." && mkdir -p $VOLDIR
[[ ! -d $VOLDIR/couchpotato ]]

slen=${#SERVICES[@]}
for ((i=0; i<$slen; i++)); do
 [[ ! -d $VOLDIR/${SERVICES[$i]} ]] && echo "Creating folder $VOLDIR/${SERVICES[$i]}" && mkdir -p $VOLDIR/${SERVICES[$i]}
 [[ $( ls -dn $VOLDIR/${SERVICES[$i]} | awk '{print $3}') != ${SERVICEUID[$i]} ]] && echo "Chowning $VOLDIR/${SERVICES[$i]} to user ${SERVICEUID[$i]}" && chown ${SERVICEUID[$i]}:${SERVICEUID[$i]} $VOLDIR/${SERVICES[$i]}
done

[[ ! -a $VOLDIR/launcher/docker-compose.yml ]] && echo "Downloading docker-compose.yml.." && curl -sSL https://raw.githubusercontent.com/Adam-Ant/media-server-in-a-box/master/docker-compose.yml > $VOLDIR/launcher/media-compose.yml
echo "Starting services..."
exec docker-compose -p media -f $VOLDIR/launcher/media-compose.yml up -d

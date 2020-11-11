#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# vim: set fileencoding=utf-8
#############################################################################
# This file is part of the Docker Samba Active Diretory Project
#
# Copyright (C) HJCMS http://www.hjcms.de, (C) 2007-2020
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; see the file COPYING.LIB.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.
#############################################################################

set +x

test -e ads-config.cfg || {
  echo "FATAL: ads-config.cfg not exists"
  exit 1
}
source ads-config.cfg

if [[ "$1" == "-h" ]] ; then
cat <<EOF

  Simple run ./`basename $0`

  Otherwise:
    ./`basename $0` [with additional docker options]

  Example:
    ./`basename $0` --network bridge

EOF
  exit 0
fi

## Samba AD/Administrator Password
declare _PASSWORD="${ADS_PASSWORD:-"P@55word"}"

## Samba Debug Level 0-5
declare i _DEBUGLEVEL="${ADS_DEBUGLEVEL:-3}"

## We need a Mount target
declare _MOUNT_TARGET=/var/data/docker/mount/${ADS_HOSTNAME}

## Docker run - Volume Definition
declare _VOLUME="${_MOUNT_TARGET}:/var/lib/samba"

_FORWARD_IPV4=$(host -4 -W 2 ${ADS_DNS_FORWARDER} | \
  grep '[0-9]\{2,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | \
  awk '{print $NF}')
test -n "${_FORWARD_IPV4}" || {
  echo "Fatal: missing SOA DNS entry"
  exit 1
}

_SERVER_IPV4=$(host -4 -W 2 ${ADS_HOSTNAME} | \
  grep '[0-9]\{2,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | \
  awk '{print $NF}')

test -n "${_SERVER_IPV4}" || {
cat <<EOF

  Can't find a DNS entry für this Service.

  Please add the IPv4 Address for your Server manually.
  With "docker network inspect bridge" you can fetch
  the right Network.

EOF
  read -p "SERVER_IPV4:"

  if test -n "$REPLY" ; then
    _SERVER_IPV4=$REPLY
  else
    echo "Script aborted"
    exit 1
  fi
}

_IMAGE="$(docker images --filter label=de.hjcms.label=SAMBA \
  --format '{{.CreatedAt}} {{.Repository}}:{{.Tag}}' | \
  sort -r | awk '{print $NF}' | head -1)"

cat <<EOF

 Configuration summary:
  ADS_PASSWORD      ${_PASSWORD}
  ADS_HOSTNAME      ${ADS_HOSTNAME}
  ADS_DOMAIN        ${ADS_DOMAIN}
  ADS_DNS_FORWARDER ${ADS_DNS_FORWARDER}
  ADS_DNS_SEARCH    ${ADS_DNS_SEARCH}
  ADS_REALM         ${ADS_REALM}
  ADS_DEBUGLEVEL    ${_DEBUGLEVEL}
  Mount Volume      ${_VOLUME}
  IPv4 Address      ${_SERVER_IPV4}
  Using Image       ${_IMAGE}

  If the Server has been started without errors.
  It will create a new bash shell for debugging purposes.

 WARNING:
  Do not close the bash, this kills the Container process!

  If you want to stop the server with saving your changes.
  Open an new Shell from your Docker User Account and run:
    docker stop ${ADS_HOSTNAME}

  After this, you can start the Server with "docker start":
    docker start ${ADS_HOSTNAME}

  For entering the Container you can use "docker attach":
    docker attach ${ADS_HOSTNAME}

  Reload behind configuration changes
    smbcontrol -t2 all reload-config

  Optional shutdown the server with
    smbcontrol -t2 all shutdown

EOF

read -p "Press <enter> for cancel or \"yes\" to run docker container: "
_inp=$(echo $REPLY | awk '{print tolower($1)}')
if [[ "${_inp}" == "y" ]] || [[ "${_inp}" == "yes" ]] ; then
  mkdir -vp ${_MOUNT_TARGET}
  echo "Start Docker run ..."
  docker run --privileged -it \
    --ip ${_SERVER_IPV4} \
    --name ${ADS_HOSTNAME} \
    --hostname ${ADS_HOSTNAME} \
    --dns ${_FORWARD_IPV4} \
    --env "ADS_HOSTNAME=${ADS_HOSTNAME}" \
    --env "ADS_SERVER_IPV4=${_SERVER_IPV4}" \
    --env "ADS_REALM=${ADS_REALM}" \
    --env "ADS_DEBUGLEVEL=${_DEBUGLEVEL}" \
    --env "ADS_PASSWORD=${_PASSWORD}" \
    --env "ADS_DNS_FORWARDER=${ADS_DNS_FORWARDER}" \
    --env "ADS_DNS_FORWARDIP=${_FORWARD_IPV4}" \
    --env "ADS_DNS_SEARCH=${ADS_DNS_SEARCH}" \
    --volume ${_VOLUME} $@ \
    ${_IMAGE} | tee docker-ad-run.log

  if [[ $? == 0 ]] ; then
    docker ps
  fi
fi

##EOF

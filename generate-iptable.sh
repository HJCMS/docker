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

declare _bindAddr=""
declare _interface=""

function _defaultIPv4Addr()
{
  local _iface=$(ip route | grep '^default' | awk '{print $NF}' 2>/dev/null)
  if [ -f /sys/class/net/${_iface}/operstate ] &&
    [ $(cat /sys/class/net/${_iface}/operstate) == "up" ]; then
    _interface=${_iface}
    _bindAddr=$(ip -br -4 addr show dev ${_iface} | awk '{print $NF}' | cut -d'/' -f1)
  fi
}

_defaultIPv4Addr

## $(ip -br -4 addr show scope global dev eno1 | awk '{print $NF}' | cut -d'/' -f1")
echo
docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Networks}}\t{{.Status}}\t{{.Names}}"

declare -a _info=($(docker ps --filter label=de.hjcms.label=SAMBA --format "{{.ID}} {{.Networks}} {{.Names}} {{.Image}}"))

if test ! -x "$(which jq 2>/dev/null)" ; then
  echo "Missing json Parser https://stedolan.github.io/jq/"
  exit 1
fi

_t=$(docker network inspect bridge --format "{{json .Options}}" | jq '."com.docker.network.bridge.name"')
declare _bridgeiface="$(echo ${_t} | sed 's/\"//g')"

cat <<EOF
########################################################################################

Container ID    : ${_info[0]}
Network Type    : ${_info[1]}
Container Name  : ${_info[2]}
Container Image : ${_info[3]}

Bridge Interface : ${_bridgeiface}
Primary Outgoing Interface : ${_interface}
Primary Interface IPv4 Address : ${_bindAddr}

!!! WARNING !!!
Any changes in Firewalld will destroy manual Iptable rules!

Make first a backup with iptables-save ;-)

Configure Firewalld:
  firewall-cmd --get-active-zones
  firewall-cmd --permanent --zone=<Primary Interface Zone> --add-masquerade
  firewall-cmd --permanent --zone=trusted --add-interface=${_bridgeiface}
  firewall-cmd --permanent --zone=trusted --add-service=dns
  firewall-cmd --permanent --zone=trusted --add-service=kerberos
  firewall-cmd --permanent --zone=trusted --add-service=kpasswd
  firewall-cmd --permanent --zone=trusted --add-service=ldap
  firewall-cmd --permanent --zone=trusted --add-service=samba-dc
  firewall-cmd --permanent --zone=trusted --add-service=samba-client
  firewall-cmd --permanent --zone=trusted --add-masquerade
  firewall-cmd --reload
  firewall-cmd --permanent --zone=trusted --list-all
  trusted (active)
    target: ACCEPT
    icmp-block-inversion: no
    interfaces: docker0
    services: dns kerberos kpasswd ldap samba-dc samba-client
    masquerade: yes

Generate iptables:
  iptables -S DOCKER-USER || iptables -N DOCKER-USER
  iptables -D DOCKER-USER -j RETURN
  iptables -A DOCKER-USER -i ${_bridgeiface} -o ${_interface} -j ACCEPT
  iptables -A DOCKER-USER -i ${_interface} -o ${_bridgeiface} -j ACCEPT
  iptables -A DOCKER-USER -j RETURN
  iptables -S DOCKER-USER

Capture the Docker Interface with tcpdump and ping it from outside:
  tcpdump 'icmp[icmptype] == icmp-echo or icmp[icmptype] == icmp-echoreply' -i ${_bridgeiface} -vvv

Now Check from your Network with ping,nmap or nc.

if ist works ...
Change to your Windows Machine and add a route to the docker Network!
If your Windows Machine is a Virtual Machine add the route to your Hypervisor!
Copy my "connection-test-remote.ps1" on it and test the remote Connection.

If the "connection-test-remote.ps1" running with no errors you can use a Domain JOIN.

good luck and have fun ...

EOF

#!/usr/bin/env bash
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
set -o errexit

## Container ID
declare _id=""
## DNS Hostname
declare _nsh=""
## DNS IpAddress
declare _nip=""
## Site Name
declare _site=""
## Enable nmap
declare -i _nmap=0

function _notify()
{
  echo -e "\n\033[1m- Check: $1 \033[0m"
}

function _print()
{
  echo -e "\n\033[1m- $1 \033[0m"
}

function _trim()
{
  echo $1 | sed 's,[ \t\n\r]\+,,'
}

function _ping()
{
  ping -c3 ${1}
  test $? == 0 || {
    echo "ping failed with ip: ${1}"
    echo "docker inspect 'container-name' can help you to find the right IPv4 address"
    exit 1
  }
}

function _usage ()
{
cat <<EOF

  USAGE:
    ./test-ad-connection.sh -i [Container ID] -e

  OPTIONS:
    -i  Container ID
    -e  if installed, enabled nmap TCP port scan support

  EXAMPLE:
    ./test-ad-connection.sh -i 04rg60e03 -e

EOF

  docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Networks}}\t{{.Names}}"
  echo
  exit 1
}

while getopts i:e opt; do
  case $opt in
    i)
      _id="$OPTARG"
      ;;
    e)
      _nmap=1
      ;;
    *)
      _usage
      ;;
  esac
done

test -x "$(which --skip-alias --skip-functions dig 2>/dev/null)" || {
  _print "Missing 'dig' from (named|bind?)-utils"
  exit 1
}

test -n "${_id}" || {
  _print "Missing Container ID"
  _usage
}

_nip=$(docker inspect \
  --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${_id} 2>/dev/null)

test -n "${_nip}" || {
  _print "Missing DNS IPv4 Address"
  _usage
}

_print "Ping to ${_nip}"
_ping ${_nip}

_print "DNS Domain"
_temp=$(docker exec -it ${_id} hostname -d)
_nsh=$(_trim ${_temp})

test -n "${_nsh})" || {
  _print "Missing DNS Domain"
  _usage
}
echo "- ${_nsh}"

_print "FQDN"
_temp=$(docker exec -it ${_id} hostname -f)
_fqdn=$(_trim ${_temp})
echo "- ${_fqdn}"

_print "Site"
_temp=$(docker exec -it ${_id} hostname -s)
_site=$(_trim ${_temp})
echo "- ${_site}"

_notify "SOA/NS and A Records"
dig -t ANY ${_nsh} +noall +answer @${_nip}
dig -t A ${_fqdn} +noall +answer @${_nip}

_notify "RFC1510 KDC SRV (_kerberos._tcp.${_nsh})"
dig -4 -t SRV +noall +answer _kerberos._tcp.${_nsh} @${_nip}

_notify "RFC1510 UDP-KDC SRV (_kerberos._udp.${_nsh})"
dig -4 -t SRV +noall +answer _kerberos._udp.${_nsh} @${_nip}

_notify "KDC SRV (_kerberos._tcp.dc._msdcs.${_nsh})"
dig -4 -t SRV +noall +answer _kerberos._tcp.dc._msdcs.${_nsh} @${_nip}

if [ -n "${_site}" ] ; then
  _notify "RFC1510 KDC@Site SRV (_kerberos._tcp.${_site}._sites.${_nsh})"
  dig -4 -t SRV +noall +answer _kerberos._tcp.${_site}._sites.${_nsh} @${_nip}
fi

_notify "LDAP SRV (_ldap._tcp.${_nsh})"
dig -4 -t SRV +noall +answer _ldap._tcp.${_nsh} @${_nip}

_notify "LDAP PDC SRV (_ldap._tcp.pdc._msdcs.${_nsh})"
dig -4 -t SRV +noall +answer _ldap._tcp.pdc._msdcs.${_nsh} @${_nip}

_notify "LDAP GC SRV (_ldap._tcp.gc._msdcs.${_nsh})"
dig -4 -t SRV +noall +answer _ldap._tcp.gc._msdcs.${_nsh} @${_nip}

_notify "LDAP DC SRV (_ldap._tcp.dc._msdcs.${_nsh})"
dig -4 -t SRV +noall +answer _ldap._tcp.dc._msdcs.${_nsh} @${_nip}

if [ -n "${_site}" ] ; then
  _notify "LDAP @Site SRV (_ldap._tcp.${_site}._sites.${_nsh})"
  dig -4 -t SRV +noall +answer _ldap._tcp.${_site}._sites.${_nsh} @${_nip}

  _notify "LDAP GC@Site SRV (_ldap._tcp.${_site}._sites.gc._msdcs.${_nsh})"
  dig -4 -t SRV +noall +answer _ldap._tcp.${_site}._sites.gc._msdcs.${_nsh} @${_nip}

  _notify "LDAP Dc@Site SRV (_ldap._tcp.${_site}._sites.dc._msdcs.${_nsh})"
  dig -4 -t SRV +noall +answer _ldap._tcp.${_site}._sites.dc._msdcs.${_nsh} @${_nip}

  _notify "LDAP DcByGuid SRV (_ldap._tcp.${_site}.domains._msdcs.${_nsh})"
  dig -4 -t SRV +noall +answer _ldap._tcp.${_site}.domains._msdcs.${_nsh} @${_nip}
fi

_notify "RFC1510 KPWD SRV (_kpasswd._tcp.${_nsh})"
dig -4 -t SRV +noall +answer _kpasswd._tcp.${_nsh} @${_nip}

_notify "RFC1510 UDP-KPWD SRV (_kpasswd._udp.${_nsh})"
dig -4 -t SRV +noall +answer _kpasswd._udp.${_nsh} @${_nip}

_notify "Generic GC SRV (_gc._tcp.${_nsh})"
dig -4 -t SRV +noall +answer _gc._tcp.${_nsh} @${_nip}

if [ -n "${_site}" ] ; then
  _notify "Generic GC@Site SRV (_gc._tcp.${_site}._sites.${_nsh})"
  dig -4 -t SRV +noall +answer _gc._tcp.${_site}._sites.${_nsh} @${_nip}
fi

if test ${_nmap} -gt 0 ; then
  _print "Finally running nmap"
  nmap -Pn -sT -pT:53-3600 ${_nip}
  echo
fi

echo -e "\ndone\n"

#EOF

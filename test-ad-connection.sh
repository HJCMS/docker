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

declare _host=""
declare _dnsip=""
declare _site=""
declare -i _nmap=0

function _usage ()
{
cat <<EOF

  USAGE:
    ./test-ad-connection.sh -d [DNS Domain] -i [IPv4 Address] -s [SITE] -e

  OPTIONS:
    -d  Samba DNS Domain - printed when provisioning
    -i  IPv4 Address of your Container
    -e  if installed, enabled nmap TCP port scan support

  EXAMPLE:
    ./test-ad-connection.sh -d ad.smb.virt -i 172.16.0.3

EOF
  exit 1
}

function _notify()
{
  echo -e "\n\033[1m- Check: $1 \033[0m"
}

function _print()
{
  echo -e "\n\033[1m- $1 \033[0m"
}

while getopts d:i:s:e opt; do
  case $opt in
    d)
      _host=$OPTARG
      ;;
    i)
      _dnsip="$OPTARG"
      ;;
    e)
      _nmap=1
      ;;
    *)
      _usage
      ;;
  esac
done

test -n "${_host}" || {
  _print "Missing DNS Domain"
  _usage
}

test -n "${_dnsip}" || {
  _print "Missing DNS IPv4 Address"
  _usage
}

ping -c3 ${_dnsip}

test $? == 0 || {
 echo "ping failed with ip: ${_dnsip}"
 echo "docker inspect 'container-name' can help you to find the right IPv4 address"
 exit 1
}

_fqdn="$(dig -4 -t NS ${_host} @${_dnsip} +noall +answer | awk '{print $NF}')"

_site="$(echo ${_fqdn} | cut -d. -f1)"
_notify "FQDN"
echo ${_fqdn}
_notify "_site"
echo ${_site}

_notify " SOA/NS/A Record"
dig -t ANY ${_host} +noall +answer @${_dnsip}
dig -t A ${_fqdn} +noall +answer @${_dnsip}

_notify "RFC1510 KDC SRV _kerberos._tcp.${_host}"
dig -4 -t SRV +noall +answer _kerberos._tcp.${_host} @${_dnsip}

_notify "RFC1510 UDP-KDC SRV _kerberos._udp.${_host}"
dig -4 -t SRV +noall +answer _kerberos._udp.${_host} @${_dnsip}

_notify "KDC SRV _kerberos._tcp.dc._msdcs.${_host}"
dig -4 -t SRV +noall +answer _kerberos._tcp.dc._msdcs.${_host} @${_dnsip}

if [ -n "${_site}" ] ; then
  _notify "RFC1510 KDC@Site SRV _kerberos._tcp.${_site}._sites.${_host}"
  dig -4 -t SRV +noall +answer _kerberos._tcp.${_site}._sites.${_host} @${_dnsip}
fi

_notify "LDAP SRV _ldap._tcp.${_host}"
dig -4 -t SRV +noall +answer _ldap._tcp.${_host} @${_dnsip}

_notify "LDAP PDC SRV _ldap._tcp.pdc._msdcs.${_host}"
dig -4 -t SRV +noall +answer _ldap._tcp.pdc._msdcs.${_host} @${_dnsip}

_notify "LDAP GC SRV _ldap._tcp.gc._msdcs.${_host}"
dig -4 -t SRV +noall +answer _ldap._tcp.gc._msdcs.${_host} @${_dnsip}

_notify "LDAP DC SRV _ldap._tcp.dc._msdcs.${_host}"
dig -4 -t SRV +noall +answer _ldap._tcp.dc._msdcs.${_host} @${_dnsip}

if [ -n "${_site}" ] ; then
  _notify "LDAP @Site SRV _ldap._tcp.${_site}._sites.${_host}"
  dig -4 -t SRV +noall +answer _ldap._tcp.${_site}._sites.${_host} @${_dnsip}

  _notify "LDAP GC@Site SRV _ldap._tcp.${_site}._sites.gc._msdcs.${_host}"
  dig -4 -t SRV +noall +answer _ldap._tcp.${_site}._sites.gc._msdcs.${_host} @${_dnsip}

  _notify "LDAP Dc@Site SRV _ldap._tcp.${_site}._sites.dc._msdcs.${_host}"
  dig -4 -t SRV +noall +answer _ldap._tcp.${_site}._sites.dc._msdcs.${_host} @${_dnsip}

  _notify "LDAP DcByGuid SRV _ldap._tcp.${_site}.domains._msdcs.${_host}"
  dig -4 -t SRV +noall +answer _ldap._tcp.${_site}.domains._msdcs.${_host} @${_dnsip}
fi

_notify "RFC1510 KPWD SRV _kpasswd._tcp.${_host}"
dig -4 -t SRV +noall +answer _kpasswd._tcp.${_host} @${_dnsip}

_notify "RFC1510 UDP-KPWD SRV _kpasswd._udp.${_host}"
dig -4 -t SRV +noall +answer _kpasswd._udp.${_host} @${_dnsip}

_notify "Generic GC SRV _gc._tcp.${_host}"
dig -4 -t SRV +noall +answer _gc._tcp.${_host} @${_dnsip}

if [ -n "${_site}" ] ; then
  _notify "Generic GC@Site SRV _gc._tcp.${_site}._sites.${_host}"
  dig -4 -t SRV +noall +answer _gc._tcp.${_site}._sites.${_host} @${_dnsip}
fi

if test ${_nmap} -gt 0 ; then
  _print "Finally running nmap"
  nmap -Pn -sT -pT:53-3600 ${_dnsip}
  echo
fi

echo -e "\ndone\n"

#EOF

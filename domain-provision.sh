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

set -Eeo pipefail

_DEBUGLEVEL="${ADS_DEBUGLEVEL:-"3"}"
_HOST="$(hostname -s)"
_DOMAIN="${ADS_DOMAIN:-"$(hostname -f)"}"
_DNSSEARCH="${ADS_DNS_SEARCH:-"${_DOMAIN}"}"
_REALM="${ADS_REALM:-"$(echo $(hostname -d) | awk '{print toupper($NF)}')"}"
_PASSWORD="${ADS_PASSWORD:-"P@55word"}"
if test -n "${_PASSWORD}" ; then
  echo "-- AD Password set"
else
  echo "-- WARNING - AD Password not set"
fi

## replace auto generated docker dns entries at start!
if [[ -n "${_DOMAIN}" ]] && [[ -n "${ADS_DNS_FORWARDIP}" ]]; then
  echo "Updating: /etc/resolv.conf"
  cat > /etc/resolv.conf <<EOF
nameserver localhost
nameserver ${ADS_DNS_FORWARDIP}
search ${_DNSSEARCH}
options timeout:5
EOF
fi

if test ! -f /etc/samba/smb.conf ; then

  rm -f /etc/krb5.conf

  if test ! -d /var/lib/samba ; then
    cp -av /var/lib/samba.core /var/lib/samba
  else
    for d in usershares printers winbindd_privileged ; do
      if test ! -d /var/lib/samba/${d} ; then
        cp -av /var/lib/samba.core/${d} /var/lib/samba/
      fi
    done
  fi

  if test ! -d /var/lib/samba/sysvol ; then
    mkdir -p /var/lib/samba/sysvol/${_DOMAIN}/scripts
    chown -R root:sambashare /var/lib/samba/sysvol
  fi

  echo "cat /etc/resolv.conf"
  cat /etc/resolv.conf

  samba-tool domain provision \
    --use-rfc2307 \
    --host-ip=${ADS_SERVER_IPV4} \
    --host-name=${_HOST} \
    --realm=${_REALM} \
    --domain=${_DOMAIN} \
    --site=${_HOST} \
    --server-role=dc \
    --dns-backend=SAMBA_INTERNAL \
    --adminpass="${_PASSWORD}" \
    --option="vfs objects = dfs_samba4 acl_xattr xattr_tdb" \
    --option="acl allow execute always = yes"

  if [[ $? == 0 ]] ; then
    install -vm 0640 /var/lib/samba/private/krb5.conf /etc/krb5.conf

    if test -e /etc/samba/smb.conf ; then
      _dfsnamespace=$(hostname -f)
      mkdir -p /var/lib/samba/${_dfsnamespace}
      chown root:sambashare /var/lib/samba/${_dfsnamespace}
      chmod 0775 /var/lib/samba/${_dfsnamespace}

    cat >> /etc/samba/smb.conf <<EOF

## dfsutil target add \\\\${_dfsnamespace}\dfs
[dfs]
  msdfs root = Yes
  path = /var/lib/samba/${_dfsnamespace}
  valid users = +"${_DOMAIN}\Domain Users"
  read only = No

EOF
    fi

    testparm /etc/samba/smb.conf
  fi
fi

if test -r /etc/samba/smb.conf ; then
  samba --show-build

  samba -D --debuglevel=${_DEBUGLEVEL}
fi

cat <<EOF

  Debuglevel      ${_DEBUGLEVEL}
  Hostname        ${_HOST}
  DNS Domain      ${_DOMAIN}
  Kerberos REALM  ${_REALM}
  DNS Forwarder   ${ADS_FORWARDER}
  PASSWORD        ${_PASSWORD}

  Debugging options:
    ps axf | egrep "samba|smbd|winbindd"
    ss -tlpn | grep "samba"
    cat /var/lib/samba/private/krb5.conf
    klist -k /var/lib/samba/private/secrets.keytab

  [old-tools]
    smbclient -L localhost -N
    smbcontrol -t2 all onlinestatus

  [net]
    net lookup name ${_DOMAIN}
    net lookup master
    net lookup <joined-host-admember>.${_DOMAIN}
    net status sessions
    net time -S localhost
    net usersidlist

  [samba-tool]
    samba-tool dbcheck --cross-ncs
    samba-tool gpo listall
    samba-tool schema objectclass show classSchema

EOF

echo "Open subshell:"
/bin/bash

##EOF

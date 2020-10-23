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

_DEBUGLEVEL="${AD_DEBUGLEVEL:-"3"}"
echo "-- Debuglevel:${_DEBUGLEVEL}"

_HOSTNAME="$(hostname -s)"
echo "-- Hostname:${_HOSTNAME}"

_DOMAIN="$(hostname -f)"
echo "-- DNS Domain and Workgroup:${_DOMAIN}"

_PASSWORD="${AD_PASSWORD:-"P@55word"}"
if test -n "${_PASSWORD}" ; then
  echo "-- AD Password set"
else
  echo "-- WARNING - AD Password not set"
fi

##  | sed 's/\./ /'
_KRBREALM="$( echo $(hostname -d) | awk '{print $NF}' )"
echo "-- Kerberos REALM:${_KRBREALM}"

#############################################################################

if test -r /etc/samba/smb.conf ; then
  echo "Start - Active Directory Controller"
  /usr/sbin/samba --interactive --debuglevel=${_DEBUGLEVEL} --debug-stderr
else
  # make conflict with domain provisioning
  rm -f /etc/krb5.conf

  samba-tool domain provision \
    --use-rfc2307 \
    --domain=${_DOMAIN} \
    --realm=${_KRBREALM} \
    --site=${_HOSTNAME} \
    --server-role=dc \
    --dns-backend=SAMBA_INTERNAL \
    --adminpass="${_PASSWORD}"

  if [[ $? == 0 ]] ; then
    install -vm 0600 /var/lib/samba/private/krb5.conf /etc/krb5.conf
    testparm /etc/samba/smb.conf
  fi

  if test -r /etc/samba/smb.conf ; then
    echo "Init - Active Directory Controller"
    /usr/sbin/samba --interactive --debuglevel=5 --debug-stderr
  fi
fi

##EOF

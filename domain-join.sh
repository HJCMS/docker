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

test -e ads-config.cfg || {
  echo "FATAL: ads-config.cfg not exists"
  exit 1
}
source ads-config.cfg

if test ! -n "${ADS_PASSWORD}" ; then
read -p "Domain Join Password:"
ADS_PASSWORD="$REPLY"
fi

cat <<EOF

  -- AD Hostname:${ADS_HOSTNAME}
  -- AD DNS Domain:${ADS_DOMAIN}
  -- Kerberos REALM:${ADS_REALM}
  -- Password:${ADS_PASSWORD}

EOF

if test -x "$(which smbclient 2> /dev/null)" ; then
  smbclient -L ${ADS_HOSTNAME} -N
fi

if test -x "$(which dig 2> /dev/null)" ; then
  dig -4 -t SRV _ldap._tcp.${ADS_DOMAIN} +nocomments
fi

if test -x "$(which realm 2> /dev/null)" ; then

  realm discover ${ADS_DOMAIN}

  cat <<EOF

  if no error response, you can run realm to join the domain
    adcli info ${ADS_DOMAIN}
    realm join --help
    realm join -v -U Administrator ${ADS_DOMAIN}

EOF
else
  echo "missing adcli application"
fi

##EOF

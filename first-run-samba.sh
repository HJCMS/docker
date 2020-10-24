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
set -o errexit

## Hostname (FQDN)
declare AD_HOSTNAME="${1:-"ad.smb.virt"}"

## Samba AD/Administrator Password
declare AD_PASSWORD="${2:-"P@55word"}"

## Samba Debug Level 0-5
declare i AD_DEBUGLEVEL="3"

if [[ $# == 0 ]] ; then
cat <<EOF

  WARNING
    Using default script settings!
    if you want to change this, use:
      ./$(basename $0) "Fully Qualified Domain Name (FQDN)" "password"

  Using Script Defaults:
    AD_PASSWORD=${AD_PASSWORD}
    AD_HOSTNAME=${AD_HOSTNAME}

EOF
fi

#############################################################################

cat Makefile | \
  sed 's/[ \t]\+//g' | \
  grep '^\<\(PROJECTTARGET\|PACKAGENAME\)\+\>' > run.env

source run.env

#############################################################################

rm -f docker-ad-run.log

docker run --privileged -it \
  -h "${AD_HOSTNAME}" \
  -e "AD_DEBUGLEVEL=${AD_DEBUGLEVEL}" \
  -e "AD_PASSWORD=${AD_PASSWORD}" \
  ${PROJECTTARGET}_${PACKAGENAME} | tee docker-ad-run.log

rm -vf run.env

##EOF

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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this library; see the file COPYING.LIB. If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.
#############################################################################
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

$_domain="docknet.virt"
$_ipaddr="172.19.0.9"
$_site="ad"
$_fqdn="ad.$_domain"

Write-Host "Ping to $_fqdn"
Test-Connection -TargetName $_fqdn -IPv4 -Traceroute

Write-Host "Check SRV Record for join (_ldap._tcp.dc._msdcs.$_domain)"
Resolve-DnsName -Type SRV -Name _ldap._tcp.dc._msdcs.$_domain

if ( Test-Connection -TargetName $_fqdn -IPv4 -Count 3 -Quiet )
{
  Write-Host "Start Domain Join"
  Add-Computer -computername $env:HOSTNAME -domainname $_domain -credential $_domain\Administrator -restart -force
}

##EOF

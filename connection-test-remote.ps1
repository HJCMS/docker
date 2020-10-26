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

$_nsh="smb.virt"
$_nip="172.17.0.2"
$_site="ad"
$_fqdn="ad.$_nsh"

Write-Host -ForegroundColor Green " -- ANY ${_host}"
Resolve-DnsName -Type ANY -Name $_fqdn -Server $_nip

Write-Host -ForegroundColor Green "RFC1510 KDC SRV (_kerberos._tcp.$_nsh)"
Resolve-DnsName -Type SRV -Name _kerberos._tcp.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "RFC1510 UDP-KDC SRV (_kerberos._udp.$_nsh)"
Resolve-DnsName -Type SRV -Name _kerberos._udp.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "KDC SRV (_kerberos._tcp.dc._msdcs.$_nsh)"
Resolve-DnsName -Type SRV -Name _kerberos._tcp.dc._msdcs.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "RFC1510 KDC@Site SRV (_kerberos._tcp.$_site._sites.$_nsh)"
Resolve-DnsName -Type SRV -Name _kerberos._tcp.$_site._sites.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "LDAP SRV (_ldap._tcp.$_nsh)"
Resolve-DnsName -Type SRV -Name _ldap._tcp.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "LDAP PDC SRV (_ldap._tcp.pdc._msdcs.$_nsh)"
Resolve-DnsName -Type SRV -Name _ldap._tcp.pdc._msdcs.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "LDAP GC SRV (_ldap._tcp.gc._msdcs.$_nsh)"
Resolve-DnsName -Type SRV -Name _ldap._tcp.gc._msdcs.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "LDAP DC SRV (_ldap._tcp.dc._msdcs.$_nsh)"
Resolve-DnsName -Type SRV -Name _ldap._tcp.dc._msdcs.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "LDAP @Site SRV (_ldap._tcp.$_site._sites.$_nsh)"
Resolve-DnsName -Type SRV -Name _ldap._tcp.$_site._sites.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "LDAP GC@Site SRV (_ldap._tcp.$_site._sites.gc._msdcs.$_nsh)"
Resolve-DnsName -Type SRV -Name _ldap._tcp.$_site._sites.gc._msdcs.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "LDAP Dc@Site SRV (_ldap._tcp.$_site._sites.dc._msdcs.$_nsh)"
Resolve-DnsName -Type SRV -Name _ldap._tcp.$_site._sites.dc._msdcs.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "RFC1510 KPWD SRV (_kpasswd._tcp.$_nsh)"
Resolve-DnsName -Type SRV -Name _kpasswd._tcp.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "RFC1510 UDP-KPWD SRV (_kpasswd._udp.$_nsh)"
Resolve-DnsName -Type SRV -Name _kpasswd._udp.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "Generic GC SRV (_gc._tcp.$_nsh)"
Resolve-DnsName -Type SRV -Name _gc._tcp.$_nsh -Server $_nip

Write-Host -ForegroundColor Green "Generic GC@Site SRV (_gc._tcp.$_site._sites.$_nsh)"
Resolve-DnsName -Type SRV -Name _gc._tcp.$_site._sites.$_nsh -Server $_nip

##EOF

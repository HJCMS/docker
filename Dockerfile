#!/usr/bin/env docker
# -*- coding: utf-8 -*-
# vim: set fileencoding=utf-8
#################################################################
FROM debian:buster
MAINTAINER HJCMS https://www.hjcms.de

## add entrypoint sources, see below
ADD domain-provision.sh /usr/local/bin/domain-provision.sh
RUN chmod +x /usr/local/bin/domain-provision.sh

## default arguments for the start-up instructions
ENTRYPOINT /usr/local/bin/domain-provision.sh

#################################################################
## add essential ports for better manage iptables later
## NOTE see my testscript test-ad-connection.sh in this project
## DNS
EXPOSE 53:53/tcp
EXPOSE 53:53/udp
## Kerberos
EXPOSE 88:88/tcp
EXPOSE 88:88/udp
## DCE/RPC Locator Service
EXPOSE 135:135/tcp
## Network Session Browsing
EXPOSE 139:139/tcp
## LDAP
EXPOSE 389:389/tcp
EXPOSE 389:389/udp
## SMB over TCP
EXPOSE 445:445/tcp
## Kerberos kpasswd
EXPOSE 464:464/tcp
EXPOSE 464:464/udp
## LDAPS
EXPOSE 636:636/tcp
## Global Catalog
EXPOSE 3268:3268/tcp
## Global Catalog (SSL)
EXPOSE 3269:3269/tcp

#################################################################
## Suppress Debian’s configuration engine
ENV DEBIAN_FRONTEND noninteractive

## what else ;-)
RUN apt-get update && apt-get upgrade -y

## Installing Essential Packages
RUN apt-get install -y attr acl krb5-user

## Installing Samba Packages
RUN apt-get install -y smbclient samba-common-bin samba winbind

## WARNING it is important to delete this file,
## otherwise the domain-provisioning process
## and the start script not work correctly.
RUN rm -f /etc/samba/smb.conf

## finally check if samba binary exists
RUN getfacl /usr/sbin/samba

## EOF

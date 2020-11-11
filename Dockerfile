#!/usr/bin/env docker
# -*- coding: utf-8 -*-
# vim: set fileencoding=utf-8
#################################################################
FROM debian:buster
MAINTAINER HJCMS https://www.hjcms.de

ENV AD_DEBUGLEVEL=3
## add entrypoint sources, see below
ADD domain-provision.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

## default arguments for the start-up instructions
ENTRYPOINT docker-entrypoint

EXPOSE "53:53/tcp"
EXPOSE "53:53/udp"

#################################################################
## Suppress Debian’s configuration engine
ENV DEBIAN_FRONTEND=noninteractive

## what else ;-)
RUN apt-get update && apt-get upgrade -y

## Installing Essential Packages
RUN apt-get install -y attr acl krb5-user less vim dnsutils

## Installing Samba Packages
RUN apt-get install -y smbclient libpam-winbind \
  libnss-winbind samba-common-bin samba winbind

RUN perl -pi -e 's/^passwd:.+$/passwd:\t\tfiles winbind/g' /etc/nsswitch.conf
RUN perl -pi -e 's/^group:.+$/passwd:\t\tfiles winbind/g' /etc/nsswitch.conf

## WARNING it is important to delete this file,
## otherwise the domain-provisioning process
## and the start script not work correctly.
RUN rm -f /etc/samba/smb.conf

## finally check if samba binary exists
RUN getfacl /usr/sbin/samba

## Show Samba Build
RUN samba --show-build

## Required for Volume
RUN mv /var/lib/samba  /var/lib/samba.core

## Cleanup
RUN apt-get clean

## EOF

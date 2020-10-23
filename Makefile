# -*- coding: utf-8 -*-
# vim: set fileencoding=utf-8
# vim: set t_Co=256
PROJECTTARGET 	= smb
PACKAGENAME 	= ad-controller
REPO		= $(PROJECTTARGET)_$(PACKAGENAME)
TAG		= latest
HOSTNAME	= samba.virt
REMOVE		= rm -vf
INIT_SCRIPT	= /usr/local/bin/domain-provision.sh
DOCKER		= docker
DOCKER_COMPOSE	= docker-compose

help:
	@echo
	@echo "USAGE: make {check,build,inspect}"
	@echo " check	# check the YAML configuration file"
	@echo " build	# building this docker project"
	@echo " inspect # show image information"
	@echo

check:
	$(DOCKER_COMPOSE) config

clean:
	$(REMOVE) *~ .gitignore~

build:
	$(DOCKER_COMPOSE) --project-name $(PROJECTTARGET) \
		--file docker-compose.yml build

run:
	$(DOCKER) run -it -h $(HOSTNAME) --privileged $(REPO):$(TAG)

inspect:
	$(DOCKER) inspect $(REPO):$(TAG)

# -*- coding: utf-8 -*-
# vim: set fileencoding=utf-8
# vim: set t_Co=256
PROJECTTARGET 	= smb
PACKAGENAME 	= ad-dc
REPO		= $(PROJECTTARGET)_$(PACKAGENAME)
TAG		= latest
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
	@rm -vf *~ .gitignore~ *.log

build:
	$(DOCKER_COMPOSE) \
		--project-name $(PROJECTTARGET) \
		--file docker-compose.yml build --force-rm

inspect:
	$(DOCKER) inspect $(REPO):$(TAG)

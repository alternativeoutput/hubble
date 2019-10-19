# virtualenv

PROJ = hubble
PROJ_UP = $(shell echo $(PROJ) | tr '[:lower:]' '[:upper:]')
PROD_ENV = AO_HUB_$(PROJ_UP)_VENV

ALL: build

# default values
AO_HUB_WRK_DIR ?= /var/lib/$(PROJ)
export AO_HUB_WRK_DIR
AO_HUB_VIRTUAL_ENV ?= env
export AO_HUB_VIRTUAL_ENV
AO_HUB_ALLOWED_HOSTS ?= *
export AO_HUB_ALLOWED_HOSTS
# secret key could include dollar char, the only way to manage it
# from environment correctly is export and use with $$ prefix
AO_HUB_DJANGO_SECRET_KEY ?= to_be_set
export AO_HUB_DJANGO_SECRET_KEY
AO_HUB_STATIC_ROOT ?= /static/
export AO_HUB_STATIC_ROOT
AO_HUB_WEB_USER ?= www-data
export AO_HUB_WEB_USER
AO_HUB_WEB_GROUP ?= www-data
export AO_HUB_WEB_GROUP

define populate_tmpl =
export secr=$$(echo "$$AO_HUB_DJANGO_SECRET_KEY" | sed 's/\&/\\&/g'); \
sed 's@#PROJ#@$(PROJ)@g;s@#WRK_DIR#@$(AO_HUB_WRK_DIR)@g;\
s@#VIRTUAL_ENV#@$(AO_HUB_VIRTUAL_ENV)@g;\
s/#ALLOWED_HOSTS#/$(AO_HUB_ALLOWED_HOSTS)/g;'"\
s/#DJANGO_SECRET_KEY#/$$secr/g;"'\
s@#STATIC_ROOT#@$(AO_HUB_STATIC_ROOT)@g;\
s/#WEB_USER#/$(AO_HUB_WEB_USER)/g;\
s/#WEB_GROUP#/$(AO_HUB_WEB_GROUP)/g;' <$(1) >$(2)
endef

define USAGE =

Usage:
    make help                   - this help
    make secret                 - dump a valid DJANGO_SECRET_KEY
    make env                    - create string to source dev virtual environment
    make create_dev             - create devel framework
    make destroy_dev            - destroy devel framework
    make reinstall              - reinstall production after creation
    sudo -E make [VARS] create  - create a production installation
    sudo -E make [VARS] destroy - destroy production installation
    the following arguments are managed:

    AO_HUB_WRK_DIR              - working dir of production installation
        current: "$(AO_HUB_WRK_DIR)"
    AO_HUB_VIRTUAL_ENV          - name of virtual environment
        current: "$(AO_HUB_VIRTUAL_ENV)"
    AO_HUB_ALLOWED_HOSTS        - csv strings list of public hostnames
                               allowed by django
        current: [$(AO_HUB_ALLOWED_HOSTS)]
    AO_HUB_DJANGO_SECRET_KEY    - django secret key
        current: "$(AO_HUB_DJANGO_SECRET_KEY)"
    AO_HUB_STATIC_ROOT          - static root folder
        current: $(AO_HUB_STATIC_ROOT)
    AO_HUB_WEB_USER             - user running daemons
	current: $(AO_HUB_WEB_USER)
    AO_HUB_WEB_GROUP            - group of user running daemons
        current: $(AO_HUB_WEB_GROUP)

endef

export USAGE

help: WRK_DIR VIRTUAL_ENV
	@echo "$$USAGE"

timestamps_dev/virtualenv.tstamp:
	virtualenv -p /usr/bin/python3.6 ./$(PROJ)-venv
	. '$(PROJ)-venv/bin/activate' \
	&& pip install --upgrade pip
	touch $@

virtualenv_dev: timestamps_dev/virtualenv.tstamp

check_venv_var:
	@if [ "$($(PROD_ENV))" = "" ]; then echo "$(PROD_ENV) env variable not set" ; exit 1 ; fi

migrate_dev: timestamps_dev/migrate.tstamp
	. '$(PROJ)-venv/bin/activate' \
	&& python manage.py migrate \
	&& python manage.py loaddata fixtures/auth_user.json

install_dev_reqs:
	. ./$(PROJ)-venv/bin/activate && pip install -r requirements_dev.txt

install_reqs: check_venv_var
	. $($(PROD_ENV))/bin/activate && pip install -r requirements_prod.txt


#
# MAIN TARGETS
#

%_dev: AO_HUB_WRK_DIR = .
create_dev: virtualenv_dev install_dev_reqs
	. $(PROJ)-venv/bin/activate \
	&& python manage.py migrate \
	&& python manage.py loaddata hubble/fixtures/auth_user.json

recreate_dev: destroy_dev create_dev

clean_dev:
	rm -rf ./dist

destroy_dev: clean_dev
	@deactivate >/dev/null 2>&1 || true
	rm -f db.sqlite3
	rm -rf ./$(PROJ)-venv
	rm -rf ./node_modules
	rm -f timestamps_dev/[a-z]*

env:
	@echo ". ./$(PROJ)-venv/bin/activate"

#
secret:
	@python -c 'import random; print("".join([random.choice("abcdefghijklmnopqrstuvwxyz0123456789!@#$$%^&*(-_=+)") for i in range(50)]))'

#
#  PRODUCTION
#
timestamps/virtualenv.tstamp:
	test -d "$(AO_HUB_WRK_DIR)" || mkdir -p "$(AO_HUB_WRK_DIR)"
	chown $(AO_HUB_WEB_USER).$(AO_HUB_WEB_GROUP) "$(AO_HUB_WRK_DIR)"
	virtualenv -p /usr/bin/python3.6 $(AO_HUB_WRK_DIR)/$(AO_HUB_VIRTUAL_ENV)
	. '$(AO_HUB_WRK_DIR)/$(AO_HUB_VIRTUAL_ENV)/bin/activate' \
	&& pip install --upgrade pip
	touch $@

virtualenv: timestamps/virtualenv.tstamp

timestamps/install.tstamp:
	. $(AO_HUB_WRK_DIR)/$(AO_HUB_VIRTUAL_ENV)/bin/activate && \
	pip install .
	touch $@

install: timestamps/install.tstamp

uninstall:
	sudo bash -c "source $(AO_HUB_WRK_DIR)/$(AO_HUB_VIRTUAL_ENV)/bin/activate && \
	pip uninstall -y $(PROJ)"
	rm -f timestamps/install.tstamp

reinstall: uninstall install

# MAIN TARGET

timestamps/migrate.tstamp:
	sudo -u $(AO_HUB_WEB_USER) bash -c "source $(AO_HUB_WRK_DIR)/$(AO_HUB_VIRTUAL_ENV)/bin/activate \
	&& hubble_manage migrate \
	&& hubble_manage loaddata fixtures/auth_user.json"
	touch $@

migrate: timestamps/migrate.tstamp

timestamps/daemons_create.tstamp:
	test -d /etc/systemd/system
	$(call populate_tmpl,rootfs/etc/systemd/system/django-channels-daphne.service,/etc/systemd/system/django-channels-daphne.service)
	$(call populate_tmpl,rootfs/etc/systemd/system/django-channels-runworker.service,/etc/systemd/system/django-channels-runworker.service)
	sudo -u $(AO_HUB_WEB_USER) bash -c "export AO_HUB_WRK_DIR=$(AO_HUB_WRK_DIR) ;  source /var/lib/$(PROJ)/env/bin/activate ; hubble_manage migrate"
	systemctl daemon-reload
	systemctl enable django-channels-runworker.service
	systemctl restart django-channels-runworker.service
	systemctl enable django-channels-daphne.service
	systemctl restart django-channels-daphne.service
	touch $@

daemons_create: timestamps/daemons_create.tstamp

config_create:
	mkdir -p $(AO_HUB_WRK_DIR)/config
	./helpers/config-gen.py > $(AO_HUB_WRK_DIR)/config/$(PROJ).yaml

daemons_destroy:
	systemctl stop django-channels-runworker.service
	systemctl disable django-channels-runworker.service
	systemctl stop django-channels-daphne.service
	systemctl disable django-channels-daphne.service
	rm -f timestamps/daemons_create.tstamp

create: virtualenv install config_create daemons_create
	echo "Finished"

timestamps/populate.tstamp:
	@sudo -u $(AO_HUB_WEB_USER) bash -c "export AO_HUB_WRK_DIR=$(AO_HUB_WRK_DIR) ;  source /var/lib/$(PROJ)/env/bin/activate ; $(PROJ)_manage loaddata ./$(PROJ)/fixtures/auth_user.json"
	touch $@

populate: timestamps/populate.tstamp

destroy: daemons_destroy
	@echo "Remove: $(AO_HUB_WRK_DIR) ? ([Enter] to continue, [CTRL+C] to abort)"
	@read resp
	@rm -rf $(AO_HUB_WRK_DIR)
	@rm -f timestamps/[a-z]*

# build:
# 	. ./$(PROJ)-venv/bin/activate && yarn build

# start:
# 	. ./$(PROJ)-venv/bin/activate && yarn start

# check:
# 	. ./$(PROJ)-venv/bin/activate && python --version

.PHONY: install_dev_reqs clean_dev destroy_dev virtualenv_dev install_reqs create recreate create_dev recreate_dev env WRK_DIR VIRTUAL_ENV

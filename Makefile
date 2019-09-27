# virtualenv

PROJ = hubble
PROJ_UP = $(shell echo $(PROJ) | tr '[:lower:]' '[:upper:]')
PROD_ENV = $(PROJ_UP)_PROD_VENV

ALL: build

timestamps/virtualenv_dev.tstamp:
	virtualenv -p /usr/bin/python3.6 ./$(PROJ)-venv
	. '$(PROJ)-venv/bin/activate' \
	&& pip install --upgrade pip
	touch $@

virtualenv_dev: timestamps/virtualenv_dev.tstamp

timestamps/virtualenv.tstamp: check_venv_var
	virtualenv -p /usr/bin/python3.6 $($(PROD_ENV))
	. '$($(PROD_ENV))' \
	&& pip install --upgrade pip
	touch $@

virtualenv: timestamps/virtualenv.tstamp

check_venv_var:
	@if [ "$($(PROD_ENV))" = "" ]; then echo "$(PROD_ENV) env variable not set" ; exit 1 ; fi

migrate_dev: timestamps/migrate_dev.tstamp
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

create: check_venv_var virtualenv install_reqs
#	. $($(PROD_ENV))/bin/activate \


create_dev: virtualenv_dev install_dev_reqs
	. $(PROJ)-venv/bin/activate \
	&& python manage.py migrate \
	&& python manage.py loaddata fixtures/auth_user.json

recreate_dev: destroy_dev create_dev

clean_dev:
	rm -rf ./dist

destroy_dev: clean_dev
	@deactivate >/dev/null 2>&1 || true
	rm -f db.sqlite3
	rm -rf ./$(PROJ)-venv
	rm -rf ./node_modules
	rm -f timestamps/[a-z]*

env:
	@echo ". ./$(PROJ)-venv/bin/activate"

# build:
# 	. ./$(PROJ)-venv/bin/activate && yarn build

# start:
# 	. ./$(PROJ)-venv/bin/activate && yarn start

# check:
# 	. ./$(PROJ)-venv/bin/activate && python --version

.PHONY: install_dev_reqs clean_dev destroy_dev virtualenv_dev install_reqs create recreate create_dev recreate_dev env

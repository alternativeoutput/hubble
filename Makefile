# virtualenv

PROJ = hubble

ALL: build

timestamps/virtualenv.tstamp:
	virtualenv -p /usr/bin/python3.6 ./$(PROJ)-venv
	touch $@

virtualenv: timestamps/virtualenv.tstamp

migrate: timestamps/migrate.tstamp
	. '$(BASE_ENV)/$(NAME_ENV_DEV)/bin/activate' \
	&& python manage.py migrate \
	&& python manage.py loaddata fixtures/auth_user.json




install_dev_reqs:
	. ./$(PROJ)-venv/bin/activate && pip install -r requirements_dev.txt

#
# MAIN TARGETS
#

create_dev: virtualenv install_dev_reqs
	. ./$(PROJ)-venv/bin/activate \
	&& pip install --upgrade pip \
	&& pip install -r requirements_dev.txt \
	&& python manage.py migrate \
	&& python manage.py loaddata fixtures/auth_user.json

recreate: destroy create

clean:
	rm -rf ./dist

destroy: clean
	@deactivate >/dev/null 2>&1 || true
	rm -rf ./$(PROJ)-venv
	rm -rf ./node_modules
	rm -f timestamps/[a-z]*

env:
	@echo ". ./$(PROJ)-venv/bin/activate"

build:
	. ./$(PROJ)-venv/bin/activate && yarn build

start:
	. ./$(PROJ)-venv/bin/activate && yarn start

check:
	. ./$(PROJ)-venv/bin/activate && python --version

.PHONY: install_reqs clean destroy virtualenv install_dev_reqs node yarn_check create recreate env build start check

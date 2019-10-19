#!/usr/bin/env python
import os
import yaml

config = {}
if os.environ.get('AO_HUB_ALLOWED_HOSTS', None):
    env_s = os.environ['AO_HUB_ALLOWED_HOSTS'].split(',')
    config['ALLOWED_HOSTS'] = [
        x.strip() for x in env_s]


print(yaml.dump(config))

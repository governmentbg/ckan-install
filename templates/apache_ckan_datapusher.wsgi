# extracted from: https://github.com/ckan/datapusher/tree/master/deployment
import os
import sys
import hashlib

activate_this = os.path.join('{{VIRTUALENV_DIR}}/bin/activate_this.py')
execfile(activate_this, dict(__file__=activate_this))

import ckanserviceprovider.web as web
os.environ['JOB_CONFIG'] = '{{CKAN_CONFIG_DIR}}/{{CKAN_INSTANCE_NAME}}_datapusher_settings.py'
web.init()

import datapusher.jobs as jobs

application = web.app

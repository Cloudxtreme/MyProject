# Copyright (C) 2014 VMware, Inc. All rights reserved.
# THIS IS NAMESPACE PACKAGE, DO NOT CHANGE THIS FILE
from pkgutil import extend_path
__path__ = extend_path(__path__, __name__)

import os
import yaml


class Codes(yaml.YAMLObject):
    yaml_tag = u'!Codes'

with open('%s/status_codes.yaml' % os.path.dirname(__file__)) as f:
    status_codes = yaml.load(f.read())

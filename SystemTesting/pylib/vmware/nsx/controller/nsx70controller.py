#!/usr/bin/env python

import vmware.base.controller as controller
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


# Create a derived class as a placeholder for any method implementation
# that cannot be solved by auto_resolve
class Nsx70Controller(controller.Controller):

    def get_impl_version(self, execution_type=None, interface=None):
        return "Nsx70"

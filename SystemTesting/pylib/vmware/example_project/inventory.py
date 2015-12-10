#!/usr/bin/env python

# sort imports in alphabetical order
import vmware.base.example as example
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


# Create a derived class as a placeholder for any method implementation
# that cannot be solved by auto_resolve
class ExampleInventory(example.BaseExample):

    def get_impl_version(self, execution_type=None, interface=None):
        return "Version10"

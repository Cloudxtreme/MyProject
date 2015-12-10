#!/usr/bin/env python

import vmware.base.controller as controller
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class Controller(controller.Controller):
    DEFAULT_IMPLEMENTATION_VERSION = 'NSX70'

    def get_impl_version(self, execution_type=None, interface=None):
        return self.DEFAULT_IMPLEMENTATION_VERSION

    def get_ip(self):
        if not self.ip:
            pylogger.warning("No controller IP set, returning %r" % self.ip)
        return self.ip

    def read_ip(self, **kwargs):
        if not self.ip:
            pylogger.warning("No controller IP set, returning %r" % self.ip)
        result_dict = {'ip': self.ip}
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = 200
        return result_dict

    def get_version(self):
        # TODO(prashants) : Hardcoded string "7.0.0.0.0" need to be changed
        # based on release version
        if "-" in self.build:
            version = "7.0.0.0.0." + self.build.split("-")[1]
        else:
            version = self.build
        return version
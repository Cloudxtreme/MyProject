#!/usr/bin/env python
import vmware.base.verification as verification
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config

auto_resolve = base_facade.auto_resolve
pylogger = global_config.pylogger


class Verification(verification.Verification):

    def get_impl_version(self, execution_type=None, interface=None):
        return "Default"

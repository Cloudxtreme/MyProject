import vmware.base.nsx as nsx
import vmware.common.versions as versions
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class Manager(nsx.NSX):
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def get_manager_ip(self):
        return self.ip

    def get_version(self):
        # TODO(prashants) : Hardcoded string "7.0.0.0.0" need to be changed
        # based on release version
        if "-" in self.build:
            version = "7.0.0.0.0." + self.build.split("-")[1]
        else:
            version = self.build
        return version

    def read_ip(self, **kwargs):
        if not self.ip:
            pylogger.warning("No manager IP set, returning %r" % self.ip)
        result_dict = {'ip': self.ip}
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = 200
        return result_dict

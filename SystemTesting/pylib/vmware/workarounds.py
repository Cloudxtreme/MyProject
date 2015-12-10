import vmware.common.global_config as global_config

# Master switch to disallow workarounds.
ALLOW_WORKAROUNDS = True  # see __init__ in parent class.
pylogger = global_config.pylogger


class Workaround(object):

    def __init__(self, desc, bug_id=None, enabled=False, autowarn=False):
        self.desc = desc
        self.bug_id = bug_id
        self._enabled = enabled
        self.autowarn = autowarn

    @property
    def enabled(self):
        if self.autowarn:
            self.warn()
        return self._enabled and ALLOW_WORKAROUNDS

    def warn(self):
        pylogger.debug("\n%s\n%s\n%s\n" % ("*" * 24, self.__str__(), "*" * 24))

    def __str__(self):
        if self._enabled:
            if not ALLOW_WORKAROUNDS:
                enabled_str = "Disallowed"
            else:
                enabled_str = "Enabled"
        else:
            enabled_str = "Disabled"
        return ('<Workaround [%s] Bug#: %d "%s">' %
                (enabled_str, self.bug_id, self.desc))


# NSX Transformers Workarounds
nsxa_installation_workaround = Workaround(
    "Background nsxa installation as stderr is not closed",
    bug_id=1361292, enabled=False, autowarn=True)

edgecluster_api_workaround = Workaround(
    "Delay to wait after edge cluster api is called",
    bug_id=1396015, enabled=True, autowarn=True)

debug_logs_workaround = Workaround(
    "Enable debug logging for the components",
    bug_id=1407030, enabled=True, autowarn=True)

nsx_manager_revoke_api_workaround = Workaround(
    "Determine hosts required for revoke",
    bug_id=1423136, enabled=True, autowarn=True)

kvm_vm_power_on_retry_workaround = Workaround(
    "Retry poweron on kvm vm related failures",
    bug_id=1394571, enabled=True, autowarn=True)

nsxcontroller_activate_cluster_workaround = Workaround(
    "Sleep before activating control cluster",
    bug_id=1452513, enabled=True, autowarn=True)

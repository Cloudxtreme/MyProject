import re

import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.kvm.cmd.default_package_impl as default_package_impl
import vmware.linux.linux_helper as linux_helper

pylogger = global_config.configure_logger()
Linux = linux_helper.Linux


class RHEL64PackageImpl(default_package_impl.DefaultPackageImpl):
    """Package management class for RHEL."""
    INSTALL_OPTION = '-Uvh --force'
    PKG_MGR = "rpm"
    RPM_KMOD_OPENVSWITCH = constants.NSXPackages.RPM_KMOD_OPENVSWITCH
    PACKAGE_TYPE = '*.rpm'
    NETWORK_RESTART_CMD = "/etc/init.d/network restart"
    OPENVSWITCH_SERVICE = 'openvswitch'

    @classmethod
    def _find_pkgs(cls, client_object, resource=None):
        """
        Helper for finding packages on the host.

        @type resource: list
        @param resource: List of name(s)/regex of packages to find.
        @rtype: list
        @return: List of matching packages.
        """
        utilities.validate_list(resource)
        get_pkgs_cmd = "%s -qa" % cls.PKG_MGR
        rpm_out = client_object.connection.request(
            get_pkgs_cmd).response_data.strip().split('\n')
        pkgs_re = "(%s)" % "|".join(resource)
        matching_pkgs = []
        for pkg in rpm_out:
            if re.match(pkgs_re, pkg):
                matching_pkgs.append(pkg)
        pylogger.debug('Found installed packages: %r, corresponding to input '
                       '%r' % (matching_pkgs, resource))
        return matching_pkgs

    @classmethod
    def uninstall(cls, client_object, resource=None, timeout=None,
                  ordered=None):
        """
        Removes the packages.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type resource: list
        @param resource: List of package names to uninstall.
        @type timeout: int
        @param timeout: Time after which the attempt to uninstall packages is
            aborted.
        @type ordered: str
        @param ordered: When True, the packages are uninstalled in order as
            specified in the list.
        @rtype: NoneType
        @return: None
        """
        _ = ordered  # TODO(salmanm): Use this.
        matching_pkgs = cls._find_pkgs(client_object, resource=resource)
        uninstall_cmd = ('%s -ev %s' % (cls.PKG_MGR, ' '.join(matching_pkgs)))
        client_object.connection.request(uninstall_cmd, timeout=timeout)

    @classmethod
    def are_installed(cls, client_object, packages=None):
        """
        Determines if the package(s) are installed on the system.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type packages: list
        @param packages: List of package names to query.
        @rtype: dict
        @return: Map from the package name to a tuple of (bool status of
            installed or not installed, package version)
        """
        matching_pkgs = cls._find_pkgs(client_object, resource=packages)
        ret = {}
        pkg_query_cmd = [cls.PKG_MGR]
        pkg_query_cmd.append(r"-qi --queryformat='%{Name},%{Version}\n'")
        pkg_query_cmd = ' '.join(pkg_query_cmd)
        for matching_pkg in matching_pkgs:
            rpm_out = (client_object.connection.request('%s %s' %
                       (pkg_query_cmd,
                        matching_pkg)).response_data.strip().split('\n'))
            # Name and version will be the last line in stdout.
            name, version = rpm_out[-1].split(',')
            ret[name] = (True, version)
        return ret

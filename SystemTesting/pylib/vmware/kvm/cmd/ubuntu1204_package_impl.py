import re

import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.kvm.cmd.default_package_impl as default_package_impl

pylogger = global_config.configure_logger()


class Ubuntu1204PackageImpl(default_package_impl.DefaultPackageImpl):
    """Package management class for Ubuntu."""
    APT_FORCE_STR = '-o Dpkg::Options::="--force-confnew" --yes --force-yes'
    INSTALL_OPTION = '-i'
    PKG_MGR = "dpkg"
    PACKAGE_TYPE = '*.deb'
    RPM_KMOD_OPENVSWITCH = 'openvswitch'
    OPENVSWITCH_SERVICE = 'openvswitch-switch'
    WGET = "wget"
    NETWORK_RESTART_CMD = ("ifdown $(ifquery --list -X lo | xargs echo) && "
                           "ifup $(ifquery --list -X lo | xargs echo)")

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
        ret = {}
        flags_map = {
            'Desired': {
                'u': 'Unknown',
                'i': 'Install',
                'r': 'Remove/Deinstall',
                'p': 'Purge',
                'h': 'Hold'},
            'Current': {
                'n': 'Not-installed',
                'i': 'Installed',
                'c': 'Only config Files are Installed',
                'u': 'Unpacked',
                'f': 'Configuration Failed (Half-Configured)',
                'h': 'Installlation Failed (Half-Installed)',
                'w': 'Packages is watiing for a trigger from another package.',
                't': 'Package has been triggered'},
            'Error': {'r': 'Package is broken, re-install required'}
        }
        flags_ind_map = dict(zip(xrange(3), flags_map))
        utilities.validate_list(packages)
        pkg_list_cmd = "%s -l" % cls.PKG_MGR
        dpkg_out = client_object.connection.request(
            pkg_list_cmd).response_data.strip().split('\n')
        pkgs_re = "(%s)" % "|".join(packages)
        for pkg_info in dpkg_out[5:]:  # Skip the header
            flags, pkg_name, version = pkg_info.split()[:3]
            if re.match(pkgs_re, pkg_name):
                # Inspect Flags and inform user.
                for index, flag in enumerate(flags):
                    state = flags_ind_map[index]
                    pylogger.debug("%r state for the package %r: %r" %
                                   (pkg_name, state, flags_map[state]))
                if flags.startswith('ii'):
                    ret[pkg_name] = (True, version)
                else:
                    ret[pkg_name] = (False, None)
        return ret

    @classmethod
    def uninstall(cls, client_object, resource=None):
        """
        Removes the packages.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type resource: list
        @param resource: List of package names to uninstall.
        @rtype: NoneType
        @return: None
        """
        utilities.validate_list(resource)
        remove_cmd = "%s -r %s" % (cls.PKG_MGR, ' '.join(resource))
        client_object.connection.request(remove_cmd)

    @classmethod
    def update(cls, client_object, resource=None, install_from_repo=None):
        """
        Upgrades the packages if they are already installed, otherwise installs
        a fresh copy of the packages.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type resource: list
        @param resource: List of package names to update.
        @type install_from_repo: boolean
        @param install_from_repo: Flag to decide if the packages need to be
            updated from a repository. If install_from_repo is set to True,
            it will try to update the packages using apt-get update. If
            install_from_repo is not set, it will try to upgrade the packages
            using dpkg.
        @rtype: NoneType
        @return: None
        """
        if bool(install_from_repo):
            return cls.apt_cmd(client_object, 'update', resource=resource)
        utilities.validate_list(resource)
        update_cmd = '%s -i %s' % (cls.PKG_MGR, ' '.join(resource))
        client_object.connection.request(update_cmd)

    @classmethod
    def apt_cmd(cls, client_object, op, resource=None, opts=None, force=None):
        """
        apt-get command for package configuration from a repository.
        """
        if force is None:
            force = True
        force_str = force and (" %s" % cls.APT_FORCE_STR) or ''
        pkgs_str = resource and (" %s" % ' '.join(resource)) or ''
        opts_str = opts and " %s" % opts or ''
        cmd = 'apt-get %s%s%s%s' % (op, opts_str, pkgs_str, force_str)
        return client_object.connection.request(cmd)

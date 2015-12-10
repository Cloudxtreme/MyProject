import os
import re

import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.package_interface as package_interface
import vmware.linux.linux_helper as linux_helper

pylogger = global_config.configure_logger()


class Ubuntu1204PackageImpl(package_interface.PackageInterface):
    """Package management class for Ubuntu."""
    PKG_MGR = "dpkg"
    WGET = "wget"
    APT_FORCE_STR = '-o Dpkg::Options::="--force-confnew" --yes --force-yes'

    @classmethod
    def install(cls, client_object, resource=None, install_from_repo=None):
        """
        Fetches the packages in a local directory and then installs them.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type resource: list
        @param resource: List of URLs to packages.
        @type install_from_repo: boolean
        @param install_from_repo: Flag to decide if the packages need to be
            installed from a repository. If install_from_repo is set to True,
            it will try to install the list of resource using apt-get install.
            If install_from_repo is not set, it will try to install the debian
            packages using dpkg.
        @rtype: NonType
        @return: None
        """

        if bool(install_from_repo):
            return cls.apt_cmd(client_object, 'install', resource=resource)
        utilities.validate_list(resource)
        if any([package for package in resource
                if not package.endswith('.deb')]):
            raise ValueError('Can only install *.deb packages, got %r' %
                             resource)
        # Fetch packages.
        package_dir = linux_helper.Linux.wget_files(client_object, resource)
        install_cmd = '%s -i %s' % (cls.PKG_MGR,
                                    os.sep.join([package_dir, "*.deb"]))
        # Install packages.
        client_object.connection.request(install_cmd)

        tmp = 'ENABLE_OVS_VTEP'
        vfile = '/etc/default/openvswitch-vtep'
        enable_cmd = 'sed -i \'s/%s=\\"false\\"/%s=\\"true\\"/g\' %s' % (tmp,
                                                                         tmp,
                                                                         vfile)

        # Enable vtep on machine
        client_object.connection.request(enable_cmd)

        start_vtep_service = '/etc/init.d/openvswitch-vtep start'

        # Start vtep service on machine
        client_object.connection.request(start_vtep_service)

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

    # XXX(Salman): Not a very useful method since we are not unpacking packages
    # and are direcly installing them.
    @classmethod
    def configure_package(cls, client_object, operation=None, resource=None):
        """
        Configures package with the provided operations.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type operation: list
        @param operation: List of flags to congfigure the package.
        @type resource: list
        @param resource: List of package names to configure.
        """
        utilities.validate_list(resource)
        operation_to_method = {'install': cls.install,
                               'uninstall': cls.uninstall}
        if operation not in operation_to_method:
            raise ValueError('Unsupported operation %r provided for '
                             'configuring resources' % operation)
        return operation_to_method[operation](client_object,
                                              resource=resource)

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

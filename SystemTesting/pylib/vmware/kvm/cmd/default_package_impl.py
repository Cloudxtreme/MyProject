import os
import time

import vmware.common as common
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.package_interface as package_interface
import vmware.linux.linux_helper as linux_helper
import vmware.kvm.cmd.default_nsx_impl as default_nsx_impl
import vmware.workarounds as workarounds

pylogger = global_config.configure_logger()
DefaultNSXImpl = default_nsx_impl.DefaultNSXImpl
Linux = linux_helper.Linux


class DefaultPackageImpl(package_interface.PackageInterface):
    """Package management class for Linux."""
    NSXA = constants.NSXPackages.NSXA
    NSX_MPA = constants.NSXPackages.NSX_MPA
    NSX_AGENT = constants.NSXPackages.NSX_AGENT
    OVSDB_TOOL = "ovsdb-tool"
    OVSDB_LOCATION = "/etc/openvswitch/conf.db"
    OVS_L3D = constants.NSXPackages.OVS_L3D

    @classmethod
    def install(cls, client_object, resource=None, timeout=None, ordered=None):
        """
        Fetches the packages in a local directory and then installs them.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type resource: list
        @param resource: List of URLs to packages.
        @type ordered: str
        @param ordered: When True, the packages are installed in order as
            specified in the list. If the user specifies a remote directory
            then any package within that directory would still be installed
            based on dependencies as determined by package manager.
        @type timeout: int
        @param timeout: Time after which the attempt to install packages is
            aborted.
        @rtype: NonType
        @return: None
        """
        utilities.validate_list(resource)
        date_and_time = utilities.current_date_time()
        package_dir = os.sep.join([client_object.TMP_DIR, date_and_time])
        ordered = utilities.get_default(ordered, "false")
        try:
            if ordered.lower() == "false":
                # Let package manager resolve the dependencies.
                cls._install(
                    client_object, resource=resource, package_dir=package_dir,
                    timeout=timeout)
            else:
                for package in resource:
                    target_dir = filter(None, package.split('/'))[-1]
                    sub_dir = os.sep.join([package_dir, target_dir])
                    cls._install(
                        client_object, resource=package, package_dir=sub_dir,
                        timeout=timeout)
        # Remove the downloaded packages.
        finally:
            client_object.connection.request(command='rm -r %s' % package_dir,
                                             timeout=timeout)

    @classmethod
    def _install(cls, client_object, resource=None, package_dir=None,
                 timeout=None):
        """
        Helper to install the packages.

        @type resource: str
        @param resource: URL where the package needs to be fetched from.
        @type package_dir: str
        @param package_dir: Directory to which the packages would be
            downloaded.
        """
        try:
            # Fetch packages.
            linux_helper.Linux.wget_files(client_object, files=resource,
                                          directory=package_dir,
                                          accept=cls.PACKAGE_TYPE,
                                          timeout=timeout,
                                          content_disposition=True)
            install_cmd = ['%s %s %s' %
                           (cls.PKG_MGR, cls.INSTALL_OPTION,
                            os.sep.join([package_dir, cls.PACKAGE_TYPE]))]
            pkg_list = client_object.connection.request(
                command="ls %s" % package_dir).response_data.split()
            if any([package for package in pkg_list if
                    package.startswith(cls.RPM_KMOD_OPENVSWITCH)]):
                ovsdb_cmd = ("%s convert %s" %
                             (cls.OVSDB_TOOL, cls.OVSDB_LOCATION))
                install_cmd.extend(
                    ["/etc/init.d/%s force-reload-kmod" % (
                     cls.OPENVSWITCH_SERVICE),
                     "/etc/init.d/nicira-ovs-hypervisor-node restart",
                     "/etc/init.d/%s stop" % cls.OPENVSWITCH_SERVICE,
                     ovsdb_cmd,
                     "/etc/init.d/%s start" % cls.OPENVSWITCH_SERVICE,
                     cls.NETWORK_RESTART_CMD])
            nsxa_pkg = [
                os.sep.join([package_dir, package]) for package in pkg_list
                if package.startswith(cls.NSXA)]
            if nsxa_pkg and workarounds.nsxa_installation_workaround.enabled:
                # Install the nsxa with background command to prevent it from
                # halting the package installation.
                nsxa_install_cmd = ('%s %s %s > /dev/null 2>&1 &' %
                                    (cls.PKG_MGR, cls.INSTALL_OPTION,
                                     " ".join(nsxa_pkg)))
                client_object.connection.request(nsxa_install_cmd)
                pylogger.debug("Waiting 10 seconds for the nsxa installation")
                time.sleep(10)
            # Install packages.
            client_object.connection.request(
                command=' && '.join(install_cmd), timeout=timeout)
            if workarounds.debug_logs_workaround.enabled:
                # Debug logs for ovs-l3d
                if any([package for package in pkg_list if
                        package.startswith(cls.RPM_KMOD_OPENVSWITCH)]):
                    DefaultNSXImpl.set_log_level(
                        client_object, component=cls.OVS_L3D,
                        log_level="Debug")
                components = (cls.NSX_AGENT, cls.NSX_MPA, cls.NSXA)
                log_components = [
                    component for component in components for pkg in pkg_list
                    if pkg.startswith(component)]
                for component in log_components:
                    DefaultNSXImpl.set_log_level(
                        client_object, component=component,
                        log_level="Debug")
        except Exception, error:
            # TODO (Jialiang): Add more granular exception and more detail
            # error information.
            pylogger.exception("Packages installation failure due to "
                               "error: %s" % error)
            error.status_code = common.status_codes.RUNTIME_ERROR
            raise

    @classmethod
    def configure_package(cls, client_object, operation=None, resource=None,
                          timeout=None, ordered=None):
        """
        Configures package with the provided operations.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type operation: list
        @param operation: List of flags to configure the package.
        @type resource: list
        @param resource: List of package names to configure.
        @type timeout: int
        @param timeout: Time after which the attempt to configure package is
            aborted.
        """
        utilities.validate_list(resource)
        operation_to_method = {'install': cls.install,
                               'uninstall': cls.uninstall}
        if operation not in operation_to_method:
            raise ValueError('Unsupported operation %r provided for '
                             'configuring resources' % operation)
        return operation_to_method[operation](
            client_object, resource=resource, timeout=timeout, ordered=ordered)

    @classmethod
    def update(cls, client_object, resource=None):
        """
        Upgrades the packages if they are already installed, otherwise installs
        a fresh copy of the packages.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type resource: list
        @param resource: List of package names to update.
        @rtype: NoneType
        @return: None
        """
        update_cmd = ('%s %s %s' % (cls.PKG_MGR, cls.PACKAGE_TYPE,
                                    ' '.join(resource)))
        client_object.connection.request(update_cmd)

import vmware.common as common
import vmware.common.global_config as global_config

from vmware.interfaces.package_interface import PackageInterface

pylogger = global_config.pylogger


class ESX55PackageImpl(PackageInterface):

    @classmethod
    def install(cls, client_object, resource=None):
        for item in resource:
            command = 'esxcli software vib install -v %s' % item
            pylogger.info("Installing VIB command %s" % command)
            result = client_object.connection.request(command).response_data
            pylogger.info("ESX package installation result %s" % result)

    @classmethod
    def uninstall(cls, client_object, resource=None):
        raise NotImplementedError("STUB")

    @classmethod
    def update(cls, client_object, resource=None):
        raise NotImplementedError("STUB")

    @classmethod
    def configure_package(cls, client_object, operation='install',
                          resource=None, signaturecheck=None, maintenance=None,
                          timeout=global_config.PACKAGE_INSTALL_TIMEOUT):

        """
        Method to install/ uninstall vibs on the ESX host.
        It iterates over the vib list passed. Method can handle both '.vib'
        and '.zip' bundles.

        @param operation: Which operation to be performed install or uninstall.
        @param resource: List containing pkg name along with url.
        @param signaturecheck: Signature check while running command.
        @param maintenance: Command to be run in maintenance mode.
        @param timeout: Command execution timeout value in seconds.
        @rtype: None
        @return: None
        """
        install_options = ''

        if signaturecheck is True:
            pylogger.debug("signaturecheck requested")
        else:
            pylogger.debug("no signaturecheck requested")
            install_options += ' --no-sig-check'

        for item in resource:
            if operation.lower() == 'install':
                file_name = item.split('/')[-1]
                command = 'rm -f /tmp/%s; cd /tmp && wget %s' %\
                    (file_name, item)
                result = client_object.connection.request(
                    command, timeout=timeout).response_data
                pylogger.debug("Downloaded offline bundle: %s %s" %
                               (file_name, result))
                if item.endswith('.zip'):
                    command = ('esxcli software vib install -d /tmp/%s' %
                               file_name)
                    command += install_options
                elif item.endswith('.vib'):
                    command = ('esxcli software vib install -v \"/tmp/%s\"' %
                               file_name)
                    command += install_options
                else:
                    raise TypeError("%s is not a valid file to install" %
                                    file_name)
            # Vib un-installation command preparation
            elif operation.lower() == 'uninstall':
                command = 'esxcli software vib remove --vibname=%s' % item

            else:  # just download the file
                other_file = item.split('/')[-1]
                command = 'rm -f /tmp/%s; cd /tmp && wget %s' %\
                    (other_file, item)

            if command.startswith('esxcli software vib install'):
                action_message = 'Running vib install:'
                action_error = 'ESX package installation result'
            elif command.startswith('esxcli software vib remove'):
                action_message = 'Running vib uninstall:'
                action_error = 'ESX package un-installation result'
            else:
                action_message = 'Downloading file:'
                action_error = 'File download result'

            pylogger.info("%s %s" % (action_message, command))

            action = ''
            try:
                action = client_object.connection.request(
                    command, timeout=timeout).response_data
            except Exception, error:
                pylogger.error("%s %s" % (action_error, error))
                error.status_code = common.status_codes.RUNTIME_ERROR
                raise

            pylogger.info("%s" % action)

            if item.endswith('.zip'):
                zip_file = item.split('/')[-1]
                command = 'rm -f /tmp/%s' % zip_file
                client_object.connection.request(
                    command, timeout=timeout)

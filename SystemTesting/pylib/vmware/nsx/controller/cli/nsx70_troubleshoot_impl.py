import time
import vmware.common as common
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.common.constants as constants
import vmware.interfaces.troubleshoot_interface as troubleshoot_interface

pylogger = global_config.pylogger


class NSX70TroubleshootImpl(troubleshoot_interface.TroubleshootInterface):

    @classmethod
    def copy_tech_support(cls, client_object, logdir=None, collectorIP=None):
        """
        Copy CCP tech support file to given dir on collectorIP

        @logdir: String
        @collectorIP: IP address for collector,

        """
        filename = ('techsupportbundle-%s.tar.gz' %
                    time.strftime("%Y%m%d-%H%M%S"))
        cmd = "get support-bundle file " + filename
        client_object.connection.request(command=cmd,
                                         expect=['bytes*', '>'])
        cmd = ("copy file %s url scp://root@%s%s%s" %
               (filename, collectorIP, logdir, filename))
        try:
            client_object.connection.execute_command_with_hostkey_prompt(
                cmd, global_config.DEFAULT_PASSWORD,
                final_expect=['bytes*', '>'])
        except Exception, error:
            pylogger.error("Copy tech support bundle failed from %s "
                           "to %s with command: %s" %
                           (client_object.ip, collectorIP, cmd))
            pylogger.error("Failed reason: %s" % error)
            raise errors.CLIError(status_code=common.status_codes.FAILURE)

        pylogger.debug("Copied tech support bundle successfully from %s "
                       "to %s with command: %s" %
                       (client_object.ip, collectorIP, cmd))
        return constants.Result.SUCCESS.upper()

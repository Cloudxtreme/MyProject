import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.interfaces.setup_interface as setup_interface

pylogger = global_config.pylogger


class Edge70SetupImpl(setup_interface.SetupInterface):

    @classmethod
    def register_nsx_edge_node(cls, client_object, manager_ip=None,
                               manager_username=None,
                               manager_password=None,
                               manager_thumbprint=None):
        try:
            # This method register edgenode with nsx manager
            cmd = 'join management-plane'
            command = ('%s %s thumbprint %s username %s password %s' %
                       (cmd, manager_ip, manager_thumbprint,
                        manager_username, manager_password))
            # XXX(dbadiani): Prompt we expect after exiting the configure
            # termninal mode on Edge VM.
            expect = ['bytes*', '>']
            pylogger.info("Executing NSX registration command: %s" % command)
            result = client_object.connection.request(
                command=command, expect=expect)
            client_object.connection.close()

            if result.status_code == 0:
                pylogger.info("Edge registration to NSX succeeded")
            else:
                pylogger.error("Edge registration to NSX failed")
                raise errors.CLIError(status_code=result.status_code,
                                      response_data=result.response_data,
                                      reason=result.error)
        except Exception, e:
            raise errors.CLIError(exc=e)

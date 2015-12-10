import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface

pylogger = global_config.pylogger


class Ubuntu1204CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def get_certificate(cls, client_object):

        cert_cmd = "cat  /etc/openvswitch/ovsclient-cert.pem | tail -n 21"
        result = client_object.connection.request(cert_cmd)

        return result.response_data

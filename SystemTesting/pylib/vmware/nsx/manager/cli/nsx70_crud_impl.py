import re

import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface

pylogger = global_config.pylogger


class NSX70CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def get_manager_thumbprint(cls, client_object):
        """
        Method to NSX manager thumbprint

        Sample output of the command 'show api certificate thumbprint':

        nimbus-cloud-nsxmanager> show api certificate thumbprint
        f71250ab638c9939a91b0db1b89619a43a9cda44a2c8628167ce5327d44bd16f

        nimbus-cloud-nsxmanager>
        """
        connection = client_object.connection
        command = 'get certificate api thumbprint'
        pylogger.debug('Command to get manager thumbprint %s' % command)
        # bytes* is used to skip/avoid any pagination information dumped
        # on the screen
        expect_prompt = ['bytes*', '>']
        result = connection.request(command, expect_prompt)
        stdout_lines = result.response_data.splitlines()
        thumbprint_index_in_output = 0
        thumbprint = stdout_lines[thumbprint_index_in_output]
        thumbprint = thumbprint.strip()
        if re.match(constants.Regex.ALPHA_NUMBERIC, thumbprint):
            return thumbprint
        else:
            raise ValueError("Unexpected data for thumbprint %s" %
                             result.response_data)

    @classmethod
    def get_manager_messaging_thumbprint(cls, client_object):
        """
        Method to NSX manager RMQ thumbprint

        Sample output of the command:
        [root@nimbus-cloud-nsxmanager ~]#
        "openssl x509 -in /home/secureall/secureall/.store/.rabbitmq_cert.pem"\
        " -noout -sha256 -fingerprint"
        [root@nimbus-cloud-nsxmanager ~]#
        "SHA256 Fingerprint=E4:03:3C:7C:08:B6:B2:F9:4D:4F:E8:A7:FA:3C:47:03:" \
        "3B:F6:50:46:3F:C0:F3:7E:72:D1:FF:21:B2:01:5D:50"
        [root@nimbus-cloud-nsxmanager ~]#
        """
        client_object.connection.login_to_st_en_terminal(expect=['#'])
        command = " openssl x509 -in " \
                  " /home/secureall/secureall/.store/.rabbitmq_cert.pem " \
                  " -noout -sha256 -fingerprint"
        pylogger.debug('Command to get manager RMQ thumbprint %s' % command)
        expect_prompt = ['bytes*', '#']
        result = client_object.connection.request(command, expect_prompt)
        stdout_lines = result.response_data.splitlines()
        lines = stdout_lines[0].split('=')
        thumbprint = lines[1].strip().replace(':', '')
        if re.match(constants.Regex.ALPHA_NUMBERIC, thumbprint):
            return thumbprint.lower()
        else:
            raise ValueError("Unexpected data for RMQ thumbprint %s" %
                             result.response_data)

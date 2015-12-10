import vmware.common as common
import vmware.common.global_config as global_config
import vmware.interfaces.auth_server_interface as auth_server_interface


pylogger = global_config.pylogger


class TACACSAuthServerImpl(
        auth_server_interface.AuthServerInterface):
    TACACS_CONF_FILE = '/etc/tacacs+/tac_plus.conf'
    TACACS_CONF_PATH = '/etc/tacacs+/'

    @classmethod
    def configure_service_state(cls, client_obj, state=None, **kwargs):
        if state == 'start' or state == 'stop' or state == 'restart':
            endpoint = '/etc/init.d/tacacs_plus %s' % state
            pylogger.debug('Command to be executed: [%s]' % endpoint)
            expect_prompt = ['--More--', '#']
        else:
            raise ValueError("Received incorrect state value")

        raw_payload = client_obj.connection.request(endpoint, expect_prompt)\
            .response_data

        lines = raw_payload.strip().split("\n")
        pydict = dict()

        if (len(lines) > 0) and (lines[1].upper().find("FAIL") > 0):
            pylogger.exception("Action [%s] on service tacacs_plus failed "
                               % state)
            pydict.update({'content': 'error'})
            return pydict

        pydict.update({'content': raw_payload})
        return pydict

    @classmethod
    def add_user(cls, client_obj, username=None, password=None,
                 service='vmware_nsx', **kwargs):
        """
        Append a user credentials in the TACACS config file
        using the 'echo' command to achieve this
        :param client_obj: BaseClient
        :param username: user name
        :param password: password
        :return: SUCCESS or FAILURE
        """
        if username and password:
            append_string = "\nuser = %s { \n        pap = cleartext \"%s\" \n" % (username, password)  # noqa
            append_string += "        chap = cleartext \"%s\" \n" % password
            append_string += "        login = cleartext \"%s\" \n" % password
            append_string += "        service = %s { }\n}" % service

            endpoint = 'echo "%s" >> %s' % (append_string,
                                            cls.TACACS_CONF_FILE)
            pylogger.debug('Command to be executed: [%s]' % endpoint)
            expect_prompt = ['--More--', '#']
        else:
            raise ValueError("Received empty username/password")

        try:
            client_obj.connection.request(endpoint, expect_prompt)
            return common.status_codes.SUCCESS
        except Exception, error:
            pylogger.exception("Failed to add user: %s" % error)
            return common.status_codes.FAILURE

    @classmethod
    def backup_config_file(cls, client_obj, file_name=None, **kwargs):
        """
        makes a copy of TACACS conf file
        :param client_obj: BaseClient
        :param file_name: file name for copied file
        :return: SUCCESS or FAILURE
        """
        if file_name:
            endpoint = 'cp %s %s' % (cls.TACACS_CONF_FILE,
                                     cls.TACACS_CONF_PATH + file_name)
            pylogger.debug('Command to be executed: [%s]' % endpoint)
            expect_prompt = ['--More--', '#']
        else:
            raise ValueError("Received empty file name")

        try:
            client_obj.connection.request(endpoint, expect_prompt)
            return common.status_codes.SUCCESS
        except Exception, error:
            pylogger.exception("Failed to take backup of TACACS "
                               "config file: %s" % error)
            return common.status_codes.FAILURE

    @classmethod
    def restore_config_file(cls, client_obj, file_name=None, **kwargs):
        """
        restores TACACS conf file
        using the 'mv' command to replace tac_plus.conf file
        :param client_obj: BaseClient
        :param file_name: file name to be restored
        :return: SUCCESS or FAILURE
        """
        if file_name:
            endpoint = 'mv %s %s' % (cls.TACACS_CONF_PATH + file_name,
                                     cls.TACACS_CONF_FILE)
            pylogger.debug('Command to be executed: [%s]' % endpoint)
            expect_prompt = ['--More--', '#']
        else:
            raise ValueError("Received empty file name")

        try:
            client_obj.connection.request(endpoint, expect_prompt)
            return common.status_codes.SUCCESS
        except Exception, error:
            pylogger.exception("Failed to restore TACACS "
                               "config file: %s" % error)
            return common.status_codes.FAILURE

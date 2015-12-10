import vmware.common.global_config as global_config
import re
pylogger = global_config.pylogger


class ShowPasswordParser:

    def get_parsed_data(self, command_response, delimiter=' '):
        pydict = dict()
        lines = command_response.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[0].strip() == ""))):
            pylogger.warn('Command returned either ERROR or NOT FOUND '
                          'or no output')
            raise Exception('Command returned either ERROR or NOT FOUND '
                            'or no output')

        user_with_un_encrypted_password = ""
        for user_details in lines:
            if re.search(":", user_details):
                if not (user_details.split(":")[1] == "x"):
                    user_with_un_encrypted_password = \
                        user_with_un_encrypted_password + \
                        user_details.split(":")[0] + ", "

        if user_with_un_encrypted_password:
            user_with_un_encrypted_password = \
                user_with_un_encrypted_password[:-2]
        else:
            user_with_un_encrypted_password = "None"

        pydict.update({'user_with_un_encrypted_password'
                       '': user_with_un_encrypted_password})

        return pydict

import time
import re

import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.appliance_interface as appliance_interface

pylogger = global_config.pylogger


class NSX70ApplianceImpl(appliance_interface.ApplianceInterface):

    @classmethod
    def verify_version(cls, client_obj, **kwargs):
        endpoint = "get version"
        parser = "raw/showVersion"
        expect_prompt = ['bytes*', '>']

        mapped_pydict = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser,
                                         expect_prompt,
                                         ' ')
        return mapped_pydict

    @classmethod
    def get_system_config(cls, client_obj, system_parameter, **kwargs):
        endpoint = "get system " + system_parameter
        parser = "raw/showSystemConfig"
        expect_prompt = ['bytes*', '>']

        func = utilities.get_mapped_pydict_for_expect
        if system_parameter == 'storage':
            mapped_pydict = func(client_obj.connection, endpoint, parser,
                                 expect_prompt, "controller_storage", ' ')
        else:
            mapped_pydict = func(client_obj.connection, endpoint, parser,
                                 expect_prompt, system_parameter, ' ')

        if system_parameter == 'uptime':
            time_update_begin = mapped_pydict['time_update']
            time.sleep(60)
            next_pydict = func(client_obj.connection, endpoint, parser,
                               expect_prompt, system_parameter, ' ')
            time_update_end = next_pydict['time_update']
            valid_up_time = 'False'
            array_length = len(time_update_begin)
            for itr in time_update_end:
                while array_length > 0:
                    if time_update_end[array_length - 1] > \
                            time_update_begin[array_length - 1]:
                        valid_up_time = 'True'
                        break
                    array_length -= 1

            mapped_pydict.update({'valid_up_time': valid_up_time})
        return mapped_pydict

    @classmethod
    def search_log(cls, client_obj, **kwargs):
        if kwargs['file_name'] is None:
            raise ValueError('file_name parameter is missing')
        if kwargs['search_string'] is None:
            raise ValueError('search_string parameter is missing')
        endpoint = "get log %s" % kwargs['file_name']
        expect_prompt = ['--More--', '>']
        pydict = dict()

        raw_payload = client_obj.connection.request(endpoint, expect_prompt)\
            .response_data
        if kwargs['search_string'] == "Exception":
            string_count = len(re.findall(kwargs['search_string'] + ":",
                                          raw_payload))
        else:
            string_count = len(re.findall(kwargs['search_string'],
                                          raw_payload))
        pydict.update({'string_count': string_count})
        return pydict

    @classmethod
    def get_configuration(cls, client_obj, **kwargs):
        endpoint = "get configuration"
        parser = "raw/showNSXConfiguration"
        expect_prompt = ['bytes*', '>']

        mapped_pydict = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser,
                                         expect_prompt,
                                         ' ')
        return mapped_pydict

    @classmethod
    def show_interfaces(cls, client_obj, **kwargs):
        endpoint = "get interfaces"
        parser = "raw/showInterfacesNSX"
        expect_prompt = ['bytes*', '>']

        mapped_pydict = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser,
                                         expect_prompt,
                                         ' ')
        return mapped_pydict

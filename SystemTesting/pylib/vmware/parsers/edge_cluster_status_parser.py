import re
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class EdgeClusterStatusParser(object):
    """
    Class for parsing the data received from "show edge-cluster status"
    command executed on NSX Edge VM.

    >>> import pprint
    >>> edgeClusterStatusParser = EdgeClusterStatusParser()
    >>> raw_data = '''
    ... Highavailability Status:             Standby
    ... Highavailability State since:        2014-10-22 17:45:43.559
    ... Highavailability Unit Id:            0
    ... Highavailability Unit State:         Down
    ... Highavailability Admin State:        Up
    ... Highavailability Running Resources:  None
    ... Highavailability Active Nodes:       None
    ... Unit Poll Policy:
    ...    Frequency:                       1     seconds
    ...    Deadtime:                        6     seconds
    ... Highavailability Services Status:
    ...    Routing Status Channel:          Up
    ...    Routing Status:                  Down
    ...    Healthcheck Config Channel:      Up
    ...    Healthcheck Status Channel:      Up
    ...    Highavailability Healthcheck Status:
    ... This unit [0]: Down
    ...    Peer unit [1]: Down
    ...       Session via vNic_0: 10.110.63.98:10.110.63.47 Down
    ...       Session via vNic_2: 169.255.255.241:169.255.255.242 Down
    ...    Peer unit [2]: Down
    ...       Session via vNic_0: 10.110.63.98:10.110.63.240 Down
    ...       Session via vNic_2: 169.255.255.241:169.255.255.243 Down
    ...    '''
    >>> py_dict=edgeClusterStatusParser.get_parsed_data(raw_data)
    >>> pprint.pprint(py_dict)
    {'deadtime': '6',
     'frequency': '1',
     'ha_admin_state': 'Up',
     'ha_status': 'Standby',
     'ha_unit_state': 'Down',
     'healthcheck_config_channel': 'Up',
     'healthcheck_status_channel': 'Up',
     'routing_status': 'Down',
     'routing_status_channel': 'Up',
     'sessions': [{'from_ip': '10.110.63.98',
                   'status': 'down',
                   'to_ip': '10.110.63.47'},
                  {'from_ip': '169.255.255.241',
                   'status': 'down',
                   'to_ip': '169.255.255.242'},
                  {'from_ip': '10.110.63.98',
                   'status': 'down',
                   'to_ip': '10.110.63.240'},
                  {'from_ip': '169.255.255.241',
                   'status': 'down',
                   'to_ip': '169.255.255.243'}]}

    """

    DEFAULT_DELIMITER = ' '

    def get_parsed_data(self, raw_data, delimiter=None):
        '''
        @type raw_data: str
        @param raw_data: output from the CLI execution result
        @type delimiter: str
        @param delimiter: character to split the key and value
        @rtype: dict
        @return: calling the get_parsed_data function will return a hash
                 based on above sample, the return data
        '''

        default_list_val = []
        default_str_val = ''
        py_dict = {}
        sessions = []

        if delimiter is None:
            delimiter = self.DEFAULT_DELIMITER

        ha_status_regex = "Highavailability Status:\s+(\w+)"
        ha_status_result = re.search(ha_status_regex, raw_data,
                                     re.IGNORECASE)

        if ha_status_result:
            ha_status = ha_status_result.group(1)
        else:
            pylogger.warn("Failed to find Highavailability Status")
            ha_status = None

        ha_unit_state_regex = "Highavailability Unit State:\s+(\w+)"
        ha_unit_state_result = re.search(ha_unit_state_regex, raw_data,
                                         re.IGNORECASE)

        if ha_unit_state_result:
            ha_unit_state = ha_unit_state_result.group(1)
        else:
            pylogger.warn("Failed to find Highavailability Unit State")
            ha_unit_state = None

        ha_admin_state_regex = "Highavailability Admin State:\s+(\w+)"
        ha_admin_state_result = re.search(ha_admin_state_regex, raw_data,
                                          re.IGNORECASE)
        if ha_admin_state_result:
            ha_admin_state = ha_admin_state_result.group(1)
        else:
            pylogger.warn("Failed to find Highavailability Admin State")
            ha_admin_state = None

        frequency_regex = "Frequency:\s+(\w+)"
        frequency_result = re.search(frequency_regex, raw_data,
                                     re.IGNORECASE)
        if frequency_result:
            frequency = frequency_result.group(1)
        else:
            pylogger.warn("Failed to find Frequency Value")
            frequency = None

        deadtime_regex = "Deadtime:\s+(\w+)"
        deadtime_result = re.search(deadtime_regex, raw_data,
                                    re.IGNORECASE)
        if deadtime_result:
            deadtime = deadtime_result.group(1)
        else:
            pylogger.warn("Failed to find Deadtime Value")
            deadtime = None

        routing_status_channel_regex = "Routing Status Channel:\s+(\w+)"
        routing_status_channel_result = re.search(routing_status_channel_regex,
                                                  raw_data, re.IGNORECASE)

        if routing_status_channel_result:
            routing_status_channel = routing_status_channel_result.group(1)
        else:
            pylogger.warn("Failed to find Routing Status Channel")
            routing_status_channel = None

        routing_status_regex = "Routing Status:\s+(\w+)"
        routing_status_result = re.search(routing_status_regex, raw_data,
                                          re.IGNORECASE)

        if routing_status_result:
            routing_status = routing_status_result.group(1)
        else:
            pylogger.warn("Failed to find Routing Status")
            routing_status = None

        healthcheck_config_channel_regex = "Healthcheck Config " \
                                           "Channel:\s+(\w+)"

        healthcheck_config_channel_result = re.search(
            healthcheck_config_channel_regex, raw_data, re.IGNORECASE)

        if healthcheck_config_channel_result:
            healthcheck_config_channel = \
                healthcheck_config_channel_result.group(1)
        else:
            pylogger.warn("Failed to find Healthcheck Config Channel status")
            healthcheck_config_channel = None

        healthcheck_status_channel_regex = \
            "Healthcheck Status Channel:\s+(\w+)"

        healthcheck_status_channel_result = re.search(
            healthcheck_status_channel_regex, raw_data, re.IGNORECASE)

        if healthcheck_status_channel_result:
            healthcheck_status_channel = \
                healthcheck_status_channel_result.group(1)
        else:
            pylogger.warn("Failed to find Healthcheck Status Channel")
            healthcheck_status_channel = None

        session_regex = "Session\s+via\s+.*\s+" \
                        "(\d+\.\d+\.\d+\.\d+:\d+\.\d+\.\d+\.\d+.*)"
        list_sessions = re.findall(session_regex, raw_data, re.IGNORECASE)
        temp_sessions = [re.sub("\s+", " ", x).replace(":", " ").lower().
                         split(' ') for x in list_sessions]

        for x in temp_sessions:
            sessions.append(dict(zip(('from_ip', 'to_ip', 'status'),
                                     tuple(x))))

        import vmware.common.utilities as utilities

        py_dict['ha_status'] = utilities.get_default(ha_status,
                                                     default_str_val)
        py_dict['ha_unit_state'] = utilities.get_default(ha_unit_state,
                                                         default_str_val)
        py_dict['ha_admin_state'] = utilities.get_default(ha_admin_state,
                                                          default_str_val)
        py_dict['frequency'] = utilities.get_default(frequency,
                                                     default_str_val)
        py_dict['deadtime'] = utilities.get_default(deadtime,
                                                    default_str_val)
        py_dict['routing_status_channel'] = utilities.get_default(
            routing_status_channel, default_str_val)
        py_dict['routing_status'] = utilities.get_default(routing_status,
                                                          default_str_val)
        py_dict['healthcheck_config_channel'] = utilities.get_default(
            healthcheck_config_channel, default_str_val)
        py_dict['healthcheck_status_channel'] = utilities.get_default(
            healthcheck_status_channel, default_str_val)
        py_dict['sessions'] = utilities.get_default(sessions,
                                                    default_list_val)

        return py_dict

if __name__ == '__main__':
    import doctest
    doctest.testmod()

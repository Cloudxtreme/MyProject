import json


def read_nimbus_config(config_file=None, pod_name=None):
    """ Routine to read nimbus config

    @param config_file: nimbus config file
    @param pod_name: nimbus pod name
    @return config_dict: dict of nimbus pod values
    """

    with open(config_file, 'r') as file_handle:
        config_json_data = json.loads(file_handle.read())
    config_dict = {}
    config_dict['vc'] = config_json_data[pod_name]['RBVMOMI_HOST']
    config_dict['vc_user'] = config_json_data[pod_name]['RBVMOMI_USER']
    config_dict['vc_password'] = config_json_data[pod_name]['RBVMOMI_PASSWORD']
    config_dict['datacenter'] = \
        config_json_data[pod_name]['RBVMOMI_DATACENTER']
    config_dict['datastore'] = config_json_data[pod_name]['RBVMOMI_DATASTORE']
    config_dict['computer'] = config_json_data[pod_name]['RBVMOMI_COMPUTER']
    config_dict['network'] = config_json_data[pod_name]['RBVMOMI_NETWORK']
    if 'NIMBUS_NSX' in config_json_data[pod_name]:
        config_dict['nsx'] = config_json_data[pod_name]['NIMBUS_NSX']
    if 'NIMBUS_NSX_USER' in config_json_data[pod_name]:
        config_dict['nsx_user'] = config_json_data[pod_name]['NIMBUS_NSX_USER']
    if 'NIMBUS_NSX_PASSWORD' in config_json_data[pod_name]:
        config_dict['nsx_password'] = \
            config_json_data[pod_name]['NIMBUS_NSX_PASSWORD']
    if 'DEFAULT_CPU_RESERVATION' in config_json_data[pod_name]:
        config_dict['cpu_reservation'] = \
            config_json_data[pod_name]['DEFAULT_CPU_RESERVATION']
    if 'DEFAULT_MEMORY_RESERVATION' in config_json_data[pod_name]:
        config_dict['memory_reservation'] = \
            config_json_data[pod_name]['DEFAULT_MEMORY_RESERVATION']

    return config_dict

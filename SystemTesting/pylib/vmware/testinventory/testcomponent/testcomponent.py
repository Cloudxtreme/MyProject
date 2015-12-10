import vmware.common as common
import vmware.common.errors as errors


def read():
    raise Exception('SDK doesnt support read yet')


class TestComponent():

    def __init__(self, parent=None, id_=None):
        """ Constructor to create TestInventory object
        """
        self.id = None

    def get_component_mac(self, id=None):
        return 2.6

    def create(self, **kargs):
        hash = {}
        hash['response_data'] = {'status_code': None, 'id_': None}
        hash['response_data']['status_code'] = 'SUCCESS'
        hash['id_'] = '0000'
        return hash

    def success_unit_test(self, **kargs):
        hash = {}
        hash = {'status_code': None, 'id_': None}
        hash['status_code'] = 'SUCCESS'
        hash['id_'] = '0000'
        return hash

    def read(self, status_code_exception_unit_test=None, **kargs):
        if status_code_exception_unit_test is not None:
            return dict(
                status_code=status_code_exception_unit_test.get('return_sc'),
                exc=status_code_exception_unit_test.get('return_exc'),
            )

        hash = {}
        hash['response_data'] = {'status_code': None, 'id_': None}
        hash['response_data']['status_code'] = 'FAILURE'
        try:
            read()
        except Exception, e:
            errors.APIError(
                status_code=common.status_codes.METHOD_NOT_ALLOWED,
                exc=e)
            raise  # raise the original exception to save the stack

    def delete(self, **kargs):
        hash = {}
        hash['response_data'] = {'status_code': None, 'id_': None}
        hash['response_data']['status_code'] = 'SUCCESS'
        hash['id_'] = '0000'
        return hash

    def read_array(self, **kargs):
        data = {}
        data['result_count'] = '2'
        data['result'] = [{'interface_id': 'lo',
                           'physical_address': '00:00:00:00:00:00'},
                          {'interface_id': 'mgmt',
                           'physical_address': '00:50:56:83:2e:75'}]
        hash = {}
        hash['response_data'] = data
        hash['id_'] = '0000'
        return data

    def helper_read_array(self, **kargs):
        data = {}
        data = {'response': {'address': '00:50:56:83:2e:75'}}
        hash = {}
        hash['response_data'] = data
        hash['id_'] = '0000'
        return data

    def get_array(self, **kargs):
        data = {}
        data['result_count'] = '2'
        data['result'] = [{'interface_id': 'lo',
                           'physical_address': '00:00:00:00:00:00'},
                          {'interface_id': 'mgmt',
                           'physical_address': '00:50:56:83:2e:75'}]
        hash = {}
        hash['response_data'] = data
        hash['id_'] = '0000'
        return data

    def helper_get_array(self, **kargs):
        data = {}
        data = {'response': {'address': '00:50:56:83:2e:75'}}
        hash = {}
        hash['response_data'] = data
        hash['id_'] = '0000'
        return data

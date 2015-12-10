import httplib
import json
import vmware.common as common
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.interfaces.test_interface as test_interface
import vmware.nsx_api.ui.ui_driver.ui_driver as ui_driver
import vmware.nsx_api.ui.ui_driver.schema.ui_driver_schema\
    as ui_driver_schema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70TestImpl(test_interface.TestInterface,
                    base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'sessionId',
        'username': 'user_name',
        'nsxmanager_url': 'nsx_ip'
    }

    _client_class = ui_driver.UIDriver
    _schema_class = ui_driver_schema.UIDriverSchema
    _url_prefix = "/uiauto/v1"

    @classmethod
    def verify_ui_component(cls, client_obj, test_name=None, **kwargs):
        client_class_obj = cls.get_sdk_client_object(client_obj)
        pylogger.debug("Execute UI test: %s", test_name)

        method = constants.HTTPVerb.PUT
        endpoint = cls._url_prefix + '/ui-driver'
        headers = {"Content-type": "application/text"}
        conn = client_class_obj.get_connection()
        response = conn.request(method, endpoint, test_name, headers)
        response_data = response.read()
        if response.status not in [httplib.OK]:
            pylogger.error('REST call failed: Details: %s', response_data)
            pylogger.error('ErrorCode: %s', response.status)
            pylogger.error('Reason: %s', response.reason)
            raise errors.Error(status_code=common.status_codes.FAILURE,
                               reason=response.reason)

        result_dict = json.loads(response_data)
        return result_dict

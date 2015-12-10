import vmware.nsx_api.ui.ui_driver.ui_driver as ui_driver
import vmware.nsx_api.ui.ui_driver.schema.ui_driver_schema\
    as ui_driver_schema

import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'sessionId',
        'username': 'user_name',
        'nsxmanager_url': 'nsx_ip'
    }

    _client_class = ui_driver.UIDriver
    _schema_class = ui_driver_schema.UIDriverSchema
    _url_prefix = "/uiauto/v1"

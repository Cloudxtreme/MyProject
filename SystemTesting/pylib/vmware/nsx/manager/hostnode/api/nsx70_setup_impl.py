import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.setup_interface as setup_interface
import vmware.nsx.manager.api.base_crud_impl\
    as base_crud_impl

import vmware.nsx_api.manager.common.hostnode_schema as hostnode_schema
import vmware.nsx_api.manager.common.hostnodelogincredential_schema\
    as hostnodelogincredential_schema
import vmware.nsx_api.manager.hostprepservicefabric.\
    performhostnodeprepareaction as performhostnodeprepareaction
import vmware.nsx_api.manager.hostprepservicefabric.\
    performhostnodeunprepareaction as performhostnodeunprepareaction

pylogger = global_config.pylogger


class NSX70SetupImpl(base_crud_impl.BaseCRUDImpl,
                     setup_interface.SetupInterface):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'host_msg_client_info': 'msg_client_info'
    }
    _client_class = performhostnodeprepareaction.PerformHostNodePrepareAction
    _schema_class = hostnodelogincredential_schema.\
        HostNodeLoginCredentialSchema
    _response_schema_class = hostnode_schema.HostNodeSchema

    @classmethod
    def get_sdk_client_object(cls, client_object, host_id=None):
        client_class_obj = cls._client_class(
            connection_object=client_object.connection,
            url_prefix=cls._url_prefix,
            addnode_id=host_id)

        client_class_obj.schema_class = (
            cls._response_schema_class.__module__ + '.' +
            cls._response_schema_class.__name__)

        return client_class_obj

    @classmethod
    def install_nsx_components(cls, client_obj,
                               credential=None, host_id=None):
        pylogger.info("%s.install_nsx_components(credential=%s)" %
                      (cls.__name__, credential))
        return cls._perform_action(client_obj,
                                   credential=credential,
                                   host_id=host_id)

    @classmethod
    def uninstall_nsx_components(cls, client_obj,
                                 credential=None, host_id=None):
        cls._client_class = performhostnodeunprepareaction.\
            PerformHostNodeUnprepareAction
        pylogger.info("%s.uninstall_nsx_components(credential=%s)" %
                      (cls.__name__, credential))
        return cls._perform_action(client_obj,
                                   credential=credential,
                                   host_id=host_id)

    @classmethod
    def _perform_action(cls, client_obj, credential=None, host_id=None):
        cls.sanity_check()
        cls.assign_response_schema_class()

        client_class_obj = cls.get_sdk_client_object(
            client_object=client_obj,
            host_id=host_id)

        payload = utilities.map_attributes(cls._attribute_map, credential)
        pylogger.debug("Payload: %s" % payload)

        schema_class_obj = cls._schema_class(payload)
        response_schema_object = client_class_obj.create(
            schema_object=schema_class_obj)

        schema_dict = response_schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

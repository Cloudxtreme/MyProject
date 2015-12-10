import time
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.messaging.addmessagingclient \
    as addmessagingclient
import vmware.nsx_api.manager.messaging.getheartbeatstatus \
    as getheartbeatstatus
import vmware.nsx_api.manager.messaging.ping as ping
import vmware.nsx_api.manager.messaging.schema.heartbeatstatus_schema \
    as heartbeatstatus_schema
import vmware.nsx_api.manager.messaging.schema.messagingclient_schema \
    as messagingclient_schema
import vmware.nsx_api.manager.messaging.schema.\
    messagingclientlistresult_schema as messagingclientlistresult_schema
import vmware.nsx_api.manager.messaging.schema.\
    pingstatus_schema as pingstatus_schema

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'client_id',
        'client_status': 'status'
    }

    _client_class = addmessagingclient.AddMessagingClient
    _schema_class = messagingclient_schema.MessagingClientSchema
    _response_schema_class = messagingclient_schema.MessagingClientSchema
    _list_schema_class = \
        messagingclientlistresult_schema.MessagingClientListResultSchema

    @classmethod
    def create(cls, client_object, **kwargs):
        cls._response_schema_class = \
            messagingclientlistresult_schema.MessagingClientListResultSchema
        cls.sanity_check()
        client_class_obj = cls._client_class(
            connection_object=client_object.connection)

        client_class_obj.schema_class = (
            cls._response_schema_class.__module__ + '.' +
            cls._response_schema_class.__name__)

        schema_object = client_class_obj.read()
        schema_dict = schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def ping_client(cls, client_object, **kwargs):
        cls._client_class = ping.Ping
        cls._response_schema_class = pingstatus_schema.PingStatusSchema

        cls.sanity_check()
        client_class_obj = cls._client_class(
            connection_object=client_object.
            connection, addmessagingclient_id=client_object.id_)

        client_class_obj.schema_class = (
            cls._response_schema_class.__module__ + '.' +
            cls._response_schema_class.__name__)
        schema_object = client_class_obj.create()
        schema_dict = schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        if verification_form['client_status'] == 'SUCCESS':
            verification_form['client_status'] = 'true'
        else:
            time.sleep(60)
            schema_object = client_class_obj.create()
            schema_dict = schema_object.get_py_dict_from_object()
            verification_form = utilities.map_attributes(
                cls._attribute_map, schema_dict, reverse_attribute_map=True)
            if verification_form['client_status'] == 'SUCCESS':
                verification_form['client_status'] = 'true'
            else:
                verification_form['client_status'] = 'false'

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def read(cls, client_object, **kwargs):
        client_type = None
        broker_id = None
        try:
            client_type = kwargs['client_type']
        except Exception:
            pass

        try:
            broker_id = kwargs['broker_id']
        except Exception:
            pass

        cls.sanity_check()
        if client_type is not None or broker_id is not None:
            cls._response_schema_class = messagingclientlistresult_schema.\
                MessagingClientListResultSchema
            cls.assign_response_schema_class()

        client_class_obj = cls._client_class(
            connection_object=client_object.connection)
        client_class_obj.schema_class = (
            cls._response_schema_class.__module__ + '.' +
            cls._response_schema_class.__name__)

        if client_type is not None:
            parameters = {'client_type': client_type}
            schema_object = client_class_obj.read(url_parameters=parameters)
        elif broker_id is not None:
            parameters = {'broker_id': broker_id}
            schema_object = client_class_obj.read(url_parameters=parameters)
        else:
            schema_object = client_class_obj.read(object_id=client_object.id_)

        schema_dict = schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def heartbeat_status(cls, client_object, **kwargs):
        cls._client_class = getheartbeatstatus.GetHeartbeatStatus
        cls._response_schema_class = \
            heartbeatstatus_schema.HeartbeatStatusSchema

        cls.sanity_check()
        client_class_obj = cls._client_class(
            connection_object=client_object.
            connection, addmessagingclient_id=client_object.id_)

        client_class_obj.schema_class = (
            cls._response_schema_class.__module__ + '.' +
            cls._response_schema_class.__name__)
        schema_object = client_class_obj.read()
        schema_dict = schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def get_distributed_clients(cls, client_object, broker_list=None,
                                **kwargs):
        if type(broker_list) is not list:
            raise ValueError('Incorrect value provided for broker_list. '
                             'Incorrect Type: %s' % type(broker_list))

        client_count = 0
        cls._response_schema_class = messagingclientlistresult_schema.\
            MessagingClientListResultSchema
        client_class_obj = cls._client_class(
            connection_object=client_object.connection)
        client_class_obj.schema_class = (
            cls._response_schema_class.__module__ + '.' +
            cls._response_schema_class.__name__)

        for broker in broker_list:
            parameters = {'broker_id': broker['broker_id']}
            schema_object = client_class_obj.read(url_parameters=parameters)
            schema_dict = schema_object.get_py_dict_from_object()
            verification_form = utilities.map_attributes(
                cls._attribute_map, schema_dict, reverse_attribute_map=True)
            client_count += verification_form['result_count']
            pylogger.info("Broker-id: %s , Client count:%s" %
                          (broker['broker_id'],
                           verification_form['result_count']))

        result_dict = dict()
        result_dict['result_count'] = client_count
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

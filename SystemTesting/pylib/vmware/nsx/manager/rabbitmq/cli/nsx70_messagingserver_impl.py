import vmware.interfaces.messaging_server_interface\
    as messaging_server_interface
import vmware.schema.messaging.list_users_schema as list_users_schema
import vmware.schema.messaging.list_vhosts_schema as list_vhosts_schema
import vmware.schema.messaging.list_exchanges_schema as list_exchanges_schema
import vmware.schema.messaging.list_permissions_schema\
    as list_permissions_schema
import vmware.schema.messaging.list_queues_schema as list_queues_schema
import vmware.schema.messaging.list_user_permissions_schema\
    as list_user_permissions_schema
import vmware.schema.messaging.list_bindings_schema as list_bindings_schema
import vmware.schema.messaging.list_channels_schema as list_channels_schema
import vmware.schema.messaging.list_connections_schema\
    as list_connections_schema
import vmware.schema.messaging.list_consumers_schema as list_consumers_schema
import vmware.common.utilities as utilities
import vmware.common.global_config as global_config
pylogger = global_config.pylogger


class NSX70MessagingServerImpl(
        messaging_server_interface.MessagingServerInterface):

    @classmethod
    def get_users_list(cls, client_object, **kwargs):
        client_object.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "rabbitmqctl list_users"
        parser = "raw/listUsers"
        expect_prompt = ['bytes*', '#']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, parser, expect_prompt, ' ')

        schema_object = list_users_schema.ListUsersSchema(mapped_pydict)
        return schema_object

    @classmethod
    def get_vhosts_list(cls, client_object, **kwargs):
        client_object.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "rabbitmqctl list_vhosts"
        parser = "raw/listHosts"
        expect_prompt = ['bytes*', '#']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, parser, expect_prompt, ' ')

        schema_object = list_vhosts_schema.ListvHostsSchema(mapped_pydict)
        return schema_object

    @classmethod
    def get_user_permissions_list(cls, client_object, **kwargs):
        username = kwargs['get_user_permissions_list']['username']

        client_object.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "rabbitmqctl list_user_permissions %s" % username
        parser = "raw/listUserPermissions"
        expect_prompt = ['bytes*', '#']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, parser, expect_prompt, ' ')

        schema_object = list_user_permissions_schema.\
            ListUserPermissionsSchema(mapped_pydict)
        return schema_object

    @classmethod
    def get_permissions_list(cls, client_object, **kwargs):
        vhostpath = kwargs['get_permissions_list']['vhostpath']

        client_object.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "rabbitmqctl list_permissions -p %s" % vhostpath
        parser = "raw/listPermissions"
        expect_prompt = ['bytes*', '#']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, parser, expect_prompt, ' ')

        schema_object = list_permissions_schema.ListPermissionsSchema(
            mapped_pydict)
        return schema_object

    @classmethod
    def get_queues_list(cls, client_object, **kwargs):
        vhostpath = kwargs['get_queues_list']['vhostpath']
        client_object.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "rabbitmqctl list_queues -p %s" % vhostpath
        parser = "raw/listQueues"
        expect_prompt = ['bytes*', '#']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, parser, expect_prompt, ' ')

        schema_object = list_queues_schema.ListQueuesSchema(mapped_pydict)
        return schema_object

    @classmethod
    def get_exchanges_list(cls, client_object, **kwargs):
        vhostpath = kwargs['get_exchanges_list']['vhostpath']
        client_object.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "rabbitmqctl list_exchanges -p %s" % vhostpath
        parser = "raw/listExchanges"
        expect_prompt = ['bytes*', '#']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, parser, expect_prompt, ' ')

        schema_object = list_exchanges_schema.ListExchangesSchema(
            mapped_pydict)
        return schema_object

    @classmethod
    def get_bindings_list(cls, client_object, **kwargs):
        vhostpath = kwargs['get_bindings_list']['vhostpath']

        client_object.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "rabbitmqctl list_bindings -p %s" % vhostpath
        parser = "raw/listBindings"
        expect_prompt = ['bytes*', '#']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, parser, expect_prompt, ' ')

        schema_object = list_bindings_schema.ListBindingsSchema(mapped_pydict)
        return schema_object

    @classmethod
    def get_connections_list(cls, client_object, **kwargs):
        client_object.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "rabbitmqctl list_connections"
        parser = "raw/listConnections"
        expect_prompt = ['bytes*', '#']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, parser, expect_prompt, ' ')

        schema_object = list_connections_schema.ListConnectionsSchema(
            mapped_pydict)
        return schema_object

    @classmethod
    def get_channels_list(cls, client_object, **kwargs):
        client_object.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "rabbitmqctl list_channels"
        parser = "raw/listChannels"
        expect_prompt = ['bytes*', '#']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, parser, expect_prompt, ' ')

        schema_object = list_channels_schema.ListChannelsSchema(mapped_pydict)
        return schema_object

    @classmethod
    def get_consumers_list(cls, client_object, **kwargs):
        vhostpath = kwargs['get_consumers_list']['vhostpath']
        client_object.connection.login_to_st_en_terminal(expect=['#'])
        endpoint = "rabbitmqctl list_consumers -p %s" % vhostpath
        parser = "raw/listConsumers"
        expect_prompt = ['bytes*', '#']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, parser, expect_prompt, ' ')

        schema_object = list_consumers_schema.ListConsumersSchema(
            mapped_pydict)
        return schema_object

    @classmethod
    def stop(cls, client_object, **kwargs):
        client_object.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "rabbitmqctl stop_app"
        expect_prompt = ['bytes*', '#']

        client_object.connection.request(endpoint, expect_prompt)

        return None

    @classmethod
    def start(cls, client_object, **kwargs):
        client_object.connection.login_to_st_en_terminal(expect=['#'])

        endpoint = "rabbitmqctl start_app"
        expect_prompt = ['bytes*', '#']

        client_object.connection.request(endpoint, expect_prompt)

        return None
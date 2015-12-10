from vsm_ipset import IPSet
from vsm_ipset_schema import IPSetSchema


class RbacTests(object):
    def __init__(self, test_obj, super_admin_obj):
        """
        Base class for all endpoints
        This class does all CRUD operations
        Derived classes endpoint specific params
        @param test_obj: Eg. VSM(), Neutron(), etc used to instantiate client objects
        This object is with user for whom CRUD operations are to be tried
        @param super_admin_obj: Eg. VSM(), Neutron(), etc used to instantiate client objects
        This object is with super admin user privileges
        """
        self.test_obj = test_obj
        self.super_admin_obj = super_admin_obj
        self.client_class = None
        self.schema_class = None
        self.create_dict = None
        self.update_dict = None

    def find_result(self, result_obj):
        """
        Converts HTTP status codes into True/False
        @param result_obj: result object returned by CRUD operations
        """
        if result_obj.status_code != int(200) and \
                result_obj.status_code != int(201):
            return False
        return True

    def get_create_dict(self):
        raise NotImplementedError

    def get_update_dict(self):
        raise NotImplementedError

    def create(self, expected_result):
        """
        Tests create call with the user configured in - test_obj
        If create is successful deletes the object
        @param expected_result: Expected result as True or False indicating whether create
        operation should go through or not
        """
        return_value = False
        self.get_create_dict()
        if self.client_class is None or self.schema_class is None or self.create_dict is None:
            raise AttributeError
        client_obj = self.client_class(self.test_obj)
        schema_obj = self.schema_class(self.create_dict)
        result_obj = client_obj.create(schema_obj)
        result_create = self.find_result(result_obj)
        if result_create == expected_result:
            return_value = True
        if result_create is True:
            return_value = self.find_result(client_obj.delete())
        return return_value

    def update(self, expected_result):
        """
        Tests update operation with the user configured in - test_obj
        Creates the object with rights of super_admin
        Updates the object with test user
        Deletes the object with super_admin user
        @param expected_result: Expected result as True or False indicating whether create
        operation should go through or not
        """
        self.get_create_dict()
        if self.client_class is None or self.schema_class is None or self.create_dict is None:
            raise AttributeError
        client_obj = self.client_class(self.super_admin_obj)
        schema_obj = self.schema_class(self.create_dict)
        result_obj = client_obj.create(schema_obj)
        result = self.find_result(result_obj)
        if not result:
            return False

        self.get_update_dict()
        if self.update_dict is None:
            raise AttributeError
        client_update_obj = self.client_class(self.test_obj)
        client_update_obj.id = client_obj.id
        result_obj = client_update_obj.update(self.update_dict)
        result = self.find_result(result_obj)

        result_del = self.find_result(client_obj.delete())
        if result != expected_result or not result_del:
            return False
        return True

    def read(self, expected_result):
        """
        Tests read operation with the user configured in - test_obj
        Creates the object with rights of super_admin
        Reads the object with test user
        Deletes the object with super_admin user
        @param expected_result: Expected result as True or False indicating whether create
        operation should go through or not
        """
        self.get_create_dict()
        if self.client_class is None or self.schema_class is None or self.create_dict is None:
            raise AttributeError
        client_obj = self.client_class(self.super_admin_obj)
        schema_obj = self.schema_class(self.create_dict)
        result_obj = client_obj.create(schema_obj)
        result = self.find_result(result_obj)
        if not result:
            return False

        client_read_obj = self.client_class(self.test_obj)
        client_read_obj.id = client_obj.id
        if client_read_obj.read() is not None:
            result = True

        result_del = self.find_result(client_obj.delete())
        if result != expected_result or not result_del:
            return False

        return True

    def delete(self, expected_result):
        """
        Tests delete operation with the user configured in - test_obj
        Creates the object with rights of super_admin
        Deletes the object with test user
        @param expected_result: Expected result as True or False indicating whether create
        operation should go through or not
        """
        self.get_create_dict()
        if self.client_class is None or self.schema_class is None or self.create_dict is None:
            raise AttributeError
        client_obj = self.client_class(self.super_admin_obj)
        schema_obj = self.schema_class(self.create_dict)
        result_obj = client_obj.create(schema_obj)
        result = self.find_result(result_obj)
        if not result:
            return False

        client_delete_obj = self.client_class(self.test_obj)
        client_delete_obj.id = client_obj.id
        result_obj = client_delete_obj.delete()
        result = self.find_result(result_obj)

        if not result:
            result_obj = client_obj.delete()
        if expected_result != result and not self.find_result(result_obj):
            return False
        return True


class IPSetRbacTests(RbacTests):
    def __init__(self, test_obj, super_admin_obj):
        """
        Class that does IPSet operations
        @param test_obj: Eg. VSM(), Neutron(), etc used to instantiate client objects
        This object is with user for whom CRUD operations are to be tried
        @param super_admin_obj: Eg. VSM(), Neutron(), etc used to instantiate client objects
        This object is with super admin user privileges
        @return:
        """
        super(IPSetRbacTests, self).__init__(test_obj, super_admin_obj)
        self.client_class = IPSet
        self.schema_class = IPSetSchema

    def get_create_dict(self):
        """
        Fills in attributes required by base class to fire create() call
        """
        self.create_dict = {'name': 'ipset-auto-1', 'value': '192.168.1.1', 'description': 'Test'}

    def get_update_dict(self):
        """
        Fills in attributes required by base class to fire update() call
        """
        self.update_dict = {'name': 'ipset-auto-1', 'value': '192.168.1.2', 'description': 'Test'}

import yaml
import importlib
from vmware.common.global_config import pylogger

from vsm import VSM

class RbacTestDriver():
    """
    Class to kick start RBAC tests
    """
    def __init__(self, rbac_tests):
        """
        @param rbac_tests: Dict that has information about users,
         endpoints, effective_roles and entity on which the tests
          are to be carried out
        @return:
        """
        self.rbac_tests = rbac_tests
        self.endpoint_actions = EndpointActions(rbac_tests['entity']['ip'])

    def verify_endpoint_authentication(self):
        """
        Funtion to start RBAC tests
        """
        for endpoint in self.rbac_tests['endpoints']:
            for user in self.rbac_tests['users']:
                pylogger.info("Tests for User: %s, Endpoint: %s" % (user['name'], endpoint))
                effective_role = self.get_effective_role(user)
                self.endpoint_actions.endpoint_check(endpoint,
                                                     user['name'],
                                                     user['password'],
                                                     effective_role)
    def get_effective_role(self, user):
        """
        Function that finds out effective role user has got
        @param user: user info whose effective role has to be found
        @return:
        """
        for user_info in self.rbac_tests['effective_roles']:
            if user_info['user'] == user['name']:
                return user_info['role']


class EndpointActions():
    def __init__(self, entity):
        """
        Class that does the actual calling of CRUD operations on endpoints
        @param entity: IP address of the entity on which the tests are to
        be carried out
        @return:
        """
        self.test_device = entity
        rules_stream = open('../../../../VDNetLib/TestData/rbac/rbac_rules.yaml')
        self.rules_dict = yaml.load(rules_stream)
        self.helper_object = None

    def check_for_privileges(self, action, expected_result):
        result = getattr(self.helper_object, action)(expected_result)
        return result

    def endpoint_check(self, endpoint, username, password, effective_role):
        """
        Fn that iterates through the rules dict and calls fns to verify
        privileges on each endpoint
        @param endpoint: e.g. IPSet, MACSet
        @param username: username for whom the privileges are checked
        @param password: password of the user
        @param effective_role: effective role the user has got
        """
        vsm = VSM(self.test_device, username, password, '')
        vsm_super_admin = VSM(self.test_device, 'root', 'vmware', '')

        class_name = endpoint + 'RbacTests'
        rbac_helper_module = importlib.import_module('rbac_tests_helper')
        loaded_helper_class = getattr(rbac_helper_module, class_name)
        self.helper_object = loaded_helper_class(vsm, vsm_super_admin)

        for action in self.rules_dict['rules'][endpoint][effective_role]['allowed_privileges']:
            if action != 'None':
                result = self.check_for_privileges(action, True)
                log_message = "Endpoint: {}, Effective Role: {}, Action: {}, ".format(endpoint, effective_role, action)
                log_message += "Username: {}, Result: {}".format(username, "Pass" if result is True else "Fail")
                pylogger.info(log_message)

        for action in self.rules_dict['rules'][endpoint][effective_role]['denied_privileges']:
            if action != 'None':
                result = self.check_for_privileges(action, False)
                log_message = "Endpoint: {}, Effective Role: {}, Action: {}, ".format(endpoint, effective_role, action)
                log_message += "Username: {}, Result: {}".format(username, "Pass" if result is True else "Fail")
                pylogger.info(log_message)


if __name__ == "__main__":
    rbac_tests = {
        'users': [{'name': 'auditor-1@vsphere.local', 'password': 'ca$hc0w', 'auth_server': 'radius', 'role': 'auditor'},
                  {'name': 'enter-admin-1@vsphere.local', 'password': 'ca$hc0w', 'auth_server': 'tacacs',
                   'role': 'enterprise_admin'}],
        'endpoints': ['IPSet'],
        'effective_roles': [{'user': 'enter-admin-1@vsphere.local', 'role': 'enterprise_admin'},
                            {'user': 'auditor-1@vsphere.local', 'role': 'auditor'}],
        'entity': {'ip': '10.110.29.222'}
    }
    rbac_driver = RbacTestDriver(rbac_tests)
    rbac_driver.verify_endpoint_authentication()


class Node(object):
    def __init__(self, py_dict):
        ''' Constructor for node class

            @param py_dict containing controlip, username, password, os, arch, testip
        '''
        if 'controlip' in py_dict.keys():
           self._controlip = py_dict['controlip']
        if 'username' in py_dict.keys():
           self._username = py_dict['username']
        if 'password' in py_dict.keys():
           self._password = py_dict['password']
        if 'os' in py_dict.keys():
           self._os = py_dict['os']
        if 'arch' in py_dict.keys():
           self._arch = py_dict['arch']
        if 'testip' in py_dict.keys():
           self._testip = py_dict['testip']

    @property
    def os(self):
        return self._os

    @property
    def arch(self):
        return self._arch

    @property
    def controlip(self):
        return self._controlip

    @property
    def username(self):
        return self._username

    @property
    def password(self):
        return self._password

    @property
    def testip(self):
        return self._testip

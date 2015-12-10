class Connection(object):

    def __init__(self, ip="", username="", password="", root_password="",
                 connection_object=None):
        if connection_object is None:
            self.ip = ip
            self.username = username
            self.password = password
            self.root_password = root_password
        else:
            self.ip = connection_object.ip
            self.username = connection_object.username
            self.password = connection_object.password
            self.root_password = connection_object.root_password
        self._anchor = None

    @property
    def anchor(self):
        return self._anchor

    @anchor.setter
    def anchor(self, value):
        self._anchor = value

    def create_connection(self):
        pass

    def initialize(self):
        pass

    def request(self, object, method, spec):
        pass

    def async_request(self, object, method, spec):
        pass

    def refresh(self):
        self.anchor = self.create_connection()

    def prepare_to_serialize(self):
        self.anchor = None

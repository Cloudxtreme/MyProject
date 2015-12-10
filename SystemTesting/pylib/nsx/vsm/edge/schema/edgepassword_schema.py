import base_schema
from edgepassword_parser import EdgePasswordParser

class EdgePasswordSchema(base_schema.BaseSchema):
    _schema_name = "EdgePasswordSchema"
    # Select the parser appropriate for the stdout related to this command
    _parser = EdgePasswordParser()

    def __init__(self, py_dict=None):
        """ Constructor to create EdgePasswordSchema object
        """
        super(EdgePasswordSchema, self).__init__()
        self.table = [EdgePasswordEntrySchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

    def set_data_raw(self, raw_payload):
        """ Convert raw data to py_dict based on the class parser and assign the py_dict to class element so that
        get_object_from_py_dict() can take it from there.

        @param raw_payload raw string from which python objects are constructed after parsing the string
        """

        payload = self._parser.get_parsed_data(raw_payload)
        py_dict = {'table': payload}
        self.get_object_from_py_dict(py_dict)
        return

class EdgePasswordEntrySchema(base_schema.BaseSchema):
    _schema_name = "EdgePasswordEntrySchema"
    def __init__(self, py_dict=None):
        """ Constructor to create EdgePasswordEntrySchema object
        """
        super(EdgePasswordEntrySchema, self).__init__()
        """
        values of the attributes are the strings which stdout uses to dump data because stdout uses stuff like
        Connection-ID we cannot have same attributes as an attribute cannot have '-' in it
        """

        self.password = None
        self.edge = None

if __name__ == '__main__':
    input = """
        Edge root password:
            edge-32 -> NcoSBAE682@fg7
            edge-33 -> zQyHv41^BGFYt
    """
    schema = EdgePasswordSchema()
    schema.set_data_raw(input)

    edge_entry_list = schema.table

    if (len(edge_entry_list) == 0):
        print"FAILURE"
        exit()

    for i in range(len(edge_entry_list)):
        edgeID = edge_entry_list[i].edge
        edgePassword = edge_entry_list[i].password
        print "EdgeID = %s and EdgePassword = %s" % (edgeID, edgePassword)

    input = """
        Edge root password:
         No Edge is deployed so far
     """
    schema = EdgePasswordSchema()
    schema.set_data_raw(input)

    edge_entry_list = schema.table
    if (len(edge_entry_list) == 0):
        print"FAILURE"
        exit()

    edgeID = edge_entry_list[0].edge
    edgePassword = edge_entry_list[0].password

    print "EdgeID = %s and EdgePassword = %s" % (edgeID, edgePassword)


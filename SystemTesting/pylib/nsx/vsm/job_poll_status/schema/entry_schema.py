import base_schema


class EntrySchema(base_schema.BaseSchema):
   _schema_name = "entry"
   def __init__(self, py_dict=None):
      """ Constructor to create EntrySchema object

      @param py_dict : python dictionary to construct this object
      """
      super(EntrySchema, self).__init__()
      self.string = [str()]

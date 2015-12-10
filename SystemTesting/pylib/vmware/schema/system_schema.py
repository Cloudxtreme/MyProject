import vmware.common.base_schema as base_schema


class SystemSchema(base_schema.BaseSchema):
    _schema_name = "SystemSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create SystemSchema object
        """
        super(SystemSchema, self).__init__()
        self.memory_total = None
        self.swap_total = None
        self.memory_total = None
        self.swap_total = None
        self.total_cpus = None
        self.sda2_size = None
        self.tmpfs_size = None
        self.sda6_size = None
        self.sda8_size = None
        self.packets_received = None
        self.packets_sent = None
        self.valid_up_time = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

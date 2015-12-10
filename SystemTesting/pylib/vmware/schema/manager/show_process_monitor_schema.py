import vmware.common.base_schema as base_schema


class ShowProcessMonitorSchema(base_schema.BaseSchema):
    _schema_name = "ShowProcessMonitorSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create ShowProcessMonitorSchema object
        """
        super(ShowProcessMonitorSchema, self).__init__()
        self.tasks = TaskSchema()
        self.cpu = CpuSchema()
        self.mem = MemSchema()
        self.swap = SwapSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class TaskSchema(base_schema.BaseSchema):
    _schema_name = "TaskSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create TaskSchema object
        """
        super(TaskSchema, self).__init__()
        self.stopped = None
        self.zombie = None
        self.sleeping = None
        self.running = None
        self.total = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class CpuSchema(base_schema.BaseSchema):
    _schema_name = "CpuSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create CpuSchema object
        """
        super(CpuSchema, self).__init__()
        self.si = None
        self.hi = None
        self.st = None
        self.sy = None
        self.us = None
        self.id = None
        self.ni = None
        self.wa = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class SwapSchema(base_schema.BaseSchema):
    _schema_name = "SwapSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create SwapSchema object
        """
        super(SwapSchema, self).__init__()
        self.free = None
        self.used = None
        self.total = None
        self.cached = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class MemSchema(base_schema.BaseSchema):
    _schema_name = "MemSchema"

    def __init__(self, py_dict=None):
        """ Constructor to create MemSchema object
        """
        super(MemSchema, self).__init__()
        self.free = None
        self.used = None
        self.total = None
        self.buffers = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

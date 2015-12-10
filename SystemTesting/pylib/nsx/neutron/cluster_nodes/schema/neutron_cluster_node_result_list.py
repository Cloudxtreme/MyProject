import base_schema
from node_config_schema import NodeConfigSchema

class ResultList(base_schema.BaseSchema):
    def __init__(self):
        super(ResultList, self).__init__()
        self.results = [NodeConfigSchema()]
        self.result_count = None

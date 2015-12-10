import neutron_client
import vmware.common.logger as logger
from logical_pipeline_stage_schema import LogicalPipelineStageSchema

class LogicalPipelineStage(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create LogicalPipelineStage object

        @param neutron object on which LogicalPipelineStage object has to be configured
        """
        super(LogicalPipelineStage, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'logical_pipeline_stage_schema.LogicalPipelineStageSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/pipeline-stages')
        self.id = None


if __name__ == '__main__':
    pass
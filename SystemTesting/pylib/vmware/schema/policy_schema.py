import vmware.common.base_schema as base_schema


class PolicySchema(base_schema.BaseSchema):

    def __init__(self, policy_id=None, policy_option_id=None,
                 parameter_keys=None, parameter_values=None,
                 array=None, property_name=None, subprofile=None,
                 network_device=None):
        """
        Schema object attributes

        @type policy_id: str
        @param policy_id: ID of the policy
        @type policy_option_id: str
        @param policy_option_id: ID of the policy option
        @type parameter_keys: str
        @param parameter_keys: Key of the parameter in the policy option
        @type parameter_values: -
        @param parameter_values: Value corresponding to the parameter_key
        @type array: bool
        @param array: Indicates if the property is an array of profiles
        @type property_name: str
        @param property_name: Property name
        @type subprofile: bool
        @param subprofile: Flag to specify if subprofile exists
        @type network_device: str
        @param network_device: Name of the network device whose policy is
            to be changed. Eg vSwitch0

        @rtype: PolicySchema instance
        @return: Policy schema object
        """
        self.policy_id = policy_id
        self.policy_option_id = policy_option_id
        self.parameter_keys = parameter_keys
        self.parameter_values = parameter_values
        self.array = array
        self.property_name = property_name
        self.subprofile = subprofile
        self.network_device = network_device

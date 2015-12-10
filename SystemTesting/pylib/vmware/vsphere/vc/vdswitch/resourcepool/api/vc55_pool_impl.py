import vmware.interfaces.pool_interface as pool_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.global_config as global_config

import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger
ADD = "add"
UPDATE = "update"


class VC55PoolImpl(pool_interface.PoolInterface):

    @classmethod
    def configure_network_resource_pool(
            cls, client_object, shares=None, shares_level=None,
            limit=None, priority_tag=None, config_version=None,
            description=None, key=None, operation=None):
        """
        Updates a virtual NIC network resource pool.

        @type client_object: ResourcePoolAPIClient instance
        @param client_object: ResourcePoolAPIClient instance
        @type shares_level: str
        @param shares_level: The allocation level. The level is a
            simplified view of shares. Levels map to a pre-determined
            set of numeric values for shares. If the shares value does
            not map to a predefined size, then the level is set as
            custom. Can be custom, high, low, or normal.
        @type shares: int
        @parem shares: he number of shares allocated. Used to determine
            resource allocation in case of resource contention. This value
            is only set if level is set to custom. If level is not set to
            custom, this value is ignored. Therefore, only shares with
            custom values can be compared.
        @type limit: long
        @param limit: Maximum allowed usage for network clients belonging
            to this resource pool per host.
        @type priority_tag: int
        @param priority_tag: 802.1p tag to be used for this resource pool.
            The tag is a priority value in the range 0..7 for Quality of
            Service operations on network traffic.
        @type config_version: str
        @param config_version: The configVersion is a unique identifier
            for a given version of the configuration. Each change to the
            configuration will update this value. This is typically
            implemented as a non-decreasing count or a time-stamp.
            However, a client should always treat this as an opaque
            string. If specified when updating the resource configuration,
            the changes will only be applied if the current configVersion
            matches the specified configVersion. This field can be used
            to guard against updates that that may have occurred between
            the time when configVersion was read and when it is applied.
        @type key: str
        @param key: The key of the network resource pool. The property is
            ignored for add operations
        @type operation: str
        @param operation: add, or update

        @rtype: NoneType
        @return: None
        """
        vds_mor = client_object.parent.vds_mor
        spec = client_object.get_network_resource_pool_spec(
            shares=shares, shares_level=shares_level,
            limit=limit, priority_tag=priority_tag,
            config_version=config_version, description=description,
            key=key, name=client_object.name)
        if operation == UPDATE:
            if spec.configVersion is None:
                for pool in vds_mor.networkResourcePool:
                    if pool.key == key:
                        spec.configVersion = pool.configVersion
            vds_mor.UpdateNetworkResourcePool([spec])
        elif operation == ADD:
            vds_mor.AddNetworkResourcePool([spec])

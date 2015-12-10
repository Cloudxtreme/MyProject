import copy
import inspect
import importlib
import string
import types
from xml.etree import ElementTree
from xml.etree.ElementTree import Element
from xml.etree.ElementTree import SubElement


class XmlParser(object):

    _xml_tag_exception = {'appliances_schema.AppliancesSchema':
                              {'appliance': None},
                          'nw_fabric_feature_config_schema.NwFabricFeatureConfigSchema':
                              {'resourceConfig': None},
                          'job_instances_schema.JobInstancesSchema':
                              {'jobInstances': None},
                          'interfaces_schema.InterfacesSchema':
                              {'interfaces': None},
                          'vnics_schema.VnicsSchema':
                              {'vnics': None},
                          'vdn_scopes_schema.VDNScopesSchema':
                              {'vdnScope': None},
                          'address_group_schema.AddressGroupSchema':
                              {'addressGroups': None},
                          'bridges_schema.BridgesSchema':
                              {'bridges': None},
                          'vxlan_controllers_schema.VXLANControllersSchema':
                              {'controller': None},
                          'tor_gateways_schema.TORGatewaysSchema':
                              {'tor': None},
                          'tor_gateway_switches_schema.TORGatewaySwitchesSchema':
                              {'torswitch': None},
                          'tor_gateway_switch_ports_schema.TORGatewaySwitchPortsSchema':
                              {'torswitchport': None},
                          'tor_gateway_bindings_schema.TORGatewayBindingsSchema':
                              {'binding': None},
                          'ptep_cluster_schema.PTEPClusterSchema':
                              {'basicinfo': None},
                          'clusters_schema.ClustersSchema':
                              {'cluster': None},
                          'dummy_cluster_schema.DummyClusterSchema':
                              {'cluster': None},
                          'data_page_schema.DataPageSchema':
                              {'list_schema': None, 'systemEvent' : None},
                          'deployment_container_schema.DeploymentContainerSchema':
                              {'keyValueArray': None, 'containerattributes': None},
                          'virtual_wire_schema.VirtualWireSchema':
                              {'vdsContextWithBacking': None},
                          'service_instances_schema.ServiceInstancesSchema':
                              {'serviceInstanceArray': None},
                          'service_profiles_schema.ServiceProfilesSchema':
                              {'serviceProfileArray': None},
                          'deployed_services_status_schema.DeployedServicesStatusSchema':
                              {'deployedServicesArray': None},
                          'cluster_deployment_configs_schema.ClusterDeploymentConfigsSchema':
                              {'clusterDeploymentConfigArray': None},
                          'typed_attributes_schema.TypedAttributesSchema':
                              {'typedAttributes': None},
                          'edge_load_balancer_global_service_instance_schema.LoadBalancerGlobalServiceInstanceSchema':
                              {'runtimenicinfoarray': None},
                          'edge_load_balancer_pool_schema.LoadBalancerPoolSchema':
                              {'memberArray': None},
                          'vsm_ipsets_schema.IPSetsSchema':
                              {'list': None},
                          'list_schema.ListSchema':
                              {'list_object': None},
                          'vmknics_schema.VmknicsSchema':
                              {'vmknics': None},
                          'nsx_upgrade_schema.NSXUpgradeSchema':
                              {'preUpgradeQuestionsAnswerArray': None},
                          'edge_page_schema.EdgePageSchema':
                              {'list_schema': None},
                          'security_group_schema.SecurityGroupSchema':
                              {'member': None, 'excludeMember': None},
                          'security_group_dynamic_member_definition_schema.SecurityGroupDynamicMemberDefinitionSchema':
                              {'dynamicSet': None},
                          'security_group_dynamic_set_schema.SecurityGroupDynamicSetSchema':
                              {'dynamicCriteria': None},
                          'layer3_redirect_sections_schema.Layer3RedirectSectionsSchema':
                              {'section' : None},
                          'layer3_sections_schema.Layer3SectionsSchema':
                              {'section' : None},
                          'layer2_sections_schema.Layer2SectionsSchema':
                              {'section' : None},
                          'section_schema.SectionSchema':
                              {'rule' : None},
                          'sources_schema.SourcesSchema':
                              {'source' : None},
                          'services_schema.ServicesSchema':
                              {'service' : None},
                          'applied_to_list_schema.AppliedToListSchema':
                              {'appliedTo' : None},
                          'destinations_schema.DestinationsSchema':
                              {'destination' : None},
                          'ipfix_configuration_schema.IpfixConfigurationSchema':
                              {'collector' : None},
                          'rule_schema.RulesSchema':
                              {'fromprotocol' : None},
                          'edge_load_balancer_schema.LoadBalancerSchema':
                              {
                                  'applicationRule': None,
                                  'virtualServer': None,
                                  'pool': None,
                                  'monitor': None,
                                  'member': None
                              },
                          'relay_agents_schema.RelayAgentsSchema':
                              {'relayAgent': None},
                          'certificates_schema.CertificatesSchema':
                              {'list': None},
                          'edge_firewall_default_policy_schema.FirewallDefaultPolicySchema':
                              {'defaultPolicy': None},
                          'edge_firewall_global_config_schema.FirewallGlobalConfigSchema':
                               {'globalConfig': None},
                          'edge_firewall_rule_source_schema.FirewallRuleSourceSchema':
                              {'groupingObjectId': None},
                          'edge_firewall_rule_destination_schema.FirewallRuleDestinationSchema':
                              {'groupingObjectId': None},
                          'vsm_ip_nodes_schema.IPNodesSchema':
                              {'ipNode': None},
                          'vsm_ip_node_schema.IPNodeSchema':
                              {'ipAddresses': None},
                          'vsm_mac_nodes_schema.MACNodesSchema':
                              {'macNode': None},
                          }

    def __init__(self):
        pass

    def set_data(self, schema_object, payload):
        """ Populates python objects with provided xml string

        @param payload xml string from which python objects are constructed
        """
        # if the namespace attribute is given to ElementTree
        # it messes up all .find() results - hence changing the root attribute
        payload = payload.replace("xmlns", "xmlnamespace")
        root = ElementTree.fromstring(payload)
        self._populate_class_elements(root, schema_object)
        return

    def get_data(self, schema_object):
        """ Generates xml string with empty tags from python objects
        """
        cls_name = self._get_schema_name_from_class(str(schema_object.__class__))
        root = Element(cls_name)
        self._append_class_elements(root, schema_object)
        return ElementTree.tostring(root)

    def get_data_without_empty_tags(self, schema_object):
        """ Generates xml string from python objects
        """
        cls_name = self._get_schema_name_from_class(str(schema_object.__class__))
        root = Element(cls_name)
        self._append_class_elements_without_empty_tags(root, schema_object)
        return ElementTree.tostring(root)

    def _append_class_elements(self, xmlNode, object):
        at_array = [str, int, unicode, bool]
        fields = inspect.getmembers(object)
        try:
            attribute_name = getattr(object, '_attributeName')
            attribute_value = getattr(object, '_attributeValue')
            xmlNode.attrib[attribute_name] = attribute_value
        except:
            pass
        for field in fields:
            # Do not process if attribute name starts with _ , unless its _tag_
            if not callable(field[1]) and (field[0].startswith('_tag_') or not field[0].startswith('_')):
                value = getattr(object, field[0])
                if not callable(value) and type(value) != types.MethodType \
                        and field[1] is not None and field[1] is not "":

                    if type(value) in at_array and field[1] is not None:
                        # If attribute name starts with _tag_ set it as tag attribute in xml
                        if field[0].startswith('_tag_'):
                            attrib_name = string.split(field[0],"_",2)[2]
                            xmlNode.attrib[attrib_name] = str(value)
                        else:
                            elem = SubElement(xmlNode, field[0])
                            elem.text = str(getattr(object, field[0]))

                    elif type(value) is list and len(value) > 0:
                        # If it is list of objects then we need xml to be like
                        # <addressGroups> <addressGroup>
                        # <primaryAddress>192.168.1.100</primaryAddress>
                        #</addressGroup> </addressGroups>
                        # if it is normal list then xml is like
                        # <listOfIPs>1.1.1.1</listOfIPs> <listOfIPs>1.1.1.2</listOfIPs>
                        if type(value[0]) not in at_array:
                            # This function call will check whether
                            # there is any special handling
                            # for the current tag to be generated
                            tag_name = self._check_for_xml__tag_exceptions(object, field[0])
                            if tag_name is not None:
                                child = SubElement(xmlNode, tag_name)
                            else:
                                child = xmlNode
                                # We start taking from 2nd element of the list since the first
                                # element is used for initialisation
                        for i in range(0, len(value)):
                            if type(value[i]) in at_array:
                                elem = SubElement(xmlNode, field[0])
                                elem.text = str(value[i])
                            else:
                                cls_name = self._get_schema_name_from_class(str(value[i].__class__))
                                insChild = SubElement(child, cls_name)
                                self._append_class_elements(insChild, value[i])
                    elif type(value) is not list:
                        cls_name = self._get_schema_name_from_class(str(field[1].__class__))
                        child = SubElement(xmlNode, cls_name)
                        self._append_class_elements(child, field[1])
        return

    def _append_class_elements_without_empty_tags(self, xmlNode, object):
        at_array = [str, int, unicode, bool]
        fields = inspect.getmembers(object)
        is_xml_node_empty = True
        try:
            attribute_name = getattr(object, '_attributeName')
            attribute_value = getattr(object, '_attributeValue')
            xmlNode.attrib[attribute_name] = attribute_value
        except:
            pass
        for field in fields:
            # Do not process if attribute name starts with _ , unless its _tag_
            if not callable(field[1]) and (field[0].startswith('_tag_') or not field[0].startswith('_')):
                value = getattr(object, field[0])
                if not callable(value) and type(value) != types.MethodType \
                        and field[1] is not None and field[1] is not "":

                    if type(value) in at_array and field[1] is not None:
                        # If attribute name starts with _tag_ set it as tag attribute in xml
                        if field[0].startswith('_tag_'):
                           attrib_name = string.split(field[0],"_",2)[2]
                           xmlNode.attrib[attrib_name] = str(value)
                        else:
                           elem = SubElement(xmlNode, field[0])
                           elem.text = str(getattr(object, field[0]))
                           is_xml_node_empty = False

                    elif type(value) is list and len(value) > 0:
                        # If it is list of objects then we need xml to be like
                        # <addressGroups> <addressGroup>
                        # <primaryAddress>192.168.1.100</primaryAddress>
                        #</addressGroup> </addressGroups>
                        # if it is normal list then xml is like
                        # <listOfIPs>1.1.1.1</listOfIPs> <listOfIPs>1.1.1.2</listOfIPs>
                        if type(value[0]) not in at_array:
                            # This function call will check whether
                            # there is any special handling
                            # for the current tag to be generated
                            tag_name = self._check_for_xml__tag_exceptions(object, field[0])
                            if tag_name is not None:
                                child = SubElement(xmlNode, tag_name)
                            else:
                                child = xmlNode
                                # We start taking from 2nd element of the list since the first
                                # element is used for initialisation
                        for i in range(0, len(value)):
                            if type(value[i]) in at_array:
                                elem = SubElement(xmlNode, field[0])
                                elem.text = str(value[i])
                                is_xml_node_empty = False
                            else:
                                cls_name = self._get_schema_name_from_class(str(value[i].__class__))
                                insChild = SubElement(child, cls_name)
                                if self._append_class_elements_without_empty_tags(insChild, value[i]):
                                    child.remove(insChild)
                                else:
                                    is_xml_node_empty = False
                    elif type(value) is not list:
                        cls_name = self._get_schema_name_from_class(str(field[1].__class__))
                        child = SubElement(xmlNode, cls_name)
                        if self._append_class_elements_without_empty_tags(child, field[1]):
                            xmlNode.remove(child)
                        else:
                            is_xml_node_empty = False
        return is_xml_node_empty

    def _populate_class_elements(self, xmlNode, className):
        fields = inspect.getmembers(className)
        at_array = [str, int, unicode, bool]
        for field in fields:
            # Do not process if attribute name starts with _ , unless its _tag_
            if not callable(field[1]) and (field[0].startswith('_tag_') or not field[0].startswith('_')):

                if type(field[1]) in at_array or type(field[1]) is types.NoneType:
                    # If attribute name starts with _tag_ set it as tag attribute in xml
                    if field[0].startswith('_tag_'):
                        attribute = string.split(field[0],"_",2)[2]
                        if xmlNode.get(attribute) is not None:
                            setattr(className, field[0], xmlNode.attrib[attribute])
                    elif xmlNode.find(field[0]) is not None:
                        setattr(className, field[0], xmlNode.find(field[0]).text)

                elif type(field[1]) is types.ListType:
                    tag_name = self._check_for_xml__tag_exceptions(className, field[0])
                    if tag_name is None:
                        tag_name = self._get_schema_name_from_class(str(field[1][0].__class__))
                    else:
                        tag_name = field[0]

                    field_name = field[0]
                    if xmlNode.find(tag_name) is not None:
                        list_nodes = xmlNode.findall(tag_name)
                        obj = field[1][0]
                        obj_list = []
                        for node in list_nodes:
                            if node.text:
                                obj = node.text
                                obj_list.append(obj)
                                #This is a hack for missing list name xml tag in edge DTO
                            elif (node.tag == self._get_schema_name_from_class(str(field[1][0].__class__)) and
                                    self._check_for_xml__tag_exceptions(className, field[0]) is None):
                                copy_obj = copy.deepcopy(obj)
                                self._populate_class_elements(node, copy_obj)
                                obj_list.append(copy_obj)
                            else:
                                for child in node:
                                    copy_obj = copy.deepcopy(obj)
                                    self._populate_class_elements(child, copy_obj)
                                    obj_list.append(copy_obj)
                        setattr(className, field_name, obj_list)

                else:
                    clsName = self._get_schema_name_from_class(str(field[1].__class__))
                    node = xmlNode.find(clsName)
                    if node is not None:
                        self._populate_class_elements(node, field[1])
        return

    def _check_for_xml__tag_exceptions(self, class_name, field_name):
        for class_name_keys in XmlParser._xml_tag_exception:
            if self._get_class_name(str(class_name)) in class_name_keys:
                for field_name_keys in XmlParser._xml_tag_exception[class_name_keys]:
                    if field_name in field_name_keys:
                        return XmlParser._xml_tag_exception[class_name_keys][field_name]
        return field_name

    def _get_class_name(self, class_name_str):
        module, class_name = class_name_str.split('.')
        class_name = class_name.split("Schema")[0]
        class_name += "Schema"
        return class_name

    def _get_schema_name_from_class(self, class_name_str):
        module, class_name = class_name_str.split('.')
        module = module.lstrip("<'")
        module = module.replace("class", "")
        module = module.lstrip(" '")
        class_name = class_name.split("Schema")[0]
        class_name += "Schema"
        some_module = importlib.import_module(module)
        loaded_schema_class = getattr(some_module, class_name)
        return loaded_schema_class._schema_name

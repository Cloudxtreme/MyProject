/*
 * ************************************************************************
 *
 * Copyright 2004-2014 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa;

import static com.vmware.vcqa.TestConstants.TESTINPUT_PORT;

import java.net.InetAddress;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import javax.xml.parsers.ParserConfigurationException;

import org.apache.commons.configuration.Configuration;
import org.apache.commons.configuration.ConfigurationUtils;
import org.apache.commons.configuration.HierarchicalConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import com.vmware.vcqa.TestConstants.VC_DEPLOYMENT_TYPE;
import com.vmware.vcqa.execution.TestDataHandler;
import com.vmware.vcqa.execution.TestbedInfoJsonParser;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.XMLUtil;

/**
 * TestInputHandler is the class which handles input data for the test and has
 * utility methods to parse test inputs and initialize test attributes
 */
public class TestInputHandler
{
   private static final Logger log = LoggerFactory.getLogger(TestInputHandler.class);
   private static final String MULTI_SERVICE_INFO_XML_XSD = "/service.xsd";
   private static HierarchicalConfiguration data = null;

   /**
    * Loads the data object with test inputs This method should be called before
    * calling the life cycle methods like testSetUp(), test(), testCleanUp()<br>
    * <br>If test data contains path to XML configuration file, test data objects
    * are modified to add/overwrite username, password, hostname and port from the first
    * {@code ServiceInfo} object
    *
    * @param testBase the test object.
    * @param testData input data passed to the test
    * @throws Exception if any problem occurs while initializing the test data
    *            object.
    */
   public static synchronized void initialize(TestBase testBase,
                                 final HierarchicalConfiguration testData)
      throws Exception
   {
      data = testData;
      log.info(testBase.getClass().getName() + ": Init Data: "
               + ConfigurationUtils.toString(data).replace("\r\n", " | ").replace("\n", "|"));
      log.debug("Loading test data... ");

      /*
       * Handle HTTP tunneling request
       */
      if ( Boolean.valueOf( testData.getString(TestConstants.USE_HTTP_TUNNELING_PARAM, Boolean.FALSE.toString()) ) ){
         testBase.setHTTPTunnelingProp(true);
      }

      List<ServiceInfo> serviceInfoList = getServiceInfo(testData);

      /*
       * Use the copy constructor to create a copy of the list, so we preserve
       * the order of the serviceinfo objects.
       */
      List<ServiceInfo> serviceInfoListCopy = new ArrayList<ServiceInfo>(serviceInfoList);
      testBase.addServiceInfoList(serviceInfoListCopy);
      testBase.setConnectAnchor((ConnectAnchor)testBase
                  .getServiceInfoList(TestConstants.VC_EXTENSION_KEY).get(0).getConnectAnchor());

   }

   /**
    * Get the list of ServiceInfo for existing connection
    *
    * @return List<ServiceInfo>    List of ServiceInfo.
    * @throws Exception
    */
   public static synchronized List<ServiceInfo> getServiceInfo()
   throws Exception
   {
      return getServiceInfo(data);
   }

   /**
    * Gets List of ServiceInfo items by extension key
    *
    * @return List<ServiceInfo> List of ServiceInfo.
    * @throws Exception
    */
   public static synchronized List<ServiceInfo> getServiceInfo(String extensionKey)
      throws Exception
   {
      List<ServiceInfo> allServiceInfoList = getServiceInfo(data);
      List<ServiceInfo> selectedServiceInfoList = new ArrayList<ServiceInfo>();
      for (ServiceInfo serviceInfo : allServiceInfoList) {
         if (extensionKey.equals(serviceInfo.getExtensionKey())) {
            selectedServiceInfoList.add(serviceInfo);
         }
      }
      return selectedServiceInfoList;
   }

   /**
    * Query a string value from the data
    *
    * @param key
    * @return
    */
   public static String getStringFromData(String key)
   {
      if (data == null)
         return null;
      return data.getString(key);
   }

   /**
    * add a new property to the data
    *
    * @param key
    * @param value
    */
   public static void addConfigurationData(String key,
                                           String value)
   {
      if (data == null) {
         data = new HierarchicalConfiguration();
      }

      data.addProperty(key, value);
   }

   /**
    * Gets the ServiceInfo list based on the configuration data<br>
    * <br>
    * If test data contains path to XML configuration file, test data objects
    * are modified to add/overwrite username, password, hostname and port from
    * the first {@code ServiceInfo} object
    *
    * @param testData input data passed to the test
    * @throws Exception if any problem occurs while initializing the test data
    *            object.
    */
   public static synchronized List<ServiceInfo> getServiceInfo(final HierarchicalConfiguration testData)
      throws Exception
   {
      HierarchicalConfiguration data = testData;
      String xmlFile = data.getString(TestConstants.TESTINPUT_XML);
      String testbedInfoJsonFile = data.getString(TestConstants.TESTINPUT_TESTBEDINFOJSONFILE, null);
      List<ServiceInfo> serviceInfoList = null;

      if (xmlFile != null && !"".equals(xmlFile)) {
         /*
          *  Use a common schema in the class path.
          */
         serviceInfoList = createServiceSetFromXml(xmlFile,
                                     MULTI_SERVICE_INFO_XML_XSD);

         /*
          * yes, we overwrite the values for h/p/u/p specified on commandline (if any),
          * with the values from the first VC's service info object
          */
         ServiceInfo vcServiceInfo = serviceInfoList.get(0);
         testData.setProperty(TestConstants.TESTINPUT_HOSTNAME, vcServiceInfo.getHostName());
         testData.setProperty(TestConstants.TESTINPUT_PORT, vcServiceInfo.getPort());
         testData.setProperty(TestConstants.TESTINPUT_USERNAME, vcServiceInfo.getUserName());
         testData.setProperty(TestConstants.TESTINPUT_PASSWORD, vcServiceInfo.getPassword());
         testData.setProperty(TestConstants.TESTINPUT_MACHINE_USERNAME,
                              vcServiceInfo.getMachineUsername());
         testData.setProperty(TestConstants.TESTINPUT_MACHINE_PASSWORD,
                              vcServiceInfo.getMachinePassword());
         ServiceInfo infraNode = vcServiceInfo.getInfraNode();
         if (infraNode != null) {
            testData.setProperty(TestConstants.TESTINPUT_INFRA_HOSTNAME,
                     infraNode.getHostName());
            testData.setProperty(
                     TestConstants.TESTINPUT_INFRA_HOST_ADMIN_USERNAME,
                     infraNode.getUserName());
            testData.setProperty(
                     TestConstants.TESTINPUT_INFRA_HOST_ADMIN_PASSWORD,
                     infraNode.getPassword());
            testData.setProperty(
                     TestConstants.TESTINPUT_INFRA_HOST_MACHINE_USERNAME,
                     infraNode.getMachineUsername());
            testData.setProperty(
                     TestConstants.TESTINPUT_INFRA_HOST_MACHINE_PASSWORD,
                     infraNode.getMachinePassword());
         }
      } else if (testbedInfoJsonFile != null && !testbedInfoJsonFile.isEmpty()) {
         serviceInfoList = createServiceSetFromJsonfile(
               testData.getInt(TestConstants.TESTINPUT_HOSTINDEX, -1), testData);
         /*
          * Service info list might be null or empty if run against hostd, which
          * does not have the vc information in the testbedInfo.json file.
          */
         if (serviceInfoList != null && serviceInfoList.size() > 0) {
            ServiceInfo serviceInfo = serviceInfoList.get(0);
            /*
             * yes, we overwrite the values for hostname/port/username/password
             * specified on commandline (if any), with the values from the
             * first VC's service info object
             */
           log.info("Overwritting the hostname/port/username/password values " +
                    "passed from the command line with the values from " +
                    "testbedInfo.json file");
           String hostname = serviceInfo.getHostName();
           String testDataHostname = testData.getString(TestConstants.TESTINPUT_HOSTNAME);
           if (!hostname.equals(testDataHostname)) {
              log.info("Changing the hostname from: " + testDataHostname +" to: " +
                    hostname + " from the testbedInfo.json file");
              testData.setProperty(TestConstants.TESTINPUT_HOSTNAME, hostname);
           }
           testData.setProperty(TestConstants.TESTINPUT_PORT, serviceInfo.getPort());
           String username = serviceInfo.getUserName();
           String testDataUsername = testData.getString(TestConstants.TESTINPUT_USERNAME);
           if (!testDataUsername.equals(username)) {
              log.info("Changing the username from: " + testDataUsername + " to: " +
                    username + " from the testbedInfo.json file");
              testData.setProperty(TestConstants.TESTINPUT_USERNAME, username);
           }
           String password = serviceInfo.getPassword();
           String testDataPassword = testData.getString(TestConstants.TESTINPUT_PASSWORD);
           if (!testDataPassword.equals(password)) {
              log.info("Changing the password from: " + testDataPassword + " to: " +
                    password + " from the testbedInfo.json file");
              testData.setProperty(TestConstants.TESTINPUT_PASSWORD, password);
           }
           /*
            * Read and set the machine user credentials for the VC machine from
            * the vc service info object.
            */
           String machineUsername = serviceInfo.getMachineUsername();
           String testDataMachineUserName =
                 testData.getString(TestConstants.TESTINPUT_MACHINE_USERNAME, null);
           if (!machineUsername.equals(testDataMachineUserName)) {
              log.info("Changing the machine username from: " + testDataMachineUserName + " to: " +
                       machineUsername + " from the testbedInfo.json file");
              testData.setProperty(TestConstants.TESTINPUT_MACHINE_USERNAME, machineUsername);
           }
           String machinePassword = serviceInfo.getMachinePassword();
           String testDataMachinePassword =
                 testData.getString(TestConstants.TESTINPUT_MACHINE_PASSWORD, null);
           if (!machinePassword.equals(testDataMachinePassword)) {
              log.info("Changing the machine password from: " + testDataMachinePassword + " to: " +
                       machinePassword+ " from the testbedInfo.json file");
              testData.setProperty(TestConstants.TESTINPUT_MACHINE_PASSWORD, machinePassword);
           }
           /*
            * Populate the infra host information in the testData object.
            */
           if (serviceInfo.getInfraNode() != null) {
              ServiceInfo infraNodeServiceInfo = serviceInfo.getInfraNode();
              String infraHostname = infraNodeServiceInfo.getHostName();
              String testDataInfraHostname =
                 testData.getString(TestConstants.TESTINPUT_INFRA_HOSTNAME, null);
              if(!infraHostname.equals(testDataInfraHostname)) {
                 log.info("Changing the infrahost hostname from: " +
                          testDataInfraHostname + " to: " + infraHostname +
                          " from the testbedInfo.json file");
                 testData.setProperty(TestConstants.TESTINPUT_INFRA_HOSTNAME,
                                      infraHostname);
              }
              String infrahostUserName = infraNodeServiceInfo.getUserName();
              String testDataInfraHostUsername =
                  testData.getString(TestConstants.TESTINPUT_INFRA_HOST_ADMIN_USERNAME, null);
              if (!infrahostUserName.equals(testDataInfraHostUsername)) {
                 log.info("Changing the infrahost username from: " + testDataInfraHostUsername
                       + " to: " + infrahostUserName + " from the testbedInfo.json file");
                 testData.setProperty(TestConstants.TESTINPUT_INFRA_HOST_ADMIN_USERNAME,
                                      infrahostUserName);
              }

              String infraHostPassword = infraNodeServiceInfo.getPassword();
              String testDataInfraHostPassword =
                 testData.getString(TestConstants.TESTINPUT_INFRA_HOST_ADMIN_PASSWORD,
                                    null);
              if (!infraHostPassword.equals(testDataInfraHostPassword)) {
                 log.info("Changing the infrahost admin password from: " +
                          testDataInfraHostPassword + " to: " + infraHostPassword +
                          " from the testbedInfo.json file");
                 testData.setProperty(TestConstants.TESTINPUT_INFRA_HOST_ADMIN_PASSWORD,
                                      infraHostPassword);
              }
              /*
               * Read and set the machine user credentials for the infra node
               * from the service info object in test data.
               */
              String infraMachineUsername = infraNodeServiceInfo.getMachineUsername();
              String testDataInfraMachineUserName =
                    testData.getString(TestConstants.TESTINPUT_INFRA_HOST_MACHINE_USERNAME,
                                       null);
              if (!infraMachineUsername.equals(testDataInfraMachineUserName)) {
                 log.info("Changing the infra machine username from: " +
                          testDataInfraMachineUserName + " to: " +
                          infraMachineUsername + " from the testbedInfo.json file");
                 testData.setProperty(TestConstants.TESTINPUT_INFRA_HOST_MACHINE_USERNAME,
                                      infraMachineUsername);
              }
              String infraMachinePassword = infraNodeServiceInfo.getMachinePassword();
              String testDataInfraMachinePassword =
                    testData.getString(TestConstants.TESTINPUT_INFRA_HOST_MACHINE_PASSWORD, null);
              if (!infraMachinePassword.equals(testDataInfraMachinePassword)) {
                 log.info("Changing the infra machine password from: " +
                          testDataInfraMachinePassword + " to: " +
                          infraMachinePassword + " from the testbedInfo.json file");
                 testData.setProperty(TestConstants.TESTINPUT_INFRA_HOST_MACHINE_PASSWORD,
                                      infraMachinePassword);
              }
           }
         } else {
            /*
             * testbedInfo.json does not have the vc information, construct the
             * service info from the configuration data.
             */
            serviceInfoList = createServiceInfoFromConfig(testData);
         }
      } else {
         /*
          * Construct the service info from the configuration data.
          */
         serviceInfoList = createServiceInfoFromConfig(testData);
      }
      return serviceInfoList == null ? Collections.EMPTY_LIST : serviceInfoList;
   }

   /**
    * Parse xml file to extract hostname, port and serviceId of the services. It
    * populates the information into list of ServiceInfo object by calling its
    * constructor. The sample file format <drtestconfig> <virtualcenters>
    * <virtualcenter> <hostname>sdk202.eng.vmware.com</hostname>
    * <port>443</port> <username>Administrator</username>
    * <password>ca$hc0w</password>
    * <keystorepath>E:\client.keystore</keystorepath> <locale>US-EN</locale>
    * <extensions> <extension>com.vmware.vcDr</extension> </extensions>
    * <customizations> <customization ID="secondaryVC"> </customization>
    * <customization SP-A-IP="10.17.37.84" SP-B-IP="10.17.37.85"
    * ManagmentSystem="Clariion Native" ArrayId="APM00062500030">
    * </customization> </customizations> </virtualcenter> </virtualcenters>
    * <drextapi> <hostname>sdk202.eng.vmware.com</hostname> <port>9007</port>
    * <username>Administrator</username> <password>ca$hc0w</password>
    * </drextapi> </drtestconfig>
    *
    * @param xmlFile file containing configuration input
    * @param xmlSchema file containing the schema for XML file
    * @throws Exception
    */
   public static List<ServiceInfo> createServiceSetFromXml(String xmlFile,
                                                           String xmlSchema)
      throws Exception
   {
      List<ServiceInfo> allServiceInfo = new Vector<ServiceInfo>();
      Map<String, ServiceInfo> infraNodeMap = new HashMap<String, ServiceInfo>();
      try {
         Document document = XMLUtil.getXmlDocumentElement(xmlFile, xmlSchema);
         NodeList virtualCenters =
            document.getElementsByTagName(TestConstants.XML_VIRTUALCENTER_TAG);
         ArrayList<String> xmlTags = new ArrayList<String>();
         xmlTags.addAll(TestUtil.arrayToVector
                  (TestConstants.MULTI_CONNECT_TESTBASE_REQUIRED_XML_TAGS));
         for (int i = 0; i < virtualCenters.getLength(); i++) {
            Node vcNode = virtualCenters.item(i);
            HashMap<String, Node> children = XMLUtil.getChildrenByTagNames(
                     vcNode, xmlTags);

            // extract deploymentType
            VC_DEPLOYMENT_TYPE deploymentType = VC_DEPLOYMENT_TYPE.EMBEDDED;
            Node deploymentTypeNode = children
                     .get(TestConstants.XML_DEPLOYMENTTYPE_TAG);
            if (deploymentTypeNode != null) {
               String xmlDeploymentType = XMLUtil
                        .getNodeTextValue(deploymentTypeNode);
               log.debug("xmlDeploymentType = {}", xmlDeploymentType);
               deploymentType = VC_DEPLOYMENT_TYPE.valueOf(xmlDeploymentType
                        .toUpperCase());
            }

            /*
             * extract information from <virtualcenter> tag. There could be xmls
             * not having hostname, port, userName, password tags. In such cases
             * fall back to test data(either config.properties or args)
             */
            Node hostNode = children.get(TestConstants.XML_HOSTNAME_TAG);
            String hostname;
            if (hostNode != null) {
               hostname = XMLUtil.getNodeTextValue(hostNode);
            } else {
               String hostNameKey = VC_DEPLOYMENT_TYPE.INFRASTRUCTURE == deploymentType ?
                        TestConstants.TESTINPUT_INFRA_HOSTNAME
                        : TestConstants.TESTINPUT_HOSTNAME;
               log.warn("Hostname tag is missing from input xml."
                        + " Hence using the {} value from config.properties",
                        hostNameKey);
               hostname = data.getString(hostNameKey);
            }
            Node portNode = children.get(TestConstants.XML_PORT_TAG);
            String portNum;
            if (portNode != null) {
               portNum = XMLUtil.getNodeTextValue(portNode);
            } else {
               log.warn("Port tag is missing from input xml."
                        + " Hence using from the config.properties.");
               portNum = data.getString(TestConstants.TESTINPUT_PORT);
            }
            int port = 0;
            if (portNum != null) {
               port = Integer.parseInt(portNum);
            }
            Node userNameNode = children.get(TestConstants.XML_USERNAME_TAG);
            String xmlUserName;
            if (userNameNode != null) {
               xmlUserName = XMLUtil.getNodeTextValue(userNameNode);
            } else {
               String userNameKey = VC_DEPLOYMENT_TYPE.INFRASTRUCTURE == deploymentType?
                        TestConstants.TESTINPUT_INFRA_HOST_ADMIN_USERNAME
                        : TestConstants.TESTINPUT_USERNAME;
               log.warn("Username tag is missing from input xml."
                        + " Hence using {} from the config.properties.",
                        userNameKey);
               xmlUserName = data.getString(userNameKey);
            }
            Node passwordNode = children.get(TestConstants.XML_PASSWORD_TAG);
            String xmlPassword;
            if (passwordNode != null) {
               xmlPassword = XMLUtil.getNodeTextValue(passwordNode);
            } else {
               String passwordKey = VC_DEPLOYMENT_TYPE.INFRASTRUCTURE == deploymentType ?
                        TestConstants.TESTINPUT_INFRA_HOST_ADMIN_PASSWORD
                        : TestConstants.TESTINPUT_PASSWORD;
               log.warn("Password tag is missing from input xml."
                        + " Hence using {} from the config.properties.",
                        passwordKey);
               xmlPassword = data.getString(passwordKey);
            }

            Node machineUserNameNode = children
                     .get(TestConstants.XML_MACHINEUSERNAME_TAG);
            String xmlMachineUserName;
            if (machineUserNameNode != null) {
               xmlMachineUserName = XMLUtil
                        .getNodeTextValue(machineUserNameNode);
            } else {
               String machineUserNameKey = VC_DEPLOYMENT_TYPE.INFRASTRUCTURE == deploymentType ?
                        TestConstants.TESTINPUT_INFRA_HOST_MACHINE_USERNAME
                        : TestConstants.TESTINPUT_MACHINE_USERNAME;
               log.warn("machineusername tag is missing from input xml."
                        + " Hence using {} from the config.properties.",
                        machineUserNameKey);
               xmlMachineUserName = data.getString(machineUserNameKey, null);
            }
            Node machinePasswordNode = children
                     .get(TestConstants.XML_MACHINEPASSWORD_TAG);
            String xmlMachinePassword;
            if (machinePasswordNode != null) {
               xmlMachinePassword = XMLUtil
                        .getNodeTextValue(machinePasswordNode);
            } else {
               String machinePasswordKey = VC_DEPLOYMENT_TYPE.INFRASTRUCTURE == deploymentType ?
                        TestConstants.TESTINPUT_INFRA_HOST_MACHINE_PASSWORD
                        : TestConstants.TESTINPUT_MACHINE_PASSWORD;
               log.warn("machinepassword tag is missing from input xml."
                        + " Hence using {} from the config.properties.",
                        machinePasswordKey);
               xmlMachinePassword = data.getString(machinePasswordKey, null);
            }

            Node keyNode = children.get(TestConstants.XML_KEYSTOREPATH_TAG);
            String keyStorePath = XMLUtil.getNodeTextValue(keyNode);
            Node localeNode = children.get(TestConstants.XML_LOCALE_TAG);
            String locale = XMLUtil.getNodeTextValue(localeNode);
            /*
             * extract extension Ids
             */
            Vector<String> vecExtensionKey = null;
            Node extsNode = children.get(TestConstants.XML_EXTENSIONS_TAG);
            if (extsNode != null) {
               vecExtensionKey = extractExtensionKeys(extsNode);
            }
            /*
             * extract custom info
             */
            HashMap<String, String> allCustomInfo = null;
            Node customizationsNode = children
                     .get(TestConstants.XML_CUSTOMIZATIONS_TAG);
            if (customizationsNode != null) {
               allCustomInfo = extractCustomizationsInfo(customizationsNode);
            }

            List<ServiceInfo> vcServiceList = null;
            switch (deploymentType) {
               case INFRASTRUCTURE:
                  ServiceInfo infraServiceInfo = new ServiceInfo(xmlUserName,
                           xmlPassword, hostname, port, null, null, null, null);
                  infraServiceInfo.setMachineUsername(xmlMachineUserName);
                  infraServiceInfo.setMachinePassword(xmlMachinePassword);
                  infraNodeMap.put(hostname, infraServiceInfo);
                  break;
               case MANAGEMENT:
                  vcServiceList = SolutionHelper
                           .createVCServiceSet(xmlUserName, xmlPassword,
                                    hostname, port, keyStorePath, locale,
                                    vecExtensionKey, allCustomInfo);
                  // extract infraNodeHostName
                  Node infraNodeHostNameNode = children
                           .get(TestConstants.XML_INFRANODEHOSTNAME_TAG);
                  if (infraNodeHostNameNode == null) {
                     log.error("InfraNodeHostName not found.");
                  } else {
                     String infraNodeHostName = XMLUtil
                              .getNodeTextValue(infraNodeHostNameNode);
                     if (infraNodeHostName == null) {
                        log.error("InfraNodeHostName not found.");
                     } else {
                        ServiceInfo infraNode = infraNodeMap
                                 .get(infraNodeHostName);
                        if (infraNode == null) {
                           log.error(
                                    "Infrastructure Node {} must be defined prior to Management Node {}!",
                                    infraNodeHostName, hostname);
                        } else {
                           vcServiceList.get(0).setInfraNode(infraNode);
                        }
                     }
                  }
                  break;
               default:
                  vcServiceList = SolutionHelper
                           .createVCServiceSet(xmlUserName, xmlPassword,
                                    hostname, port, keyStorePath, locale,
                                    vecExtensionKey, allCustomInfo);
                  break;
            }

            if (vcServiceList != null) {
               /**
                * Find the service info object for the vc, and set the machine
                * username and password.
                */
               for (ServiceInfo vcServiceInfo : vcServiceList) {
                  if (vcServiceInfo.getExtensionKey().equals(
                           TestConstants.VC_EXTENSION_KEY)) {
                     vcServiceInfo.setMachineUsername(xmlMachineUserName);
                     vcServiceInfo.setMachinePassword(xmlMachinePassword);
                     break;
                  }
               }
               allServiceInfo.addAll(vcServiceList);
            }
         }

         // extract information from <vendorprovider> tag
         NodeList vpServiceInfos = document
                  .getElementsByTagName(TestConstants.XML_VENDORPROVIDER_TAG);
         if (vpServiceInfos != null) {
            xmlTags.add(TestConstants.XML_VENDORPROVIDER_TYPE_TAG);
            for (int i = 0; i < vpServiceInfos.getLength(); i++) {
               Node vpNode = vpServiceInfos.item(i);
               HashMap<String, Node> children = XMLUtil.getChildrenByTagNames(
                        vpNode, xmlTags);
               Node hostNode = children.get(TestConstants.XML_HOSTNAME_TAG);
               String hostname = XMLUtil.getNodeTextValue(hostNode);
               String userName = XMLUtil.getNodeTextValue(children
                        .get(TestConstants.XML_USERNAME_TAG));
               String password = XMLUtil.getNodeTextValue(children
                        .get(TestConstants.XML_PASSWORD_TAG));
               String keyStorePath = XMLUtil.getNodeTextValue(children
                        .get(TestConstants.XML_KEYSTOREPATH_TAG));
               String locale = XMLUtil.getNodeTextValue(children
                        .get(TestConstants.XML_LOCALE_TAG));
               Node portNode = children.get(TestConstants.XML_PORT_TAG);
               String portValue = XMLUtil.getNodeTextValue(portNode);
               int port = portValue == null ? -1 : Integer.parseInt(portValue);

               /*
                * extract custom info
                */
               HashMap<String, String> customInfo =  new HashMap<String,String>();
               Node customizationsNode =
                  children.get(TestConstants.XML_CUSTOMIZATIONS_TAG);
               if (customizationsNode != null) {
                  customInfo = extractCustomizationsInfo(customizationsNode);
               }
               allServiceInfo.add(new ServiceInfo(userName, password, hostname,
                        port, keyStorePath, locale,
                        TestConstants.XML_VENDORPROVIDER_TAG, customInfo));
            }
         }
      } catch (SAXException saEx) {
         log.error("SAXException thrown in parsing the xml file. ", saEx);
      } catch (ParserConfigurationException pEx) {
         log.error("ParserConfigurationException thrown in"
                  + "parsing the xml file.", pEx);
      }
      return allServiceInfo.isEmpty() ? null : allServiceInfo;
   }

   /**
    * Parses the testbedInfo.json file and returns an ordered list of
    * service info objects based on the host index.
    *
    * @param hostIndex int host index.
    * @param configData Configuration object.
    *
    * @return List<ServiceInfo> serviceinfo objects of size 1, based on the
    * host index passed.
    *
    * @throws Exception
    */
   public static synchronized List<ServiceInfo> createServiceSetFromJsonfile(
         int hostIndex, Configuration configData) throws Exception
   {
      List<ServiceInfo> serviceInfoList = null;
      TestbedInfoJsonParser testbedInfoJsonParser = new TestbedInfoJsonParser();

      Configuration commonData = TestDataHandler.getSingleton().getData();

      String hostname = null;
      int port = commonData.getInt(TESTINPUT_PORT);;
      String username = null;
      String password = null;
      String machineUsername = null;
      String machinePassword = null;

      if (hostIndex != -1) {
         /*
          * Find all the embedded VC's in the testbed info json file, including
          * standalone VC's and replicating VC's and create service info object for
          * each VC.
          */
         List<String> embeddedHostnames = testbedInfoJsonParser.getEmbeddedHostnames();

         /*
          * Find all the management nodes in the testbed info json file, and populate
          * the service info object for the management node which includes the
          * infra node information.
          */
         List<String> managementHostnames = testbedInfoJsonParser.getManagementHostnames();

         if (hostIndex >= embeddedHostnames.size() + managementHostnames.size()) {
            log.warn("No host can be associated for hostIndex:" + hostIndex +
                     " provided, Creating service info from the configuration data" +
                     "provided");
            serviceInfoList = createServiceInfoFromConfig(configData);
         } else {
            serviceInfoList = new ArrayList<ServiceInfo>();
            ServiceInfo vcServiceInfo = null;
            if (hostIndex < embeddedHostnames.size()) {
               hostname = testbedInfoJsonParser.getEmbeddedHostname(hostIndex);
               if (commonData.getBoolean(TestConstants.TESTINPUT_USE_DNS_HOSTNAME, false)) {
                  hostname = InetAddress.getByName(hostname).getHostName();
               }
               username = testbedInfoJsonParser.getEmbeddedHostAdminUsername(hostIndex);
               password = testbedInfoJsonParser.getEmbeddedHostAdminPassword(hostIndex);
               vcServiceInfo = new ServiceInfo(username, password, hostname,
                                               port, null, null, null);
               /*
                * Populate the machine username and password for the embedded
                * deployment.
                */
               vcServiceInfo.setMachineUsername(
                     testbedInfoJsonParser.getEmbeddedHostMachineAdminUsername(hostIndex));
               vcServiceInfo.setMachinePassword(
                     testbedInfoJsonParser.getEmbeddedHostMachineAdminPassword(hostIndex));
            }

            if (vcServiceInfo == null) {
               hostIndex = hostIndex - embeddedHostnames.size();
               int infraHostIndex = testbedInfoJsonParser.getInfraHostIndex(hostIndex);
               hostname = testbedInfoJsonParser.getInfraHostname(infraHostIndex);
               username = testbedInfoJsonParser.getInfraHostAdminUserName(infraHostIndex);
               password = testbedInfoJsonParser.getInfraHostAdminPassword(infraHostIndex);
               /*
                * Read and populate the machine username which is always available
                * in the testbedInfo.json file for all the MxN VC nodes.
                */
               machineUsername =
                     testbedInfoJsonParser.getInfraHostMachineAdminUserName(infraHostIndex);
               /*
                * Read and populate the machine password which is always available
                * in the testbedInfo.json file for all the MxN VC nodes.
                */
               machinePassword =
                     testbedInfoJsonParser.getInfraHostMachineAdminPassword(infraHostIndex);
               ServiceInfo infraServiceInfo =
                     new ServiceInfo(username, password, hostname, port, null, null,
                           null, null);
               infraServiceInfo.setMachineUsername(machineUsername);
               infraServiceInfo.setMachinePassword(machinePassword);
               hostname = testbedInfoJsonParser.getManagementHostname(hostIndex);
               if (commonData.getBoolean(TestConstants.TESTINPUT_USE_DNS_HOSTNAME, false)) {
                  hostname = InetAddress.getByName(hostname).getHostName();
               }
               username = testbedInfoJsonParser.getManagementHostAdminUsername(hostIndex);
               password = testbedInfoJsonParser.getManagementHostAdminPassword(hostIndex);
               /*
                * Read and populate the machine username which is always available
                * in the testbedInfo.json file for all the MxN VC nodes.
                */
               machineUsername =
                     testbedInfoJsonParser.getManagementHostMachineAdminUsername(hostIndex);
               /*
                * Read and populate the machine password which is always available
                * in the testbedInfo.json file for all the MxN VC nodes.
                */
               machinePassword =
                     testbedInfoJsonParser.getManagementHostAdminPassword(hostIndex);
               vcServiceInfo = new ServiceInfo(infraServiceInfo, username,
                     password, hostname, port,
                     null, null, null);
               vcServiceInfo.setMachineUsername(machineUsername);
               vcServiceInfo.setMachinePassword(machinePassword);
            }

            /*
             * Add the vc service info to the list.
             */
            serviceInfoList.add(vcServiceInfo);
         }
      } else {
         /*
          * Host index is not passed create the service info from the
          * configuration data passed.
          */
         log.debug("Not a valid host index: " + hostIndex +
                  ", Creating service info from the configuration data" +
                  "provided");
         serviceInfoList = createServiceInfoFromConfig(configData);
      }

      return serviceInfoList;
   }

   /**
    * Constructs and returns the service info object from the configuration
    * object passed.
    *
    * @param data Configuration
    *
    * @return List<ServiceInfo>
    *
    * @throws Exception
    */
   public static List<ServiceInfo> createServiceInfoFromConfig(Configuration data) throws Exception {
      ArrayList<ServiceInfo> serviceInfoList = null;
      String hostNameFromArg = data.getString(TestConstants.TESTINPUT_HOSTNAME);
      int port = 0;
      if (data.getProperty(TestConstants.TESTINPUT_PORT) != null) {
         port = data.getInt(TestConstants.TESTINPUT_PORT);
      } else {
         log.error("Input port not specified");
      }
      if (hostNameFromArg != null && port != 0) {
         ServiceInfo svcInfo = null ;
         String usernameFromArg = data.getString(TestConstants.TESTINPUT_USERNAME);
         String passwordFromArg = data.getString(TestConstants.TESTINPUT_PASSWORD);
         String machineUserName =
            (data.getString(TestConstants.TESTINPUT_MACHINE_USERNAME, null) == null)?
             TestUtil.getDefaultMachineAdminUserName(hostNameFromArg):
             data.getString(TestConstants.TESTINPUT_MACHINE_USERNAME, null);
         String machinePassword = null;
         /*
          * Infra host information passed from the command line, populate
          * the service info object with this information.
          */
         String infraHostnameFromArg = data.getString(TestConstants.TESTINPUT_INFRA_HOSTNAME, null);

         if (infraHostnameFromArg != null && infraHostnameFromArg.isEmpty()) {
            String infraHostMachineUsername = null;
            String infraHostMachinePassword = null;
            ServiceInfo infraSvcInfo =
               new ServiceInfo(
                  data.getString(TestConstants.TESTINPUT_INFRA_HOST_ADMIN_USERNAME, null),
                  data.getString(TestConstants.TESTINPUT_INFRA_HOST_ADMIN_PASSWORD, null),
                  infraHostnameFromArg,
                  port, null, null, null);
            /*
             * Set the management host machine password from the test data if
             * passed or the default username for the vc type.
             */
            infraHostMachineUsername =
               (data.getString(TestConstants.TESTINPUT_INFRA_HOST_MACHINE_USERNAME, null)==null)?
                TestUtil.getDefaultMachineAdminUserName(infraHostnameFromArg):
                data.getString(TestConstants.TESTINPUT_INFRA_HOST_MACHINE_USERNAME, null);
            /*
             * Set the infra host machine password from the test data if passed
             * or the default for the VC type.
             */
            infraHostMachinePassword =
                (data.getString(TestConstants.TESTINPUT_INFRA_HOST_MACHINE_PASSWORD, null)==null)?
                 TestUtil.getDefaultMachineAdminPassword(infraHostnameFromArg, null, null, -1):
                 data.getString(TestConstants.TESTINPUT_INFRA_HOST_MACHINE_PASSWORD, null);
            infraSvcInfo.setMachineUsername(infraHostMachineUsername);
            infraSvcInfo.setMachinePassword(infraHostMachinePassword);
            svcInfo = new ServiceInfo(infraSvcInfo, usernameFromArg,
                                      passwordFromArg, hostNameFromArg,
                                      port, null, null, null);
            /*
             * Set the machine password if the machine password has been passed.
             * Set it to the default password based on vim install type if the
             * machine password is not passed.
             */
            machinePassword = data.getString(TestConstants.TESTINPUT_MACHINE_PASSWORD, null);
            if (machinePassword == null) {
               machinePassword = TestUtil.getDefaultMachineAdminPassword(hostNameFromArg,
                     usernameFromArg, passwordFromArg, port);
            }
            data.setProperty(TestConstants.TESTINPUT_INFRA_HOST_MACHINE_USERNAME,
                             infraHostMachineUsername);
            data.setProperty(TestConstants.TESTINPUT_INFRA_HOST_MACHINE_PASSWORD,
                             infraHostMachinePassword);
         } else {
            machinePassword = data.getString(TestConstants.TESTINPUT_MACHINE_PASSWORD,
                                             null);
            if (machinePassword == null) {
               /*
                * Get the default machine password based on the machine type and
                * the if the machine is VCSA or ESX host.
                */
               machinePassword = TestUtil.getDefaultMachineAdminPassword(
                    hostNameFromArg, usernameFromArg, passwordFromArg, port);
            }
            svcInfo = new ServiceInfo(usernameFromArg, passwordFromArg,
                                      hostNameFromArg, port, null, null, null);
         }
         /*
          * Set the machine username and password.
          */
         svcInfo.setMachineUsername(machineUserName);
         svcInfo.setMachinePassword(machinePassword);
         serviceInfoList = new ArrayList<ServiceInfo>();
         serviceInfoList.add(svcInfo);
         data.setProperty(TestConstants.TESTINPUT_MACHINE_USERNAME,
                          machineUserName);
         data.setProperty(TestConstants.TESTINPUT_MACHINE_PASSWORD,
                          machinePassword);
      } else {
         log.error("Input parameters are incorrect");
      }
      return serviceInfoList;
   }

   /**
    * Extract array of extensions from xml node list. for example if we have
    * <extensions> <extension>DisasterRecovery</extension>
    * <extension>Integrity</extension> </extensions> this function gets the
    * extension key associated with each of these solutions from TestConstant
    * and for example in this case it returns ["TESTCONSTANT.DR_EXTENSION_KEY",
    * "TESTCONSTANT.INTEGRITY_EXTENSION_KEY"] in the array
    *
    * @param node - <extensions> node which can have one or more <extension>
    *           node
    * @return arrExtensionKey - array of extension keys
    * @throws Exception
    */
   private static Vector<String> extractExtensionKeys(Node extensionsNode)
      throws Exception
   {
      NodeList extensionsList = extensionsNode.getChildNodes();
      Vector<String> arrExtensionKey = new Vector<String>();
      if (extensionsList.getLength() > 0) {
         for (int index = 0; index < extensionsList.getLength(); index++) {
            if (extensionsList.item(index).getNodeType() == Node.ELEMENT_NODE) {
               String solutionId =
                  XMLUtil.getNodeTextValue(extensionsList.item(index));
               arrExtensionKey.add(solutionId);
            }
         }
      }
      return arrExtensionKey.isEmpty() ? null : arrExtensionKey;
   }

   /**
    * Extract hashMap of <String,String> from all the customization keys,values
    * found in the xml * <customizations> <customization
    * ID="primaryVC"></customization> <customization
    * ArrayManagerUrl="http://10.20.30.40" ArraySystem="ABCD"> </customization>
    * </customizations> this function gets all the attributes and put them in a
    * <string,string> hashMap. in the above case it returns : {
    * ["ID","primaryVC"],["ArrayManagerUrl",""http://10.20.30.40"],
    * ["ArraySystem","ABCD"] in the hashMap
    *
    * @param node - <customizations> node which can have one or more
    *           <customization> node
    * @return customInfoMap - hashMap of all customizations keys,values
    */
   private static HashMap<String, String> extractCustomizationsInfo(Node customizationNode)
   {
      NodeList customizationList = customizationNode.getChildNodes();

      HashMap<String, String> allCustomInfo = new HashMap<String, String>();
      HashMap<String, String> customInfo = null;
      /*
       * get all <customization> tags attributes
       */
      if (customizationList != null) {
         for (int index = 0; index < customizationList.getLength(); index++) {
            customInfo = XMLUtil.getAttributes(customizationList.item(index));
            if (customInfo != null) {
               allCustomInfo.putAll(customInfo);
            }
         }
      }
      return allCustomInfo.isEmpty() ? null : allCustomInfo;
   }
}

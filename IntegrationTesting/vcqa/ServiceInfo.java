/*
 * ************************************************************************
 *
 * Copyright 2007-2014 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package com.vmware.vcqa;

import java.lang.reflect.Constructor;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.AboutInfo;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.internal.sps.SpsTestConstants;
import com.vmware.vcqa.pbm.util.impl.PbmConnectAnchorUtils;
import com.vmware.vcqa.vasa.VPConnectAnchor;
import com.vmware.vcqa.vasa.VasaTestConstants.VasaVersion;
import com.vmware.vcqa.vasa.VasaTestConstants.WebServiceEndpointProtocol;

public class ServiceInfo {


   private static final Logger log = LoggerFactory.getLogger(ServiceInfo.class);

   /*
    * The machine admin username.
    */
   private String machineUsername;

   /*
    * The machine admin password.
    */
   private String machinePassword;

   /*
    * userName to login to service
    */
   private  String userName;
   /*
    * password to login to service
    */
   private  String password;

   /*
    * locale string
    */
   private  String locale;

   /*
    * key representing an extension or other service
    */
   private  String key;

   /*
    * url of the host to connect to
    */
   private String hostName;

   /*
    * portNumber that service is running
    */
   private int portNumber;

   /*
    * endpoint Url
    */
   private  URL endpointUrl;

   /*
    * serviceDescription specifies host role in the application
    * it can be VC /ESX box / DR Primary / DR Secondary , etc.
    */
   private String serviceDescription = null;

   /*
    * client keyStorePath
    */
   private  String keyStorePath;

   /*
    * The reference to the vc serviceInfo that this extension is registered
    * to.
    * If parentVC is null , it means the current serviceInfo
    * is a VC/HA , not an extension.
    */
   private ServiceInfo parentVc;

   /*
    * The reference to the infra node serviceinfo that this VC points to.
    * If infraNode is null, it means the current VC serviceInfo is an embedded
    * deployment, and not an MxN deployment.
    */
   private ServiceInfo infraNode;

   /*
    * The connect anchor that binds to the extension
    * it can be instance of ConnectAnchor for VC/HA
    * DrConnectAnchor for DisasterRecovery service,
    * IntgConnectAnchor for Integrity service
    *
    */
   private  GenericConnectAnchor refConnectAnchor;

   /*
    * hashmap of <key,value> reserved for some
    * customized information specific to each service
    */
   private  HashMap<String,String> customInfo;

   /*
    * map of <key,value> reserved for some
    * customized Objects specific to each service
    */
   private Map<Object,Object> customObjects;

   /**
    * Constructor #1
    * This constructor can be used to create serviceInfo for
    * extensions to VC such as DisasterRecovery , Integrity and etc.
    * @param userName userName to login to Extension/VC
    * @param password required to login to Extension/VC
    * @param extensionUrl  Url of the extension server
    * @param keyStorePath
    * @param locale
    * @param extensionKey  extensionKey of the service
    * @param customInfo customInfo which can be different for each service
    * @param parentVC serviceInfo object of the VC this extension is
    *        associated to
    */
   public ServiceInfo(String userName,
                      String password,
                      URL extensionUrl,
                      String keyStorePath,
                      String locale,
                      String extensionKey,
                      HashMap<String,String> customInfo,
                      ServiceInfo parentVC)
                      throws Exception
   {
      /*
       * endPointUrl refers to url that the registered extension is running.
       * it is required when createConnectAnchor is invoked
       */
      this.endpointUrl = extensionUrl;
      this.parentVc = parentVC;
      this.infraNode = null;
      commonConstructor(userName, password,extensionUrl.getHost(),
                        extensionUrl.getPort(), keyStorePath, locale,
                        extensionKey, customInfo);

   }

   /**
    * Constructor #2
    * This constructor can be used only if the serviceInfo is for
    * a VC or HostAgent
    * @param userName userName to login to VC
    * @param password required to login to VC
    * @param hostName  Name of host where Service is running
    * @param port  port Number
    * @param keyStorePath
    * @param locale
    * @param customInfo customInfo which can be different for each service
    * @param parentVC serviceInfo object of the VC this extension is
    *        associated to
    * @deprecated
    * TODO Remove this method as it is deprecated.
    */
   public ServiceInfo(String userName,
                      String password,
                      String hostName,
                      int    portNumber,
                      String keyStorePath,
                      String locale,
                      HashMap<String,String> customInfo)
                      throws Exception

   {
      this.parentVc = null;
      this.infraNode = null;
      commonConstructor(userName, password,hostName,portNumber,
            keyStorePath, locale,TestConstants.VC_EXTENSION_KEY, customInfo);
   }

   /**
    * Constructor #3 This constructor can be used only if the serviceInfo is for
    * a VendorProvider (not VC, host agent or extension)
    *
    * @param userName userName to login to VC
    * @param password required to login to VC
    * @param hostName Name of host where Service is running
    * @param port port Number
    * @param keyStorePath
    * @param locale
    * @param serviceKey Service key
    * @param customInfo customInfo which can be different for each service
    */
   public ServiceInfo(String userName,
                      String password,
                      String hostName,
                      int port,
                      String keyStorePath,
                      String locale,
                      String serviceKey,
                      HashMap<String, String> customInfo)
                                                         throws Exception
   {
      this.parentVc = null;
      this.infraNode = null;
      commonConstructor(userName, password, hostName, port, keyStorePath,
               locale, serviceKey, customInfo);
   }

   /**
    * Constructor #4
    * This constructor can be used to create serviceInfo for
    * extensions to VC such as DisasterRecovery , Integrity and etc.
    * @param userName userName to login to Extension/VC
    * @param password required to login to Extension/VC
    * @param extensionUrl  Url of the extension server
    * @param keyStorePath
    * @param locale
    * @param extensionKey  extensionKey of the service
    * @param customInfo customInfo which can be different for each service
    * @param parentVC serviceInfo object of the VC this extension is
    *        associated to
    * @param customObjects A Map of custom objects
    *
    * @throws Exception
    */
   public ServiceInfo(String userName,
                      String password,
                      URL extensionUrl,
                      String keyStorePath,
                      String locale,
                      String extensionKey,
                      HashMap<String,String> customInfo,
                      ServiceInfo parentVC,
                      Map<Object,Object> customObjects)
                      throws Exception
   {
      /*
       * endPointUrl refers to url that the registered extension is running.
       * it is required when createConnectAnchor is invoked
       */
       this.customObjects = customObjects;
       this.endpointUrl = extensionUrl;
       this.parentVc = parentVC;
       this.infraNode = null;
       commonConstructor(userName, password,extensionUrl.getHost(),
                  extensionUrl.getPort(), keyStorePath, locale,
                  extensionKey, customInfo);
   }

   /**
    * Constructor #5
    * This constructor can be used only if the serviceInfo is for a VC in an MXN
    * deployment.
    *
    * @param infraNode the infra node service info object.
    * @param userName userName to login to VC
    * @param password required to login to VC
    * @param hostName  Name of host where Service is running
    * @param port  port Number
    * @param keyStorePath
    * @param locale
    * @param customInfo customInfo which can be different for each service
    *
    * @throws Exception
    */
   public ServiceInfo(ServiceInfo infraNode,
                      String userName,
                      String password,
                      String hostName,
                      int portNumber,
                      String keyStorePath,
                      String locale,
                      HashMap<String,String> customInfo)
                      throws Exception

   {
      this.parentVc = null;
      this.infraNode = infraNode;
      commonConstructor(userName, password,hostName,portNumber,
            keyStorePath, locale, TestConstants.VC_EXTENSION_KEY, customInfo);
   }

   /**
    * private method to initialize private data members
    * used by both constructors. It initializes the variables and
    * invoke createConnectAnchor method.
    * @param userName userid to login to service
    * @param password password to login to service
    * @param hostName hostname to login to
    * @param portNumber portnumber of the service
    * @param keyStorePath
    * @param locale
    * @param extensionKey - extensionkey of the service
    * @param customInfo - customInfo which can be different for each service
    * @throws Exception
    */
   private void
   commonConstructor(String userName,
                     String password,
                     String hostName,
                     int portNumber,
                     String keyStorePath,
                     String locale,
                     String extensionKey,
                     HashMap<String,String> customInfo)
                     throws Exception
   {
      this.userName = userName;
      this.password = password;
      this.keyStorePath = keyStorePath;
      this.hostName = hostName;
      this.portNumber = portNumber;
      this.locale = locale;
      this.key = extensionKey;
      this.customInfo = customInfo;
      this.serviceDescription = null;
      this.refConnectAnchor = createConnectAnchor();

      if (this.refConnectAnchor != null) {
         /*
          * after invoking createConnectAnchor we can get the
          * service full url from connectAnchor
          */
         this.endpointUrl = new URL(this.refConnectAnchor.getEndPointUrl());
      }
   }

   /*
    * public methods go here
    */

   /**
    * return connectAnchor assocaited with this ServiceInfo
    *
    * @return GenericConnectAnchor object - can be casted to
    *         its derived objects such as ConnectAnchor , DrConnectAnchor
    *
    */
   public GenericConnectAnchor
   getConnectAnchor()
   {
      return refConnectAnchor;
   }

   /**
    * @return service id
    */
   public HashMap<String,String>
   getCustomInfoMap()
   {
      return customInfo;
   }

   /**
    * @return service id
    */
   public String
   getExtensionKey()
   {
      return key;
   }

   /**
    * @return userName
    */
   public String
   getUserName()
   {
      return userName;
   }

   /**
    * @return password
    */
   public String
   getPassword()
   {
      return password;
   }

   /**
    * Returns the machine username.
    *
    * @return the machineUserName
    */
   public String getMachineUsername() {
      return machineUsername;
   }

   /**
    * Setter with package scope.
    *
    * @param machineUsername the machineUserName to set
    */
   void setMachineUsername(String machineUsername) {
      /*
       * Make the machine username variable immutable.
       */
      if (this.machineUsername == null) {
         this.machineUsername = machineUsername;
      }
   }

   /**
    * Returns the machine password.
    *
    * @return the machinePassword
    */
   public String getMachinePassword() {
      return machinePassword;
   }

   /**
    * Setter with package scope.
    *
    * @param machinePassword the machinePassword to set
    */
   void setMachinePassword(String machinePassword) {
      /*
       * Make the machine password variable immutable.
       */
      if (this.machinePassword == null) {
         this.machinePassword = machinePassword;
      }
   }

   /**
    * @param infraNode the infraNode to set
    */
   public void setInfraNode(ServiceInfo infraNode)
   {
      this.infraNode = infraNode;
   }

   /**
    * @return locale string
    */
   public String
   getLocale()
   {
      return locale;
   }

   /**
    * @return hostname
    */
   public String
   getHostName()
   {
      return hostName;
   }

   /**
    * @return endPointUrl of the service
    */
   public URL
   getEndpointUrl()
   {
      return this.endpointUrl;
   }

   /**
    * @return portNumber
    */
   public int
   getPort()
   {
      return portNumber;
   }

   /**
    *
    * @return keyStorePath
    */
   public String
   getKeyStorePath()
   {
      return keyStorePath;
   }

   /**
    * @return serviceDescription obtained from customMap
    */
   public String
   getServiceDescription()
   {
      String description = "";
      if (this.customInfo.containsKey(TestConstants.XML_DESCRIPTION_ATTRIBUTE)) {
         description =
            this.customInfo.get(TestConstants.XML_DESCRIPTION_ATTRIBUTE);
      }
      return description;
   }

   /**
    * @return serviceInstanceMor
    */
   public ManagedObjectReference
   getServiceInstance()
                      throws Exception
   {
      return this.getConnectAnchor().getServiceInstance();
   }

   /**
    * @return serviceContent
    */
   public Object
   getServiceContent()
                     throws Exception
   {
      return this.getConnectAnchor().getSC();
   }

   /**
    * @return build
    */
   public String
   getBuild()
            throws Exception
   {
      return this.getConnectAnchor().getBuild();
   }

   /**
    * @return AboutInfo
    */
   public AboutInfo
   getAboutInfo()
                throws Exception
   {
      return this.getConnectAnchor().getAboutInfo();
   }


   /**
    * sets the serviceDescription
    * @param  serviceDescriptionType: task type of this serviceInfo in the test
    */
    public void
    setServiceDescription(String serviceDescription)
    {
       this.customInfo.put(TestConstants.XML_DESCRIPTION_ATTRIBUTE,
                           serviceDescription);
    }

   /**
   * returns the VC Service info that this serviceInfo is
   * associated to. If this serviceInfo is a VC itself then parentVc is null.
   * If this serviceInfo is an extension then parentVC is not null.
   * @return parentVC
   */
   public ServiceInfo
   getParentVC()
   {
      return parentVc;
   }

   /**
    * Returns the Infra node Service info that this serviceInfo is
    * associated to. If this is an embedded deployment then the infra node
    * will be null.
    *
    * @return ServiceInfo infraNode.
    */
    public ServiceInfo getInfraNode()
    {
       return infraNode;
    }

   /**
    *
    * @return the customObjects Map
    *
    */
   public Map<Object, Object> getCustomObjectsMap()
   {
      return customObjects;
   }
   /**
    * Print the Service Info object properties.
    * Print VC related information if info object is a VC Service.
    * Otherwise print extension related information if info object is of
    * extension type.
    *
    */
   public void
   PrintInfo()
   {
      if ( this.key == null ) {
         log.info("Virtual Center");
         log.info("---------------------------------");
         log.info("   EndPointURL: " + this.endpointUrl );

         log.info("   Description: " +
            this.serviceDescription );

      } else {
         log.info("Solution");
         log.info("---------------------------------");
         log.info("   Extension: " + this.key );
         log.info("   EndPointURL: " + this.endpointUrl );
         log.info("   Description: " +
            this.serviceDescription );
      }
   }

  /**
   * It creates the connect anchor that this service info
   * requires.
   * If service is a standalone vc it instantiates a ConnectAnchor object
   * otherwise it instantiates a specific connectAnchor based on the extension.
   * This is acheived through reflection , so we dynamically generate
   * DrConnectAnchor or IntegrityConnectAnchor object
   * Note : All created ConnectAnchors are casted to GenericConnectAnchor object
   *
   * @return created connect anchor which is of GenericConnectAnchor type
   *
   *
   * @throws Exception
   */
   private GenericConnectAnchor
   createConnectAnchor()
                       throws Exception
   {
      GenericConnectAnchor createdConnectAnchor = null;

      /*
       * Some services such as services in infra node do not have a VC extension
       * key.
       */
      if (this.key != null) {
         if ( this.key == TestConstants.VC_EXTENSION_KEY) {
            createdConnectAnchor =
               new ConnectAnchor(this.hostName,this.portNumber,
                                 this.keyStorePath);
         } else if (this.key == TestConstants.PBM_EXTENSION_KEY) {
            createdConnectAnchor = PbmConnectAnchorUtils.createPbmConnectAnchor(customObjects, endpointUrl);
         } else {
            /*
             * using reflection to get the corresponding connect anchor
             */
            String className = null;
            /*
             * If multiple extensions are registered with one instance of VC,
             * Now, we follow a standard and register the extension like,
             * "com.vmware.vcDr-user1".
             */
            if (this.key.startsWith(TestConstants.DR_EXTENSION_KEY) ) {
               className = TestConstants.DRCONNECTANCHOR_CLASSNAME;
            } else if (this.key.equals
               (TestConstants.INTEGRITY_EXTENSION_KEY) ) {
               className = TestConstants.VCCONNECTANCHOR_CLASSNAME;
            } else if (this.key.equals
               (TestConstants.CONVERTER_EXTENSION_KEY)) {
               className = TestConstants.CONVERTERCONNECTANCHOR_CLASSNAME;
            } else if (this.key.equals(TestConstants.SM_EXTENSION_KEY)){
               className = TestConstants.SMSCONNECTANCHOR_CLASSNAME;
            } else if (this.key.equals(TestConstants.XHM_EXTENSION_KEY)){
               className = TestConstants.XHMCONNECTANCHOR_CLASSNAME;
            } else if (this.key.equals(TestConstants.VSM_EXTENSION_KEY)){
               className = TestConstants.VSMCONNECTANCHOR_CLASSNAME;
            } else if( this.key.equals(SpsTestConstants.EXTENSION_KEY)){
               className = SpsTestConstants.CONNECTANCHOR_CLASSNAME;
            } else if (this.key.equals(TestConstants.VP_EXTENSION_KEY)){
               className = TestConstants.VPCONNECTANCHOR_CLASSNAME;
               boolean useSSL = false;
               if(this.customInfo.containsKey(TestConstants.XML_USESSL)) {
                  useSSL =
                     Boolean.parseBoolean(this.customInfo.get(TestConstants.XML_USESSL));
               }
               String vasaVersionString = this.customInfo
                        .get(TestConstants.XML_VERSION);
               VasaVersion vasaVersion = VasaVersion
                        .fromVersionString(vasaVersionString);
               if (vasaVersion == null) {
                  log.warn("Unknown VASA provider version in configuration file: {}",
                           vasaVersionString);
               }
               String protocolString = this.customInfo
                        .get(TestConstants.XML_ENDPOINT_PROTOCOL);
               WebServiceEndpointProtocol protocol = WebServiceEndpointProtocol
                        .fromProtocolString(protocolString);
               if (protocol == null) {
                  log.warn("Unknown VP endpoint protocol in configuration file: {}",
                           protocolString);
               }
               createdConnectAnchor = new VPConnectAnchor(hostName, portNumber,
                        useSSL,
                        this.customInfo.get(TestConstants.XML_SERVICE_ENDPOINT),
                        vasaVersion, protocol);
            } else if (this.key.equals(TestConstants.EAM_EXTENSION_KEY)) {
               className = TestConstants.EAMCONNECTANCHOR_CLASSNAME;
            }
            /*
             * As connectAnchor for Vendor Provider is already created, we do not
             * want to visit this block of code.
             */
            if (!this.key.equals(TestConstants.VP_EXTENSION_KEY)) {
               Class derivedAnchorClass = Class.forName(className);
               /*
                * Populate the constructor classes 1- Get constructor that accepts
                * (URL) as argument 2- Make argsValues that contains (URLg) values
                * 3- invoke .newInstance and pass constructor object to create it
                * 4- cast it from Object to GenericConnectAnchor
                */
               Class[] anchorArgsClass = new Class[] { URL.class };
               Object[] argsValues = new Object[] { this.endpointUrl };

               Constructor derivedConstructor = derivedAnchorClass
                        .getConstructor(anchorArgsClass);
               Object derivedAnchorObj = derivedConstructor
                        .newInstance(argsValues);
               createdConnectAnchor = (GenericConnectAnchor) derivedAnchorObj;
            }
         }
      } else {
         log.info("Extension key is null, Some services such as services " +
                  "in the infra node do not have an extension key in VC");
      }
      return createdConnectAnchor;
   }

   @Override
   public boolean equals(Object obj)
   {
      if (this == obj) {
         return true;
      }
      if ((obj == null) || (obj.getClass() != this.getClass())) {
         return false;
      }
      ServiceInfo compareObject = (ServiceInfo) obj;
      boolean equals =
               (endpointUrl == compareObject.endpointUrl || (endpointUrl != null && endpointUrl
                        .equals(compareObject.endpointUrl)));
      equals = equals &&
               (key == compareObject.key || (key != null && key
                        .equals(compareObject.key)));
      equals = equals &&
               (hostName == compareObject.hostName || (hostName != null && hostName
                        .equals(compareObject.hostName)));
      equals = equals &&
               (keyStorePath == compareObject.keyStorePath || (keyStorePath != null && keyStorePath
                        .equals(compareObject.keyStorePath)));
      equals = equals &&
               (locale == compareObject.locale || (locale != null && locale.equals(locale)));
      equals = equals &&
               (parentVc == compareObject.parentVc ||
                        (parentVc != null && parentVc.equals(compareObject.parentVc)));
      equals = equals && (infraNode == compareObject.infraNode ||
                        (infraNode != null && infraNode.equals(compareObject.infraNode)));
      equals = equals &&
               (password == compareObject.password ||
                        (password != null && password.equals(compareObject.password)));
      equals = equals && (portNumber == compareObject.portNumber);
      equals = equals &&
         (serviceDescription == compareObject.serviceDescription ||
                  (serviceDescription != null && serviceDescription
                  .equals(compareObject.serviceDescription)));
      equals = equals &&
               (userName == compareObject.userName ||
                        (userName != null && userName.equals(compareObject.userName)));
      equals = equals &&
               (customInfo == compareObject.customInfo ||
                        (customInfo != null && customInfo.equals(compareObject.customInfo)));

      return equals;
   }

   @Override
   public int hashCode()
   {
      int hash = 7;
      hash = 31 * hash + (null == endpointUrl ? 0 : endpointUrl.hashCode());
      hash = 31 * hash + (null == key ? 0 : key.hashCode());
      hash = 31 * hash + (null == hostName ? 0 : hostName.hashCode());
      hash = 31 * hash + (null == hostName ? 0 : hostName.hashCode());
      hash = 31 * hash + (null == keyStorePath ? 0 : keyStorePath.hashCode());
      hash = 31 * hash + (null == locale ? 0 : locale.hashCode());
      hash = 31 * hash + (null == parentVc ? 0 : parentVc.hashCode());
      hash = 31 * hash + (null == infraNode ? 0 : infraNode.hashCode());
      hash = 31 * hash + (null == serviceDescription ? 0 : serviceDescription.hashCode());
      hash = 31 * hash + (null == userName ? 0 : userName.hashCode());
      hash = 31 * hash + (null == customInfo ? 0 : customInfo.hashCode());
      hash = 31 * hash + portNumber;
      return hash;
   }
}

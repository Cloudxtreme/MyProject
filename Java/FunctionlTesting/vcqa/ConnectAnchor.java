/* ************************************************************************
 *
 * Copyright 2010-2014 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa;

import java.net.ProxySelector;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.ws.BindingProvider;
import javax.xml.ws.Service;
import javax.xml.ws.handler.MessageContext;

import org.apache.commons.configuration.Configuration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import sun.net.util.IPAddressUtil;

import com.sun.xml.ws.client.ClientTransportException;
import com.sun.xml.ws.developer.JAXWSProperties;
import com.vmware.vc.AboutInfo;
import com.vmware.vc.InternalVimPortType;
import com.vmware.vc.InternalVimService;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.ServiceContent;
import com.vmware.vcqa.execution.TestDataHandler;
import com.vmware.vcqa.ssl.CustomProxySelector;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.MORConstants;
import com.vmware.vcqa.vim.ServiceInstance;

/**
 * ConnectAnchor is an anchor class that allows the client to establish
 * connection to host agent/VC Webservice.
 */
public class ConnectAnchor extends GenericConnectAnchor
{
   private static final Logger log           = LoggerFactory
                                                      .getLogger(ConnectAnchor.class);
   private static Service      svc           = null;
   protected boolean           SSL           = false;
   protected boolean           useHttpTunnel = false;
   protected int               vcHttpPort    = 80;
   protected String            sdkTunnelUri  = "https://sdkTunnel:8089/sdk/vimService";
   private InternalVimPortType portType;
   private String              cookie;

   /**
    * Constructor to initialize, establish socket (SSL or non-SSL) connection
    * with host agent and create a host binding
    *
    * @param hostName hostName where host agent or VC WebService is running
    * @param port port where host agent or VC WebService is running
    *
    * @throws Exception
    */
   @Deprecated
   public ConnectAnchor(String hostName,
                        int port,
                        String keyStorePath)
                                            throws Exception
   {
      this.hostName = hostName;
      this.port = port;
      setupSsl();
      setupHttpTunneling();
      setup();
      setupUserAgent();
   }

   /**
    * Put an default constructor so that the child class of ConnectAnchor can have customized constructor
    * Below is a case in point
    * to verify the server ssl certificate, one needs to do it in X509TrustManager.checkServerTrusted in
    * GenericConnectAnchor.setConnectionProperties
    * here is the step:
    *   1. create a new class inheriting from ConnectAnchor
    *   2. pass the trusted certificates from the constructor of the new class
    *   3. override GenericConnectAnchor.setConnectionProperties
    *
    *   refer to com.vmware.vcqa.certmgr.CertMgrConnectAnchor

    */
   public ConnectAnchor(){};

   /**
    * Constructor to initialize, establish socket (SSL or non-SSL) connection
    * with host agent and create a host binding
    *
    * @param changeContext CHANGE AUDIT ITB- K/L: Change Audit Tag for SOAP
    *           Header
    * @param hostName hostName where host agent or VC WebService is running
    * @param port port where host agent or VC WebService is running
    *
    * @throws Exception
    */
   public ConnectAnchor(String changeContext,
                        String hostName,
                        int port)
                                 throws Exception
   {
      super.changeContextTagForSOAP = changeContext;
      this.hostName = hostName;
      this.port = port;
      setupSsl();
      setupHttpTunneling();
      setup();
   }

   /**
    * Constructor to initialize, establish socket (SSL or non-SSL) connection
    * with host agent and create a host binding.
    *
    * @param hostName hostName where host agent or VC WebService is running
    * @param port port where host agent or VC WebService is running
    * @throws Exception
    */
   public ConnectAnchor(String hostName,
                        int port)
                                 throws Exception
   {
      this.hostName = hostName;
      this.port = port;
      setupSsl();
      setupHttpTunneling();
      setup();
   }

   /**
    * Constructor to initialize, establish socket (SSL or non-SSL) connection
    * with host agent and create a host binding Introduced as fix for PR 857251.
    *
    * @param hostName hostName where host agent or VC WebService is running
    * @param port port where host agent or VC WebService is running
    * @param enableHttpTunneling Flag to enable or disable Http tunneling.
    * @throws Exception
    */
   public ConnectAnchor(String hostName,
                        int port,
                        boolean enableHttpTunneling)
                                                    throws Exception
   {
      this.hostName = hostName;
      this.port = port;
      setupSsl();
      this.useHttpTunnel = enableHttpTunneling;
      setup();
   }

   /**
    * Setup will create the VimBinding Object using InternalVimService and
    * endpoint. Endpoint is a url constructed using hostname, port and protocol
    * (http or https)
    *
    * @throws Exception
    */
   protected void setup()
                         throws Exception
   {
      boolean connectAnchorCreated = false;
      if (this.hostName == null || this.port == 0) {
         log.error("ConnectAnchor: Either the HostName or Port is invalid");
         log.error("ConnectAnchor: HostName" + this.hostName);
         log.error("ConnectAnchor: port" + this.port);
      } else {
         if (this.useHttpTunnel) {
            /*
             * Connect to the sdktunnel URI-
             * https://sdkTunnel:8089/sdk/vimService
             */
            endPointURL = getSdkTunnelUri();
         } else {
            /*
             * /sdk is a proxy path for WebService
             */
            if (this.SSL) {
               if (IPAddressUtil.isIPv6LiteralAddress(this.hostName)) {
                  endPointURL = "https://[" + this.hostName + "]:" + this.port
                           + "/sdk";
               } else {
                  endPointURL = "https://" + this.hostName + ":" + this.port
                           + "/sdk";
               }
            } else {
               if (IPAddressUtil.isIPv6LiteralAddress(this.hostName)) {
                  endPointURL = "http://[" + this.hostName + "]:" + this.port
                           + "/sdk";
               } else {
                  endPointURL = "http://" + this.hostName + ":" + this.port
                           + "/sdk";
               }
            }
         }
         createService(endPointURL);
         if (this.stub == null) {
            log.error("ConnectAnchor: Failed to create VimBinding");
         } else {
            createServiceInstance();
            createServiceContent();
            if (this.serviceContent == null) {
               log.error("ConnectAnchor: Failed to create Service Content");
            } else {
               connectAnchorCreated = true;
            }
         }
      }
      if (!connectAnchorCreated) {
         log.error("ConnectAnchor: Failed to create Connect Anchor.");
         throw new Exception("Failed to create connect anchor for VIM service");
      }
   }

   /**
    * setupUserAgent will check fo the system variable "USER-AGENT" if an
    * incorrect user agent is found the it throws an Exception.
    *
    * @throws Exception
    */
   protected void setupUserAgent()
                                  throws Exception
   {
      log.info("Checking for the UserAgent... ");
      Boolean userAgentFound = false;
      if (System.getProperty("USER-AGENT") != null
               && System.getProperty("USER-AGENT").length() > 0) {
         String testUserAgent = System.getProperty("USER-AGENT");
         for (String userAgent : TestConstants.ALL_USER_AGENT_LIST) {
            if (userAgent.equals(testUserAgent)) {
               log.info("Running with the userAgent '" + testUserAgent + "'");
               userAgentFound = true;
               break;
            }
         }
         if (!userAgentFound) {
            log.error("The user agent is not recognized '" + testUserAgent
                     + "'");
            throw new Exception(
                     "The user agent is not recognized "
                              + testUserAgent
                              + ""
                              + "Please check the user agent passed as -USER-AGENT vmAgrs from the test");
         }
      } else {
         log.info("No user agent is set. Running with the default user agent {}",
                  portType);
      }
   }

   /**
    * Create binding using end point URL and the VIM service
    *
    * @param endPointURL - URL for the VIM service
    * @param service - The VIM service
    *
    * @throws Exception
    */
   @Override
   protected void createService(String endPointURL)
                                                   throws Exception
   {
      log.info("Endpoint URL for VIM Binding = " + endPointURL);
      setConnectionProperties();
      if (this.useHttpTunnel) {
         setupProxyProperties();
      }
      synchronized (ConnectAnchor.class) {
         if (svc == null) {
            log.info("Creating new VIM service...");
            stub = new InternalVimService();
            svc = stub;
         } else {
            log.info("Using cached VIM Service: " + svc);
            stub = svc;
         }
      }
      log.info("Service Name: {}", stub.getServiceName());
      log.info("Service WSDL: {}", stub.getWSDLDocumentLocation());
      // Get the port from service
      portType = ((InternalVimService) stub).getInternalVimPort();

      log.info("Java Version: {}", System.getProperty("java.version"));
      log.info("Java Arch   : {}", System.getProperty("sun.arch.data.model"));
      log.info("Setting endpoint URL to Port...");
      Map<String, Object> context = ((BindingProvider) getPortType())
               .getRequestContext();
      context.put(BindingProvider.ENDPOINT_ADDRESS_PROPERTY, endPointURL);
      context.put(BindingProvider.SESSION_MAINTAIN_PROPERTY, true);

      context.put("Content-Encoding", Collections.singletonList("gzip"));
      context.put("Accept-Encoding", Collections.singletonList("gzip"));

      context.put(JAXWSProperties.CONNECT_TIMEOUT, TestConstants.SOCKET_TIMEOUT);
      context.put("com.sun.xml.ws.request.timeout",
               TestConstants.SOCKET_TIMEOUT);
      context.put("Proxy-Connection", "keep-alive");
      System.getProperties().setProperty("http.keepAlive", "true");
      System.getProperties().setProperty("https.keepAlive", "true");
      log.info("Port Object : {}", portType);
      addHandler((BindingProvider) portType);
   }

   /**
    * Setup proxy properties on the service client of the stub. Set proxy host,
    * proxy port for the client to send http requests to.
    *
    * @throws Exception
    */
   protected void setupProxyProperties()
                                        throws Exception
   {
      log.info("Selecting CustomProxySelector with host {}", hostName);
      ProxySelector.setDefault(new CustomProxySelector(this.hostName,
               getVCHttpPort(), ProxySelector.getDefault()));
   }

   /**
    * Returns VC's http port.
    *
    * @return vc's http port.
    */
   protected int getVCHttpPort()
                                throws Exception
   {
      /*
       * Get vc's httpport from internalsic::proxyservice::gethttpport?
       */
      return this.vcHttpPort;
   }

   /**
    * Get sdktunnel URI to be used as stub's endpoint.
    *
    * @return sdk tunnel uri
    */
   protected String getSdkTunnelUri()
                                     throws Exception
   {
      return this.sdkTunnelUri;
   }

   /**
    * Create binding using end point URL for VIM service and the VIM service
    *
    * @param endPointURL - URL for the VIM service
    * @param service - The VIM service
    *
    * @throws MethodFault, Exception
    */
   @Override
   protected void createServiceContent()
                                        throws Exception
   {
      Configuration configData = TestDataHandler.getSingleton().getData();
      boolean isRunSuitesInParallel = configData.getBoolean(
               TestConstants.TESTINPUT_RUN_SUITES_IN_PARALLEL, false);
      try {
         this.serviceContent = new ServiceInstance(this)
                  .retrieveServiceContent(serviceInstanceMor);
      } catch (ClientTransportException ctex) {
         /*
          * Check if running the suites in parallel is enabled.
          */
         if (isRunSuitesInParallel) {
            log.info("Multiple suites running in parallel, This vpxd Service "
                     + "might be currently stopped by another thread: ");
            /*
             * TODO The code to check the status of the vpxd service can be
             * moved to the com.vmware.vcqa.util.services.VpxServices.
             */
            log.info("Sleeping for upto 300 seconds for the vpxd service to "
                     + "be up");
            for (int i = 0; i <= 30; i++) {
               try {
                  /*
                   * Sleep for 10 seconds.
                   */
                  Thread.sleep(10 * 1000);
                  this.serviceContent = new ServiceInstance(this)
                           .retrieveServiceContent(serviceInstanceMor);
                  /*
                   * No exception thrown, and the api call succeeded, continue.
                   */
                  break;
               } catch (ClientTransportException ctex1) {
                  log.debug("vpxd service still unavailable");
               }
            }
         } else {
            /*
             * Re-throw the exception, Multiple threads/suites not running in
             * parallel.
             */
            throw ctex;
         }
      }
      if (this.serviceContent != null) {
         log.info("--------------------------------------------");
         log.info("VIM ConnectAnchor: Connected Server Info :");
         LogUtil.printObject(this.getAboutInfo());
         log.info("--------------------------------------------");
      }
   }

   /**
    * Create Service Instance
    *
    * @throws MethodFault, Exception
    */
   @Override
   protected void createServiceInstance()
                                         throws Exception
   {
      this.serviceInstanceMor = new ManagedObjectReference();
      serviceInstanceMor.setType(MORConstants.MORSICTYPE);
      serviceInstanceMor.setValue(MORConstants.MORSICVALUE);
   }

   /**
    * Get the AboutInfo object for this Service
    *
    * @return AboutInfo object
    */
   @Override
   public AboutInfo getAboutInfo()
   {
      return ((ServiceContent) serviceContent).getAbout();
   }

   /**
    * Get the binding to VIM service
    *
    * @return InternalVimPortType object
    */
   @Override
   public InternalVimService getService()
   {
      return (InternalVimService) stub;
   }

   @Override
   public InternalVimPortType getPortType()
   {
      getCookie();
      return (InternalVimPortType) portType;
   }

   /**
    * Get ServiceContent(SC) object
    *
    * @return Reference to Service Content object
    */
   public ServiceContent getSC()
   {
      return (ServiceContent) this.serviceContent;
   }

   /**
    * Setup SSL properties
    *
    */
   protected void setupSsl()
                          throws Exception
   {
      String useSSL = System.getProperty(TestConstants.USE_SSL);
      if (useSSL != null && useSSL.equalsIgnoreCase(TestConstants.BOOL_TRUE)) {
         this.SSL = true;
      } else {
         useSSL = System.getenv(TestConstants.USE_SSL);
         if (useSSL != null && useSSL.equalsIgnoreCase(TestConstants.BOOL_TRUE)) {
            this.SSL = true;
         }
      }
   }

   /**
    * Determines if httpTunneling should be used while creating the binding
    * stub.
    *
    * @throws Exception
    */
   private void setupHttpTunneling()
                                    throws Exception
   {
      String httpTunneling = System
               .getProperty(TestConstants.USE_HTTP_TUNNELING);
      if (httpTunneling != null
               && httpTunneling.equalsIgnoreCase(TestConstants.BOOL_TRUE)) {
         this.useHttpTunnel = true;
      } else {
         httpTunneling = System.getenv(TestConstants.USE_HTTP_TUNNELING);
         if (httpTunneling != null
                  && httpTunneling.equalsIgnoreCase(TestConstants.BOOL_TRUE)) {
            this.useHttpTunnel = true;
         }
      }
      log.info("httpTunneling=" + this.useHttpTunnel);
   }

   /**
    * Gets the http session cookie for this session.
    *
    * @return Cookie The String cookie.
    */
   public String getHttpSessionCookie()
   {
      return cookie;
   }

   @SuppressWarnings("unchecked")
   public void getCookie()
   {
      String oldCookie = cookie;
      Map<String, Object> resContext = ((BindingProvider) portType)
               .getResponseContext();
      Map<String, List<String>> httpHeaders = new HashMap<String, List<String>>();
      if (resContext != null) {// get headers from response
         httpHeaders = (Map<String, List<String>>) resContext
                  .get(MessageContext.HTTP_RESPONSE_HEADERS);
         // log.info("VIM HTTP headers: {}", httpHeaders);
         if (httpHeaders != null) {
            List<String> cookies = httpHeaders.get("Set-cookie");
            if (cookies != null) {
               for (String c : cookies) {
                  if (c.contains(TestConstants.VC_SESSION_COOKIE_NAME)) {
                     log.info("Got VC session cookie: {}", c);
                     cookie = c;
                     if (!cookie.equals(oldCookie)) {
                        log.warn("Warning : cookie reset from " + oldCookie);
                     }
                     break;
                  }
               }
            }
         }
      }
   }

   // @SuppressWarnings("unchecked")
   // public void getCookie13() {
   // // check for cookie being not null here.
   // // it seems we have to maintain the session on our own.. kiri
   // Map<String, Object> reqContext = ((BindingProvider)
   // portType).getRequestContext();
   // Map<String, Object> resContext = ((BindingProvider)
   // portType).getResponseContext();
   // Map<String, List<String>> httpHeaders = new HashMap<String,
   // List<String>>();
   // if (resContext != null) {// get headers from response and check for
   // cookie..
   // httpHeaders = (Map<String, List<String>>) resContext
   // .get(MessageContext.HTTP_RESPONSE_HEADERS);
   // log.info("HTTP headers: {} \t{}", x, httpHeaders);
   // if (httpHeaders != null) {
   // List<String> cookies = httpHeaders.get("Set-cookie");
   // if (cookies != null) {
   // StackTraceElement[] trace = Thread.currentThread().getStackTrace();
   // System.out.println(trace.toString());
   // for (String c : cookies) {
   // // System.out.println(">>>>>>>>>>>>> " + c);
   // if (c.contains(TestConstants.VC_SESSION_COOKIE_NAME)) {
   // log.info(" Iter-{} \tCookie GOT {}", x++, c);
   // // if(cookie==null){
   // cookie = c;
   // // }else{
   // // log.info("*** Using existing cookie: {}", cookie);
   // // }
   // break;
   // }
   // }
   // }
   // }
   // log.info(" Iter-{} \tCookie {}", x++, cookie);
   // // log.info("Setting Cookie: {}", cookie);
   // if (cookie != null) {
   // Map<String, List<String>> setHeaders = new HashMap<String,
   // List<String>>();
   // setHeaders.put("Cookie", Collections.singletonList(cookie));
   // reqContext.put(MessageContext.HTTP_REQUEST_HEADERS, setHeaders);
   // httpHeaders.put("Accept-Encoding", Collections.singletonList("gzip"));
   // }
   // }
   // // log.info("HTTP headers: {}", httpHeaders);
   // }

   public void clean()
   {
      stub = null;
      portType = null;
   }

   static int x = 0;

   /**
    * to tell if the ConnectAnchor object is constructed using an IPV6 or not if
    * a fully qualified hostname is passed, false will be returned
    *
    * @return true if an IPV6 is passed to construct a ConnectAnchor object
    */
   public boolean isIPv6ConnectAnchor()
   {
      return TestUtil.isIpv6Address(this.hostName);
   }

   /**
    * to tell if the ConnectAnchor object is constructed using an IPV4 or not if
    * a fully qualified hostname is passed, false will be returned
    *
    * @return true if an IPV4 is passed to construct a ConnectAnchor object
    */
   public boolean isIPv4ConnectAnchor()
   {
      return !isIPv6ConnectAnchor();
   }
}

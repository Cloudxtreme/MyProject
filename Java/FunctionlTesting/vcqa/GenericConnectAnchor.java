/* ************************************************************************
 *
 * Copyright 2007 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.Calendar;
import java.util.List;
import java.util.Set;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.Unmarshaller;
import javax.xml.namespace.QName;
import javax.xml.soap.SOAPElement;
import javax.xml.soap.SOAPEnvelope;
import javax.xml.soap.SOAPFactory;
import javax.xml.soap.SOAPFault;
import javax.xml.soap.SOAPHeader;
import javax.xml.soap.SOAPMessage;
import javax.xml.ws.BindingProvider;
import javax.xml.ws.Service;
import javax.xml.ws.handler.Handler;
import javax.xml.ws.handler.MessageContext;
import javax.xml.ws.handler.soap.SOAPHandler;
import javax.xml.ws.handler.soap.SOAPMessageContext;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.AboutInfo;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.operations.NullOperationLogger;
import com.vmware.vcqa.operations.VCOperationLogger;
import com.vmware.vcqa.util.TestUtil;
/**
 * GenericConnectAnchor the base class for ConnectAnchor and
 * ExtensionConnectAnchor. It contains all the common functionality of the two
 * derived classes.
 */
public abstract class GenericConnectAnchor
{
   private static final Logger log = LoggerFactory.getLogger(GenericConnectAnchor.class);
   protected String hostName                            = null;
   protected int port                                   = 0;
   protected String endPointURL                            = null;

   public Service stub = null;
   protected Object serviceContent = null;
   protected ManagedObjectReference serviceInstanceMor  = null;
   protected String changeContextTagForSOAP             = null;

   /**
    * Constructor to set the Dummy SSL Factory to axis, for any anchor created
    */
   protected GenericConnectAnchor () {
   }

   /**
    * Get binding to the service
    *
    * @return java.rmi.Remote object
    */
   protected abstract Service
   getService();

   /**
    * Get information about the service. <br>
    * Note: No more an abstract method.
    * @return AboutInfo object
    */
    public AboutInfo getAboutInfo() {
        return null;
    }

   /**
    * Create binding between the service stub and the end point url
    *
    * @param url     - URL where service is hosted
    * @param service - the service being hosted at the specified URL
    *
    * @throws Exception
    */
   protected abstract void
   createService(String url)
                 throws Exception;

   /**
    * Create the service content <br>
    * Note: No more an abstract method.<br>
    * @throws MethodFault, Exception
    */
    protected void createServiceContent() throws Exception {
    }

   /**
    * Create Service instance
    *
    * @throws MethodFault, Exception
    */
   protected abstract void
   createServiceInstance()
                         throws   Exception;

   /**
    * Get the portType from the service.
    * @return the portType proxy.
    */
   public abstract Object getPortType();

   /**
    * Get the service content for the service
    *
    * @return service object
    */
   public abstract Object
   getSC();

   /**
    * Setup the connect anchor by creating getting the end point URL and binding
    * it to the service and creating service instance and service content
    *
    * @throws Exception
    */
   protected abstract void
   setup()
         throws Exception;

   /**
    * Get ServiceInstance MOR
    *
    * @return ServiceInstance MOR
    */
   public ManagedObjectReference
   getServiceInstance()
   {
      return this.serviceInstanceMor;
   }

   /**
    * Returns the Session API Type
    *
    * @return API Type in String
    */
   public String
   getAPIType()
   {
      return this.getAboutInfo().getApiType();
   }

   /**
    * Returns the Session API Version
    *
    * @return Version type in String
    */
   public String
   getAPIVersion()
   {
      return this.getAboutInfo().getApiVersion();
   }

   /**
    * Get the Build Number
    *
    * @return Build number in String
    */
   public String
   getBuild()
   {
      return this.getAboutInfo().getBuild();
   }

   /**
    * Get the name of the connected host(hostd/vc) for this session
    *
    * @return host name
    */
   public String
   getHostName()
   {
      return this.hostName;
   }

   /**
    * Get the port of the service on the connected host(hostd/vc) for
    * this session
    *
    * @return port number
    */
   public int
   getPort()
   {
      return this.port;
   }

   /**
    * Get endpoint URL where the service is hosted
    *
    * @return end point URL of service
    */
   public String
   getEndPointUrl()
   {
      return this.endPointURL;
   }

   /**
    * Set Binding object's properties. This function is used when creating
    * binding between endPointURL and service using createBinding().
    *
    * TODO  Some of the below need to be done only once per jvm , find a better place?.
    */
	protected void setConnectionProperties() throws Exception {
		TrustManager[] trustAllCerts = new TrustManager[] { new X509TrustManager() {
			@Override
			public X509Certificate[] getAcceptedIssuers() {
				return null;
			}

			@Override
			public void checkServerTrusted(X509Certificate[] chain, String authType)
			        throws CertificateException {
				// Auto-generated method stub
			}

			@Override
			public void checkClientTrusted(X509Certificate[] chain, String authType)
			        throws CertificateException {
				// Auto-generated method stub
			}
		} };
		// Install the all-trusting trust manager
		SSLContext sslc = SSLContext.getInstance("SSL");
		// Create empty HostnameVerifier
		HostnameVerifier hv = new HostnameVerifier() {
			public boolean verify(String arg0, SSLSession arg1) {
				return true;
			}
		};
		sslc.init(null, trustAllCerts, new java.security.SecureRandom());
		HttpsURLConnection.setDefaultSSLSocketFactory(sslc.getSocketFactory());
		HttpsURLConnection.setDefaultHostnameVerifier(hv);
//		HttpsURLConnection.setDefaultHostnameVerifier(hv);
		log.info("Trusted all certificates..");
	}

   /**
    * Adds handler to print MethodFaults. This will be helpful for debugging
    * unexpected SoapFaultException.
    *
    * @param bindingProvider BindingProvider(PortType Object)
    */
   protected void addHandler(BindingProvider bindingProvider)
   {
      List<Handler> handlers = bindingProvider.getBinding().getHandlerChain();
      handlers.add(new SOAPHandler<SOAPMessageContext>()
      {
         public boolean handleMessage(SOAPMessageContext context)
         {
            try {
               Boolean outboundProp = (Boolean) context
                     .get(MessageContext.MESSAGE_OUTBOUND_PROPERTY);
               if (outboundProp.booleanValue()) {
                  //Add operationID element in SOAP message header.
                  SOAPFactory factory = SOAPFactory.newInstance();
                  SOAPElement opIdElement = factory.createElement("operationID", "vcqe", "http://www.vmware.com/vcqe");
                  String opId = "OpId-" + Calendar.getInstance().getTimeInMillis();
                  opIdElement.setTextContent(opId);
                  SOAPEnvelope envelope = context.getMessage().getSOAPPart()
                        .getEnvelope();
                  SOAPHeader header = envelope.getHeader();
                  if(header==null){
                     header = envelope.addHeader();
                  }
                  header.addChildElement(opIdElement);
                  // Log operation id & operation name except for operations
                  // specified in config file.
                  SOAPElement operationElement = (SOAPElement) context.getMessage().getSOAPBody().getChildElements().next();
                  String operationName = operationElement.getNodeName();

                  if (log.isInfoEnabled()) {
                     if (!TestConstants.OPERATIONS_IGNORED_FOR_OPID_LOGGING.contains(operationName)) {
                        log.info("Operation ID for the operation  -  "
                                 + operationName + ":: " + opId);
                     }
                  }
                  VCOperationLogger vcOperationLogger = VCOperationLogger.getInstance();
                  vcOperationLogger.logOperations(hostName, operationName);
               }
            } catch(Exception ex) {
               log.warn("Exception thrown", ex);
            }
            return true;
         }

         @SuppressWarnings("rawtypes")
         public boolean handleFault(SOAPMessageContext context)
         {
            try {
               SOAPMessage message = context.getMessage();
               message.getSOAPPart().getEnvelope().addNamespaceDeclaration(
                        "xsd", "http://www.w3.org/2001/XMLSchema");
               SOAPFault fault = message.getSOAPBody().getFault();
               Unmarshaller unmarshaller = TestUtil.jaxbContext.createUnmarshaller();
               JAXBElement xx = (JAXBElement) unmarshaller.unmarshal(fault.getDetail().getFirstChild());
               Object obj = xx.getValue();
               LogUtil.printObject(obj);
               log.info("Printing Method Fault: \n{}", obj);
            } catch (Exception e) {
               log.debug("Got Exception", e);
            }
            return true;
         }

         public void close(MessageContext context)
         {
            // nothing
         }

         public Set<QName> getHeaders()
         {
            return null;
         }
      });
      bindingProvider.getBinding().setHandlerChain(handlers);
   }
}
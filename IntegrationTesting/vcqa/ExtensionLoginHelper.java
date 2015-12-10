/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa;

import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLClassLoader;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.cert.Certificate;
import java.util.Enumeration;
import java.util.Map;

import javax.net.ssl.HttpsURLConnection;
import javax.xml.ws.BindingProvider;

import org.apache.commons.codec.binary.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.sun.xml.ws.developer.JAXWSProperties;
import com.vmware.vcqa.ssl.AuthSSLProtocolSocketFactory;
import com.vmware.vcqa.ssl.CertificateLoadException;
import com.vmware.vcqa.ssl.SSLUtil;
/**
 * Helper class for extensions which deals with the signatures. It has utility
 * methods to get the public/private keys for a extension, Signs the string for
 * login extension .
 */
public class ExtensionLoginHelper
{

   private static final Logger log = LoggerFactory.getLogger(ExtensionLoginHelper.class);
   private static ExtensionLoginHelper singleton         = null;

   /**
    * Private Constructor
    */
   private ExtensionLoginHelper()
   {
   }

   /**
    * Public api which returns the singleton instance
    *
    * @return Returns the singleton instance of this class
    */
   public static ExtensionLoginHelper singleton()
   {
      if (singleton == null) {
         singleton = new ExtensionLoginHelper();
      }
      return singleton;
   }

   /**
    * Assumes that the files are available in VMQAHOME/runlists/VC/Java/sslcert folder
    *
    * @param fileName Certificate/key file name for extension login tests
    *
    * @return Complete path to the file name passed
    * @throws Exception -
    */
   private String getabsolutePath(String fileName) throws Exception
   {
      String certPath = "/sslcert/" + fileName;
      
      URL resource = getClass().getResource(certPath);
      if(resource == null){
    	  log.info("resource=null, certPath=" + certPath + ", curDir=" + System.getProperty("user.dir"));
    	  log.info("classpath=\n" + getClasspathString());
      }
      return resource.getFile();
   }

   /**
    * Creates a keystore/truststore with the keystorepath, type and password
    *
    * @param keystorePath keystore path
    * @param keystoreType keystore type (PKCS12/JKS)
    * @param keystorePass keystore password
    * @return a keystore instance with the given keystorepath, type and password
    * @throws Exception -
    */
   private KeyStore
   createKeystore(String keystorePath,
                  String keystoreType,
                  String keystorePass)
                  throws Exception
   {
      KeyStore ks = null;
      try {
    	 log.info("keystorePath=" + keystorePath + ", keystoreType=" + keystoreType +", keystorePass=" + keystorePass);
         URL keystoreUrl = new File(getabsolutePath(keystorePath)).toURI().toURL();
         log.info("Using Keystore URL: " + keystoreUrl);
         ks = SSLUtil.createKeyStore(keystoreUrl, keystoreType, keystorePass);
         log.info("Keystore certificates:");
         if (ks.aliases() != null) {
            Enumeration<String> aliases = ks.aliases();
            while (aliases.hasMoreElements()) {
               String alias = aliases.nextElement();
               log.info("Alias: " + alias);
               log.info("Certificate type: "
                        + ks.getCertificate(alias).getType());
               log.info("Certificate public key: "
                        + ks.getCertificate(alias).getPublicKey());
            }
         }
      } catch (MalformedURLException e) {
         log.error("Unable to make URL out of keystore path." + e);
      } catch (KeyStoreException ke) {
         log.error("Keystore exception:" + ke);
      } catch (CertificateLoadException cle) {
         log.error("Unable to create a keystore from keystore url."
                  + cle);
      }
      return ks;
   }

   /**
    * Creates a SocketFactory with the truststore and keystore as the
    * AuthSSLProtocolSocketFactory, and uses this socketfactory for
    * https connections
    *
    * @param portType, on which custom protocol handler needs to be set.
    * @param keystoreFileName  Filename of the keystore . Looks for this file
    *                          in sslCert folder
    * @throws Exception -
    */
   public void
   registerCertificateWithSocketFactory(Object portType,
                                        String keystoreFileName)
                                        throws Exception
   {
	   // kiri Nov 9, 2011
	      KeyStore keystore = createKeystore(keystoreFileName, TestConstants.KEYSTORE_TYPE,TestConstants.KEYSTORE_PASSWORD);
	      AuthSSLProtocolSocketFactory socketFactory =
	         new AuthSSLProtocolSocketFactory(keystore,TestConstants.KEYSTORE_PASSWORD, keystore, null, null);
	      if(portType instanceof BindingProvider) {
	         Map<String, Object> context = ((BindingProvider)portType).getRequestContext();
	         HttpsURLConnection.setDefaultSSLSocketFactory(socketFactory.getSSLContext().getSocketFactory());
	         context.put(JAXWSProperties.SSL_SOCKET_FACTORY, socketFactory.getSSLContext().getSocketFactory());
	         log.info("New default SSL Factory {}",HttpsURLConnection.getDefaultSSLSocketFactory());
	      } else {
	         log.error("PortType Mismatch. Expected: InternalVimPortType or any other portType; Actual: "+portType.getClass().getName());
	      }
   }
   
   
   private String getClasspathString() {
	 StringBuffer clspath = new StringBuffer();
	 ClassLoader clsLoader = this.getClass().getClassLoader();
	 if (clsLoader == null) {
		 log.info("classLoader for " + this.getClass().getName() + " is null. Using systemClassLoader.");
		 clsLoader = ClassLoader.getSystemClassLoader();
	 }
	 
	 URL[] urls = ((URLClassLoader)clsLoader).getURLs();
	 for(int i=0; i < urls.length; i++) {
		 clspath.append(urls[i].getFile()).append("\n");
	 }    
	     
	 return clspath.toString();
  }

   /**
    * Method to get a certificate in PEM encoded format.
    * 
    * @param keystorePath - keystore filename
    * @param keystoreType - keystore type
    * @param keystorePass - kestore password
    *
    * @return - Returns certificate in PEM encode foramt
    *
    * @throws Exception
    */
   public String pemEncodeCert(String keystorePath,
                                  String keystoreType,
                                  String keystorePass)
      throws Exception
   {
      KeyStore keystore = createKeystore(
               keystorePath, keystoreType, keystorePass);
      Certificate cert = keystore.getCertificate(keystore.aliases().nextElement());
      String base64Cert = new String(Base64.encodeBase64(cert.getEncoded(),
               true));
      StringBuffer sb = new StringBuffer();
      sb.append("-----BEGIN CERTIFICATE-----\n");
      sb.append(base64Cert);
      sb.append("-----END CERTIFICATE-----\n");
      return sb.toString();
   }
}
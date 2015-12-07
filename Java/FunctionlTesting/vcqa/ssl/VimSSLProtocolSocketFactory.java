package com.vmware.vcqa.ssl;

import java.io.File;
import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.MalformedURLException;
import java.net.Socket;
import java.net.SocketAddress;
import java.net.URL;
import java.net.UnknownHostException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.SecureRandom;
import java.util.Enumeration;

import javax.net.SocketFactory;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;

import org.apache.commons.httpclient.ConnectTimeoutException;
import org.apache.commons.httpclient.params.HttpConnectionParams;
import org.apache.commons.httpclient.protocol.SecureProtocolSocketFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;



/**
 * Class that implements ProtocolSocketFactory that enables us to associate our
 * self-signed client certificate with an Axis request.
 *
 */
public class VimSSLProtocolSocketFactory implements SecureProtocolSocketFactory
{
   private static final Logger log = LoggerFactory.getLogger(VimSSLProtocolSocketFactory.class);
   private String keystorePath =
      "C:\\Documents and Settings\\All Users\\Application Data\\VMware\\VMware VirtualCenter\\SSL\\rui.pfx";
   private String keystorePass = "testpassword";
   private String sslProtocol = "SSL";
   private String keystoreType = "pkcs12";
   private SSLContext sslcontext = null;

   public
   VimSSLProtocolSocketFactory()
   {
      super();
      log.info("Creating " + this.getClass().getName());
   }

   public
   VimSSLProtocolSocketFactory(String keystoreFilePath,
                               String keystorePassword,
                               String sslProtocol)
   {
      super();
      if(keystoreFilePath != null){
         this.keystorePath = keystoreFilePath;
      }
      if(this.keystorePass != null){
         this.keystorePass = keystorePassword;
      }
      if(sslProtocol != null){
         this.sslProtocol = sslProtocol;
      }
      log.info("Creating " + this.getClass().getName());
   }


   /**
    * @see SecureProtocolSocketFactory#createSocket(java.lang.String,int,java.net.InetAddress,int)
    */
   public Socket
   createSocket(String host,
                int port,
                InetAddress clientHost,
                int clientPort)
                throws IOException, UnknownHostException {

      log.info("Creating a socket using: " + this.getClass().getName());
      return getSSLContext().getSocketFactory().createSocket(
          host,
          port,
          clientHost,
          clientPort
      );
   }

   /**
    * Attempts to get a new socket connection to the given host within the given time limit.
    * <p>
    * To circumvent the limitations of older JREs that do not support connect timeout a
    * controller thread is executed. The controller thread attempts to create a new socket
    * within the given limit of time. If socket constructor does not return until the
    * timeout expires, the controller terminates and throws an {@link ConnectTimeoutException}
    * </p>
    *
    * @param host the host name/IP
    * @param port the port on the host
    * @param clientHost the local host name/IP to bind the socket to
    * @param clientPort the port on the local machine
    * @param params {@link HttpConnectionParams Http connection parameters}
    *
    * @return Socket a new socket
    *
    * @throws IOException if an I/O error occurs while creating the socket
    * @throws UnknownHostException if the IP address of the host cannot be
    * determined
    */
   public Socket
   createSocket(final String host,
                final int port,
                final InetAddress localAddress,
                final int localPort,
                final HttpConnectionParams params)
                throws IOException, UnknownHostException,
                                    ConnectTimeoutException
   {
      log.info("Creating a socket using: " + this.getClass().getName());
      if (params == null) {
          throw new IllegalArgumentException("HttpConnectionParams may not be null");
      }
      int timeout = params.getConnectionTimeout();
      SocketFactory socketfactory = getSSLContext().getSocketFactory();
      Socket socket = null;
      if (timeout == 0) {
         socket = socketfactory.createSocket(host, port, localAddress, localPort);
      } else {
         socket = socketfactory.createSocket();
         SocketAddress localaddr = new InetSocketAddress(localAddress, localPort);
         SocketAddress remoteaddr = new InetSocketAddress(host, port);
         socket.bind(localaddr);
         socket.connect(remoteaddr, timeout);
      }
      return socket;
   }

   /**
    * @see SecureProtocolSocketFactory#createSocket(
    * java.lang.String,int)
    */
   public Socket
   createSocket(String host, int port)
                throws IOException, UnknownHostException
   {
      log.info("Creating a socket using: " + this.getClass().getName());
      return getSSLContext().getSocketFactory().createSocket(
          host,
          port
      );
   }

   /**
    * @see SecureProtocolSocketFactory#createSocket(
    * java.net.Socket,java.lang.String,int,boolean)
    */
   public Socket
   createSocket(Socket socket,
                String host,
                int port,
                boolean autoClose)
                throws IOException, UnknownHostException
   {
      log.info("Creating a socket using: " + this.getClass().getName());
      return getSSLContext().getSocketFactory().createSocket(
          socket,
          host,
          port,
          autoClose
      );
   }

   /**
    * Gets a custom SSL Context.
    * This is where the main work is done for this class.
    * The following are the steps are done:
    *
    * 1. Create a keystore using VC's certificate
    * 2. Create a KeyManagerFactory and TrustManagerFactory using this keystore
    * 3. Initialize an SSLContext using these factories
    *
    * @return SSLContext
    * @throws WebServiceClientConfigException
    * @throws Exception
    */
   protected SSLContext
   createSSLContext()
   {
      /*
       * Create KeyManager and TrustManager from one keystore -
       * we are using VC's self-signed certificate for both client & server trust material.
       */
      KeyStore keyStore = createKeystore();
      char[] passwordChars = this.keystorePass != null ?
               this.keystorePass.toCharArray() : null;
      SSLContext sslContext = null;
      try {
         KeyManagerFactory kmf = KeyManagerFactory.getInstance(
                  KeyManagerFactory.getDefaultAlgorithm());
         kmf.init(keyStore, passwordChars);
         TrustManagerFactory tmf =
             TrustManagerFactory.getInstance(
                      TrustManagerFactory.getDefaultAlgorithm());
         tmf.init(keyStore);
         TrustManager[] trustmanagers = tmf.getTrustManagers();
         boolean foundX509 = false;
         for (int i = 0; i < trustmanagers.length; i++) {
            if (trustmanagers[i] instanceof X509TrustManager) {
               foundX509 = true;
               log.info("Found X509 Trust Manager.");
            }
         }
         if(!foundX509){
            log.warn("No X509 trust manager to trust self-signed certs.");
         }
         /*
          * Configure a local SSLContext to use keystore
          */
         sslContext = SSLContext.getInstance(this.sslProtocol);
         sslContext.init(kmf.getKeyManagers(),
                         trustmanagers,
                         new SecureRandom());
      } catch (Exception e) {
         log.error(e.getMessage());
         e.printStackTrace();
      }

      log.info("Successfully created a custom SSL Context.");
      return sslContext;
   }

   /**
    * Creates a keystore on-the-fly using a known keystore URL,
    * type and password.
    *
    * @return KeyStore
    */
   private KeyStore
   createKeystore(){
      KeyStore ks = null;
      try {
         URL keystoreUrl = new File(this.keystorePath).toURI().toURL();
         log.info("Using Keystore URL: " + keystoreUrl);
         ks = SSLUtil.createKeyStore(keystoreUrl, this.keystoreType,
                  this.keystorePass);
         if(ks.aliases() != null){
            Enumeration<String> aliases = ks.aliases();
            while(aliases.hasMoreElements()){
               String alias = aliases.nextElement();
               log.info("Client SSL Certificate Alias: " + alias + " - Public Key: ");
               log.info(ks.getCertificate(alias).getPublicKey().toString());
            }
         }

      } catch (MalformedURLException e) {
         log.error("Unable to make URL out of keystore path.");
         e.printStackTrace();
      } catch (KeyStoreException ke){
         log.error("Keystore exception:");
         ke.printStackTrace();
      } catch (CertificateLoadException cle){
         log.error("Unable to create a keystore from keystore url.");
         cle.printStackTrace();
      }
      return ks;
   }

   public void
   setAsDefaultHttpsURLFactory()
                               throws IOException {
      HttpsURLConnection.setDefaultSSLSocketFactory(getSSLContext().getSocketFactory());
   }

   private SSLContext
   getSSLContext()
   {
      if (this.sslcontext == null) {
          this.sslcontext = createSSLContext();
      }
      return this.sslcontext;
  }

   public boolean equals(Object obj) {
      return ((obj != null) && obj.getClass().equals(
               VimSSLProtocolSocketFactory.class));
   }

   public int hashCode() {
      return VimSSLProtocolSocketFactory.class.hashCode();
   }

}

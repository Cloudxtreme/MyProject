/*
 * ****************************************************************************
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 * ****************************************************************************
 */

package com.vmware.vcqa.ssl;

import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketAddress;
import java.net.UnknownHostException;
import java.security.KeyStore;
import java.security.Principal;
import java.security.PrivateKey;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509KeyManager;
import javax.net.ssl.X509TrustManager;

import org.apache.commons.httpclient.ConnectTimeoutException;
import org.apache.commons.httpclient.params.HttpConnectionParams;
import org.apache.commons.httpclient.protocol.SecureProtocolSocketFactory;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import sun.security.validator.ValidatorException;

/**
 * Custom implementation of of the SecureProtocolSocketFactory
 * interface that enables the use of the service keystores to
 * establish and validate SSL connections.
 */
public class CustomSslSocketFactory implements SecureProtocolSocketFactory {
   /** Class logger */
   private static Log log =
      LogFactory.getLog(CustomSslSocketFactory.class);

   private SSLSocketFactory socketFactory;

   /**
    * Class to manage which X509 certificate-based key pairs are used to
    * authenticate the local side of a secure socket. <br>
    * During secure socket negotiations, methods in this class are called to <br>
    * - determine the set of aliases that are available for negotiations based
    * on the criteria presented,<br>
    * -  select the best alias based on the criteria
    * presented, <br>
    * - select no alias if it does not matter which issuers are used, and  <br>
    * - obtain the corresponding key material for given aliases.
    */
   public class CustomKeyManager implements X509KeyManager
   {
      private X509KeyManager keyManager;

      public CustomKeyManager(KeyManager km)
      {
         if (km instanceof X509KeyManager) {
            keyManager = (X509KeyManager) km;
         } else {
            throw new IllegalArgumentException(
                     "keyManager not of supported type");
         }
      }

      @Override
      public String chooseClientAlias(String[] keyType,
                                      Principal[] issuers,
                                      Socket socket)
      {
         /*
          * Passing null for list of acceptable CA issuer subject names
          * indicates that it does not matter which issuers are used. Hence, by
          * default, any of the aliases from the client keystore will be chosen.
          * Overriding this behavior to return no alias in the above mentioned
          * scenario.
          */
         if (issuers == null || issuers.length == 0) {
            return null;
         }
         return keyManager.chooseClientAlias(keyType, issuers, socket);
      }

      @Override
      public String chooseServerAlias(String keyType,
                                      Principal[] issuers,
                                      Socket socket)
      {
         return keyManager.chooseServerAlias(keyType, issuers, socket);
      }

      @Override
      public X509Certificate[] getCertificateChain(String alias)
      {
         return keyManager.getCertificateChain(alias);
      }

      @Override
      public String[] getClientAliases(String keyType,
                                       Principal[] issuers)
      {
         return keyManager.getClientAliases(keyType, issuers);
      }

      @Override
      public PrivateKey getPrivateKey(String alias)
      {
         return keyManager.getPrivateKey(alias);
      }

      @Override
      public String[] getServerAliases(String keyType,
                                       Principal[] issuers)
      {
         return keyManager.getServerAliases(keyType, issuers);
      }

   }

   public class CustomTrustManager implements X509TrustManager
   {

      private X509TrustManager trustManager;

      public CustomTrustManager(TrustManager tm) {
         if(tm instanceof X509TrustManager) {
            trustManager = (X509TrustManager) tm;
         } else {
            throw new IllegalArgumentException(
               "TrustManager not of supported type");
         }
      }

      public void checkClientTrusted(
         X509Certificate[] chain,
         String authType) throws CertificateException {

         trustManager.checkClientTrusted(chain, authType);
      }

      @SuppressWarnings("all")
      public void checkServerTrusted(
         X509Certificate[] chain,
         String authType) throws CertificateException {
         try {
            trustManager.checkServerTrusted(chain, authType);
         } catch (ValidatorException ve) {
            log.info("CustomTrustManager could not validate certificate.");
            throw new ValidatorException(ve.getMessage(), ve.getErrorType(),
                     chain[0], ve.getCause());
         } catch (CertificateException ce) {
            log.error(ce.getMessage(), ce);
            throw ce;
         }
      }

      public X509Certificate[] getAcceptedIssuers() {
         return trustManager.getAcceptedIssuers();
      }
   }

   public CustomSslSocketFactory(KeyStore keystore,
                                 KeyStore trustStore,
                                 String keystorePassword)
   {
      try {

         KeyManagerFactory keyManagerFactory = KeyManagerFactory
                  .getInstance(KeyManagerFactory.getDefaultAlgorithm());
         keyManagerFactory.init(keystore, keystorePassword.toCharArray());

         KeyManager[] kms = keyManagerFactory.getKeyManagers();
         KeyManager[] customKms = new KeyManager[kms.length];
         for (int i = 0; i < kms.length; ++i) {
            customKms[i] = new CustomKeyManager(kms[i]);
         }

         TrustManagerFactory trustManagerFactory = TrustManagerFactory
                  .getInstance(TrustManagerFactory.getDefaultAlgorithm());
         trustManagerFactory.init(trustStore);

         TrustManager[] tms = trustManagerFactory.getTrustManagers();
         TrustManager[] customTms = new TrustManager[tms.length];
         for (int i = 0; i < tms.length; ++i) {
            customTms[i] = new CustomTrustManager(tms[i]);
         }

         SSLContext sslContext = SSLContext.getInstance("SSL");
         sslContext.init(customKms, customTms, null);

         socketFactory = sslContext.getSocketFactory();
      } catch (Exception e) {
         log.error("Exception initializing CustomSslSocketFactory", e);
         throw new RuntimeException(e);
      }
   }

   public Socket createSocket(String host,
                              int port,
                              InetAddress localAddress,
                              int localPort,
                              HttpConnectionParams params)
   throws IOException, UnknownHostException, ConnectTimeoutException {

      if (params == null) {
         throw new IllegalArgumentException("Parameters may not be null");
      }

      int timeout = params.getConnectionTimeout();
      if (timeout == 0) {
         return socketFactory.createSocket(host, port,
                                           localAddress, localPort);
      } else {
         Socket socket = socketFactory.createSocket();
         SocketAddress localAddr =
            new InetSocketAddress(localAddress, localPort);
         SocketAddress remoteAddr =
            new InetSocketAddress(host, port);

         socket.bind(localAddr);
         socket.connect(remoteAddr, timeout);

         return socket;
      }
   }

   public Socket createSocket(String host, int port,
                              InetAddress clientHost,
                              int clientPort)
      throws IOException, UnknownHostException {

      return socketFactory.createSocket(host, port,
                                        clientHost, clientPort);
   }

   public Socket createSocket(String host, int port)
      throws IOException, UnknownHostException {

      return socketFactory.createSocket(host, port);
   }

   public Socket createSocket(Socket socket, String host,
                              int port, boolean autoClose)
      throws IOException, UnknownHostException {

      return socketFactory.createSocket(socket, host,
                                        port, autoClose);
   }
}
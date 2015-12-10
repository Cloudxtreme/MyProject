/* **********************************************************
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 * **********************************************************/

package com.vmware.vcqa.ssl;

import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.SocketAddress;
import java.net.UnknownHostException;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;

import javax.net.SocketFactory;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;

import org.apache.commons.httpclient.ConnectTimeoutException;
import org.apache.commons.httpclient.params.HttpConnectionParams;
import org.apache.commons.httpclient.protocol.SecureProtocolSocketFactory;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * AuthSSLProtocolSocketFactory will enable client authentication when supplied with
 * a {@link KeyStore keystore} file containing a private key/public certificate pair. 
 * The client secure socket will use the private key to authenticate itself to the 
 * target HTTPS server during the SSL session handshake if requested to do so by the 
 * server. The target HTTPS server will in its turn verify the certificate presented
 * by the client in order to establish client's authenticity
 */

public class AuthSSLProtocolSocketFactory implements SecureProtocolSocketFactory {
   private static final Logger log = LoggerFactory.getLogger(AuthSSLProtocolSocketFactory.class);

   /** Log object for this class. */
   private static final Log _log =
      LogFactory.getLog(AuthSSLProtocolSocketFactory.class);

   private static final String DEFAULT_PROTOCOL = "TLS";

   private KeyStore _keyStore, _trustStore;
   private String _keyStorePassword;
   private SSLContext _sslcontext = null;
   private String[] _trustedThumbprints = null;
   private String _protocol = null;

   /**
    * Constructor for AuthSSLProtocolSocketFactory. Either a keystore or truststore 
    * file must be given. Otherwise SSL context initialization error will result.
    * 
    * @param keystore The keystore to use for server-side certificates.
    * @param truststore The keystore to use for client-side authentication.
    * @param protocol The SSL protocol to use.
    * @param trustedThumbprints The list of SHA-1 thumbprints of server certificates
    *                           for which connections made from this factory will
    *                           implicitly trust.
    */
   public AuthSSLProtocolSocketFactory(
         final KeyStore keystore, final String keystorePassword,
         final KeyStore truststore, 
         String protocol, String[] trustedThumbprints) {
      _keyStore = keystore;
      _keyStorePassword = keystorePassword;
      _trustStore = truststore;
      _protocol = protocol != null ? protocol : DEFAULT_PROTOCOL;
      _trustedThumbprints = trustedThumbprints;
   }

   public void setAsDefaultHttpsURLFactory() throws IOException {
      HttpsURLConnection.setDefaultSSLSocketFactory(getSSLContext().getSocketFactory());
   }

   private static KeyManager[] createKeyManagers(final KeyStore keystore,
                                                 final String password)
                        throws KeyStoreException,
                               NoSuchAlgorithmException,
                               UnrecoverableKeyException {
      assert keystore != null;
      if (_log.isDebugEnabled()) {
         _log.debug("Initializing key manager");
      }
      KeyManagerFactory kmfactory = KeyManagerFactory.getInstance(
            KeyManagerFactory.getDefaultAlgorithm());
      kmfactory.init(keystore, password != null ? password.toCharArray() : null);
      return kmfactory.getKeyManagers();
   }

   private static TrustManager[] createTrustManagers(final KeyStore keystore,
                                                     String[] trustedThumbprints)
                        throws KeyStoreException,
                               NoSuchAlgorithmException,
                               IOException {
      assert keystore != null;
      if (_log.isDebugEnabled()) {
         _log.debug("Initializing trust manager");
      }

      TrustManagerFactory tmfactory = TrustManagerFactory.getInstance(
            TrustManagerFactory.getDefaultAlgorithm());
      tmfactory.init(keystore);
      TrustManager[] trustmanagers = tmfactory.getTrustManagers();
      for (int i = 0; i < trustmanagers.length; i++) {
         if (trustmanagers[i] instanceof X509TrustManager) {
            trustmanagers[i] = new AuthSSLX509TrustManager(
                  (X509TrustManager)trustmanagers[i], trustedThumbprints);
         }
      }
      return trustmanagers;
   }

   private SSLContext createSSLContext(String protocol) {
      if (protocol == null) {
         protocol = DEFAULT_PROTOCOL;
      }

      try {
         KeyManager[] keymanagers = null;
         TrustManager[] trustmanagers = null;
         if (_keyStore != null) {
            keymanagers = createKeyManagers(_keyStore, _keyStorePassword);
         }
         if (_trustStore != null) {
            trustmanagers = createTrustManagers(_trustStore, _trustedThumbprints);
         }
         SSLContext sslcontext = SSLContext.getInstance(protocol);
         sslcontext.init(keymanagers, trustmanagers, null);
         return sslcontext;
      } catch (NoSuchAlgorithmException e) {
         _log.error(e.getMessage(), e);
         throw new AuthSSLInitializationError("Unsupported algorithm exception: " +
               e.getMessage(), e);
      } catch (KeyStoreException e) {
         _log.error(e.getMessage(), e);
         throw new AuthSSLInitializationError("Keystore exception: " +
               e.getMessage(), e);
      } catch (GeneralSecurityException e) {
         _log.error(e.getMessage(), e);
         throw new AuthSSLInitializationError("Key management exception: " +
               e.getMessage(), e);
      } catch (IOException e) {
         _log.error(e.getMessage(), e);
         throw new AuthSSLInitializationError(
               "I/O error reading keystore/truststore file: " + e.getMessage(), e);
      }
   }
   /**
    * kiri private -> public
    * @return
    * @throws IOException
    */
   public SSLContext getSSLContext() throws IOException {
      if (_sslcontext == null) {
         _sslcontext = createSSLContext(_protocol);
      }
      return _sslcontext;
   }

   /**
    * Attempts to get a new socket connection to the given host within the given time 
    * limit.
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
    *                              determined
    */
   public Socket createSocket(final String host,
                              final int port,
                              final InetAddress localAddress,
                              final int localPort,
                              final HttpConnectionParams params)
                     throws IOException, UnknownHostException, ConnectTimeoutException {
      assert params != null;
      int timeout = params.getConnectionTimeout();
      SocketFactory socketfactory = getSSLContext().getSocketFactory();
      if (timeout == 0) {
         return socketfactory.createSocket(host, port, localAddress, localPort);
      } else {
         Socket socket = socketfactory.createSocket();
         socket.setSoTimeout(timeout);
         socket.setKeepAlive(true);
         SocketAddress localaddr = new InetSocketAddress(localAddress, localPort);
         SocketAddress remoteaddr = new InetSocketAddress(host, port);
         socket.bind(localaddr);
         socket.connect(remoteaddr, timeout);

         return socket;
      }
   }

   /**
    * @see SecureProtocolSocketFactory#createSocket(java.lang.String,int,
    * java.net.InetAddress,int)
    */
   public Socket createSocket(String host, int port,
                              InetAddress clientHost, int clientPort)
                        throws IOException, UnknownHostException {
      return getSSLContext().getSocketFactory().createSocket(
            host,
            port,
            clientHost,
            clientPort
      );
   }

   /**
    * @see SecureProtocolSocketFactory#createSocket(java.lang.String,int)
    */
   public Socket createSocket(String host, int port)
                        throws IOException, UnknownHostException {
      return getSSLContext().getSocketFactory().createSocket(
            host,
            port
      );
   }

   /**
    * @see SecureProtocolSocketFactory#createSocket(java.net.Socket,
    * java.lang.String,int,boolean)
    */
   public Socket createSocket(Socket socket, String host, int port, boolean autoClose)
                        throws IOException, UnknownHostException {
      return getSSLContext().getSocketFactory().createSocket(
            socket,
            host,
            port,
            autoClose
      );
   }
}

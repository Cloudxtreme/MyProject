package com.vmware.vcqa.ssl;

import java.io.IOException;
import java.net.InetAddress;
import java.net.Socket;
import java.net.UnknownHostException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;
import javax.security.cert.X509Certificate;

import org.apache.commons.httpclient.ConnectTimeoutException;
import org.apache.commons.httpclient.HttpClientError;
import org.apache.commons.httpclient.params.HttpConnectionParams;
import org.apache.commons.httpclient.protocol.ControllerThreadSocketFactory;
import org.apache.commons.httpclient.protocol.SecureProtocolSocketFactory;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * @exclude <p>
 *          EasySSLProtocolSocketFactory can be used to creats SSL
 *          {@link Socket}s that accept self-signed certificates.
 *          </p>
 *          <p>
 *          This socket factory SHOULD NOT be used for productive systems due to
 *          security reasons, unless it is a concious decision and you are
 *          perfectly aware of security implications of accepting self-signed
 *          certificates
 *          </p>
 *          <p>
 *          Example of using custom protocol socket factory for a specific host:
 * 
 *          <pre>
 * Protocol easyhttps = new Protocol(&quot;https&quot;, new EasySSLProtocolSocketFactory(),
 *     443);
 * </pre>
 * 
 *          </p>
 *          <p>
 * 
 *          <pre>
 * HttpClient client = new HttpClient();
 * client.getHostConfiguration().setHost(&quot;localhost&quot;, 443, easyhttps);
 * // use relative url only
 * GetMethod httpget = new GetMethod(&quot;/&quot;);
 * client.executeMethod(httpget);
 * </pre>
 * 
 *          </p>
 *          <p>
 *          Example of using custom protocol socket factory per default instead
 *          of the standard one:
 * 
 *          <pre>
 * Protocol easyhttps = new Protocol(&quot;https&quot;, new EasySSLProtocolSocketFactory(),
 *     443);
 * Protocol.registerProtocol(&quot;https&quot;, easyhttps);
 * HttpClient client = new HttpClient();
 * GetMethod httpget = new GetMethod(&quot;https://localhost/&quot;);
 * client.executeMethod(httpget);
 * </pre>
 * 
 *          </p>
 * 
 *          <p>
 *          DISCLAIMER: HttpClient developers DO NOT actively support this
 *          component. The component is provided as a reference material, which
 *          may be inappropriate for use without additional customization.
 *          </p>
 * @author <a href="mailto:oleg -at- ural.ru">Oleg Kalnichevski</a>
 */
public class EasySSLProtocolSocketFactory implements
    SecureProtocolSocketFactory {
   private static final Logger log = LoggerFactory.getLogger(EasySSLProtocolSocketFactory.class);
    private SSLContext sslcontext = null;

    /**
     * Constructor for EasySSLProtocolSocketFactory.
     */
    public EasySSLProtocolSocketFactory() {
        super();
    }

    private static SSLContext createEasySSLContext() {
        try {
            SSLContext context = SSLContext.getInstance("SSL");
            context.init(null, new TrustManager[] { new EasyX509TrustManager(
                null) }, null);
            return context;
        } catch (Exception e) {
            throw new HttpClientError(e.toString());
        }
    }

    private SSLContext getSSLContext() {
        if (this.sslcontext == null) {
            this.sslcontext = createEasySSLContext();
        }
        return this.sslcontext;
    }

    /**
     * @see SecureProtocolSocketFactory#createSocket(java.lang.String,int,java.net.InetAddress,int)
     */
    public Socket createSocket(String host, int port, InetAddress clientHost,
        int clientPort) throws IOException, UnknownHostException {
        return getSSLContext().getSocketFactory().createSocket(host, port,
            clientHost, clientPort);
    }

    /**
     * Attempts to get a new socket connection to the given host within the
     * given time limit.
     * <p>
     * To circumvent the limitations of older JREs that do not support connect
     * timeout a controller thread is executed. The controller thread attempts
     * to create a new socket within the given limit of time. If socket
     * constructor does not return until the timeout expires, the controller
     * terminates and throws an {@link ConnectTimeoutException}
     * </p>
     * 
     * @param host
     *            the host name/IP
     * @param port
     *            the port on the host
     * @param localAddress
     *            the local host name/IP to bind the socket to
     * @param localPort
     *            the port on the local machine
     * @param params
     *            {@link HttpConnectionParams Http connection parameters}
     * @return Socket a new socket
     * @throws IOException
     *             if an I/O error occurs while creating the socket
     * @throws UnknownHostException
     *             if the IP address of the host cannot be determined
     */
    public Socket createSocket(final String host, final int port,
        final InetAddress localAddress, final int localPort,
        final HttpConnectionParams params) throws IOException,
        UnknownHostException, ConnectTimeoutException {
        if (params == null) {
            throw new IllegalArgumentException("Parameters may not be null");
        }
        int timeout = params.getConnectionTimeout();
        if (timeout == 0) {
            return createSocket(host, port, localAddress, localPort);
        } else {
            // To be eventually deprecated when migrated to Java 1.4 or above
            return ControllerThreadSocketFactory.createSocket(this, host, port,
                localAddress, localPort, timeout);
        }
    }

    /**
     * @see SecureProtocolSocketFactory#createSocket(java.lang.String,int)
     */
    public Socket createSocket(String host, int port) throws IOException,
        UnknownHostException {
        return getSSLContext().getSocketFactory().createSocket(host, port);
    }

    /**
     * @see SecureProtocolSocketFactory#createSocket(java.net.Socket,java.lang.String,int,boolean)
     */
    public Socket createSocket(Socket socket, String host, int port,
        boolean autoClose) throws IOException, UnknownHostException {
        return getSSLContext().getSocketFactory().createSocket(socket, host,
            port, autoClose);
    }

    public boolean equals(Object obj) {
        return ((obj != null) && obj.getClass().equals(
            EasySSLProtocolSocketFactory.class));
    }

    public int hashCode() {
        return EasySSLProtocolSocketFactory.class.hashCode();
    }

    public static class EasyX509TrustManager implements X509TrustManager {
        private X509TrustManager standardTrustManager = null;
        /** Log object for this class. */
        private static final Log LOG = LogFactory
            .getLog(EasyX509TrustManager.class);

        /**
         * Constructor for EasyX509TrustManager.
         */
        public EasyX509TrustManager(KeyStore keystore)
            throws NoSuchAlgorithmException, KeyStoreException {
            super();
            TrustManagerFactory factory = TrustManagerFactory
                .getInstance("SunX509");
            factory.init(keystore);
            TrustManager[] trustmanagers = factory.getTrustManagers();
            if (trustmanagers.length == 0) {
                throw new NoSuchAlgorithmException(
                    "SunX509 trust manager not supported");
            }
            this.standardTrustManager = (X509TrustManager)trustmanagers[0];
        }

        /**
         * @see com.sun.net.ssl.X509TrustManager#isClientTrusted(X509Certificate[])
         */
        public boolean isClientTrusted(X509Certificate[] certificates) {
            return true;
        }

        /**
         * @see com.sun.net.ssl.X509TrustManager#isServerTrusted(X509Certificate[])
         */
        public boolean isServerTrusted(X509Certificate[] certificates) {
            return true;
        }


        public void checkClientTrusted(
            java.security.cert.X509Certificate[] chain, String authType)
            throws java.security.cert.CertificateException {
            // TODO Auto-generated method stub
            
        }


        public void checkServerTrusted(
            java.security.cert.X509Certificate[] chain, String authType)
            throws java.security.cert.CertificateException {
            // TODO Auto-generated method stub
            
        }


        public java.security.cert.X509Certificate[] getAcceptedIssuers() {
            // TODO Auto-generated method stub
            return null;
        }
    }
}

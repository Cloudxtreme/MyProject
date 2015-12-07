/* **********************************************************
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 * **********************************************************/

package com.vmware.vcqa.ssl;

import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;

import javax.net.ssl.X509TrustManager;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * AuthSSLX509TrustManager can be used to extend the default {@link X509TrustManager} 
 * with additional trust decisions.
 */

public class AuthSSLX509TrustManager implements X509TrustManager
{
   private static final Logger log = LoggerFactory.getLogger(AuthSSLX509TrustManager.class);
   private X509TrustManager _defaultTrustManager = null;

   private String[] _trustedThumbprints;

   /** Log object for this class. */
   private static final Log _log = LogFactory.getLog(AuthSSLX509TrustManager.class);

   /**
    * Constructor for AuthSSLX509TrustManager.
    */
   public AuthSSLX509TrustManager(final X509TrustManager defaultTrustManager,
                                  String[] trustedThumbprints) {
      assert defaultTrustManager != null;
      _defaultTrustManager = defaultTrustManager;
      _trustedThumbprints = trustedThumbprints;
   }

   /**
    * @see javax.net.ssl.X509TrustManager#checkClientTrusted(X509Certificate[],
    * String authType)
    */
   public void checkClientTrusted(X509Certificate[] certificates, String authType)
   throws CertificateException {
      if (_log.isDebugEnabled() && certificates != null) {
         for (int c = 0; c < certificates.length; c++) {
            X509Certificate cert = certificates[c];
            _log.debug(" Client certificate " + (c + 1) + ":");
            _log.debug("  Subject DN: " + cert.getSubjectDN());
            _log.debug("  Signature Algorithm: " + cert.getSigAlgName());
            _log.debug("  Valid from: " + cert.getNotBefore() );
            _log.debug("  Valid until: " + cert.getNotAfter());
            _log.debug("  Issuer: " + cert.getIssuerDN());
         }
      }
      _defaultTrustManager.checkClientTrusted(certificates,authType);
   }

   /**
    * @see javax.net.ssl.X509TrustManager#checkServerTrusted(X509Certificate[],
    * String authType)
    */
   public void checkServerTrusted(X509Certificate[] certificates, String authType)
   throws CertificateException {
      
      // DO NOTHING. TESTWARE NEED NOT VALIDATE VC's CERTIFICATE
    
   }

   /**
    * Get the set of accepted certificate issuers.  If we are running
    * in thumbprint mode, don't return any.  Otherwise, return the default
    * set of issuers.
    *
    * @see javax.net.ssl.X509TrustManager#getAcceptedIssuers()
    */
   public X509Certificate[] getAcceptedIssuers() {
      if (_trustedThumbprints != null) {
         return null;
      } else {
         return _defaultTrustManager.getAcceptedIssuers();
      }
   }
}


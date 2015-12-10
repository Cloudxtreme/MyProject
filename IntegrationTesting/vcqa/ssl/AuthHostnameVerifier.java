/* **********************************************************
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 * **********************************************************/

package com.vmware.vcqa.ssl;

import java.net.InetAddress;
import java.net.UnknownHostException;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.SSLSession;


/**
 * Replacement HostnameVerifier class for HttpsURLConnection that
 * allows local host connections in any form.
 */
public class AuthHostnameVerifier implements HostnameVerifier {

   private HostnameVerifier _default;
   private String _localHostName, _localHostNameCanonical;

   public AuthHostnameVerifier(HostnameVerifier defaultVerifier) 
                    throws UnknownHostException {
      _default = defaultVerifier;

      InetAddress localMachine = java.net.InetAddress.getLocalHost();
      _localHostName = localMachine.getHostName();
      _localHostNameCanonical = localMachine.getCanonicalHostName();
   }

   /**
    * Verify a given hostname for a given SSL session.
    * 
    * Always allows "localhost" and the local DNS name to pass through.
    *
    * @param hostname The host name to verify.
    * @param session The SSL session to verify against.
    */
   public boolean verify(String hostname,
                         SSLSession session) {
      if (hostname.equalsIgnoreCase("localhost") ||
          hostname.equals("127.0.0.1") ||
          hostname.equalsIgnoreCase(_localHostName) ||
          hostname.equalsIgnoreCase(_localHostNameCanonical)) {
         return true;
      } else {
         return _default == null ? true : _default.verify(hostname, session);
      }
   }

}


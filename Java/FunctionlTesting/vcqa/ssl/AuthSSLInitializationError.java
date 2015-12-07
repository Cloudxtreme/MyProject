/* **********************************************************
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 * **********************************************************/

package com.vmware.vcqa.ssl;


/**
 * Signals fatal error in initialization of {@link AuthSSLProtocolSocketFactory}.
 */

public class AuthSSLInitializationError extends Error {

   /**
    * Creates a new AuthSSLInitializationError.
    */
   public AuthSSLInitializationError() {
      super();
   }

   /**
    * Creates a new AuthSSLInitializationError with the specified message.
    *
    * @param message error message
    */
   public AuthSSLInitializationError(String message) {
      super(message);
   }

   /**
    * Creates a new AuthSSLInitializationError with the specified message
    * and related Throwable.
    *
    * @param message error message
    * @param t Associated throwable.
    */
   public AuthSSLInitializationError(String message, Throwable t) {
      super(message, t);
   }

}

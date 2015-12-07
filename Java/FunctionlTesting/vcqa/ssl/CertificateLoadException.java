/* **********************************************************
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 * **********************************************************/

package com.vmware.vcqa.ssl;


/**
 * Thrown during an error to load a certificate file.
 */
public class CertificateLoadException extends Exception {
   public CertificateLoadException(String message) {
      super(message);
   }
   public CertificateLoadException(String message, Throwable t) {
      super(message, t);
   }
}

/* **********************************************************
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 * **********************************************************/

package com.vmware.vcqa.ssl;
import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLDecoder;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CRL;
import java.security.cert.Certificate;
import java.security.cert.CertificateEncodingException;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Enumeration;
import java.util.Iterator;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Helper functions for handling SSL certificates.
 */
public class SSLUtil {

   private static final Logger log = LoggerFactory.getLogger(SSLUtil.class);
   
   private static final String BEGIN_CERT_HEADER = "-----BEGIN CERTIFICATE-----";
   private static final String END_CERT_FOOTER = "-----END CERTIFICATE-----";
   private static final String BEGIN_CRL_HEADER = "-----BEGIN X509 CRL-----";
   private static final String END_CRL_FOOTER = "-----END X509 CRL-----";

   /**
    * Compute the SHA-1 thumbprint of an X.509 certificate.
    *
    * @param certFilePath Path to a base-64 encoded certificate file.
    */
   public static String getSSLThumbprint(String certFilePath)
             throws CertificateLoadException {

      Certificate cert = loadCertificate(certFilePath);
      return getCertificateThumbprint(cert);
   }

   /**
    * Load a certificate from a file.
    */
   public static Certificate loadCertificate(String certFilePath)
             throws CertificateLoadException {

      /*
       * http://www.columbia.edu/~ariel/ssleay/x509_certs.html :
       *
       * X509_digest converts the X509 structure a to DER-encoded form; computes
       * the message digest of it, using  as the message digest algorithm; and
       * returns the results in md, with the length of the returned digest in len.
       */

      File certFile = new File(certFilePath);

      Certificate localCert = null;
      try {
         FileInputStream fis = new FileInputStream(certFile);
         BufferedInputStream bis = new BufferedInputStream(fis);
         CertificateFactory cf = CertificateFactory.getInstance("X.509");
         if (bis.available() > 0) {
            localCert = cf.generateCertificate(bis);
         }
         bis.close();
      } catch (FileNotFoundException e) {
         throw new CertificateLoadException(
            "Certificate file \"" + certFilePath + "\" not found", e);
      } catch (IOException e) {
         throw new CertificateLoadException(
            "Failed to read certificate \"" + certFilePath + "\"", e);
      } catch (CertificateException e) {
         throw new CertificateLoadException("Failed to load certificate", e);
      }

      if (null == localCert) {
         throw new CertificateLoadException("No certificate data found");
      }

      return localCert;
   }

   /**
    * Loads an existing keystore at keystoreFilePath.
    *
    * @param keystoreFilePath relative to classpath, or full path.
    * @param password password to the keystore
    * @return
    * @throws Exception
    */
   public static KeyStore loadKeystore(String keystoreFilePath,
                                       String password)
      throws Exception

   {
      KeyStore keystore = KeyStore.getInstance(KeyStore.getDefaultType());
      FileInputStream fis = null;
      try {
         fis = new FileInputStream(keystoreFilePath);
         keystore.load(fis, password != null ? password.toCharArray() : null);
      } catch (CertificateException e) {
         throw new CertificateLoadException("Keystore error: " + e.getMessage());
      } catch (IOException ioe) {
         throw new CertificateLoadException("Problem accessing file: "
                  + ioe.getMessage());
      } finally {
         try {
            fis.close();
         } catch (Exception e) {
            throw e;
         }
      }
      return keystore;
   }

   /**
    * Stores this keystore to the truststore specified at location and protects
    * its integrity with the given password.
    *
    * @param trustStore KeyStore object
    * @param truststoreFilePath File path to TrustStore
    * @param password Password
    * @throws Exception
    */
   private static void saveTrustStore(KeyStore trustStore,
                                      String truststoreFilePath,
                                      String password)
      throws Exception
   {
      String trustStoreLocation = URLDecoder
               .decode(truststoreFilePath, "UTF-8");
      log.info("Saving trustStore to " + truststoreFilePath);
      trustStore.store(new FileOutputStream(trustStoreLocation), password
               .toCharArray());
   }

   /**
    * Add a certificate entry to the trustStore.
    *
    * @param trustStore KeyStore object
    * @param truststoreFilePath File path to TrustStore
    * @param password Password
    * @param alias Certificate Alias
    * @param cert Certificate object
    * @throws Exception
    */
   public static void addCertToTrustStore(KeyStore trustStore,
                                          String truststoreFilePath,
                                          String password,
                                          String alias,
                                          Certificate cert)
      throws Exception
   {
      trustStore.setCertificateEntry(alias, cert);
      saveTrustStore(trustStore, truststoreFilePath, password);
   }

   /**
    * Remove a certificate entry from the trustStore.
    *
    * @param trustStore KeyStore object
    * @param truststoreFilePath File path to TrustStore
    * @param password Password
    * @param alias Certificate Alias
    * @throws Exception
    */
   public static void removeCertFromTrustStore(KeyStore trustStore,
                                               String truststoreFilePath,
                                               String password,
                                               String alias)
      throws Exception
   {
      if (!trustStore.containsAlias(alias)) {
         return;
      }

      trustStore.deleteEntry(alias);
      saveTrustStore(trustStore, truststoreFilePath, password);
   }

   /**
    * Create a keystore.
    *
    * @param url URL of Keystore file
    * @param keystoreType Type of keystore
    * @param password Password
    * @return KeyStore object
    * @throws CertificateLoadException
    */
   public static KeyStore createKeyStore(final URL url,
                                         String keystoreType,
                                         final String password)
      throws CertificateLoadException
   {
      assert url != null;

      InputStream is = null;
      try {
         KeyStore keystore = KeyStore.getInstance(keystoreType);
         is = url.openStream();
         keystore.load(is, password != null ? password.toCharArray() : null);
         return keystore;
      } catch (KeyStoreException e) {
         throw new CertificateLoadException(
                  "Keystore error: " + e.getMessage(), e);
      } catch (NoSuchAlgorithmException e) {
         throw new CertificateLoadException("No such algorithm: "
                  + e.getMessage(), e);
      } catch (CertificateException e) {
         throw new CertificateLoadException("Certificate error: "
                  + e.getMessage(), e);
      } catch (IOException e) {
         throw new CertificateLoadException("I/O error: " + e.getMessage(), e);
      } finally {
         if (is != null) {
            try {
               is.close();
            } catch (IOException e) {
               log.error("IOException returned." + e.getMessage());
            }
         }
      }
   }

   public static String getCertificateThumbprint(Certificate cert)
                                throws CertificateLoadException {

      // Compute the SHA-1 hash of the certificate.
      byte[] encoded;

      try {
         encoded = cert.getEncoded();
      } catch (CertificateEncodingException cee) {
         throw new CertificateLoadException(
            "Error reading certificate encoding: " + cee.getMessage(), cee);
      }

      MessageDigest sha1;
      try {
         sha1 = MessageDigest.getInstance("SHA-1");
      } catch (NoSuchAlgorithmException e) {
         throw new CertificateLoadException(
               "Could not instantiate SHA-1 hash algorithm", e);
      }
      sha1.update(encoded);
      byte[] hash = sha1.digest();

      // Hash *should* be 20 bytes?
      if (hash.length != 20) {
         throw new CertificateLoadException(
               "Computed thumbprint is " + hash.length + " bytes long, expected 20");
      }

      StringBuilder thumbprintString = new StringBuilder(hash.length * 3);
      for (int i = 0; i < hash.length; i++) {
         if (i > 0) {
            thumbprintString.append(":");
         }
         String hexByte = Integer.toHexString(0xFF & (int)hash[i]);
         if (hexByte.length() == 1) {
            thumbprintString.append("0");
         }
         thumbprintString.append(hexByte);
      }

      return thumbprintString.toString().toUpperCase();
   }

   /**
    * Gets the certificate with the alias name passed or a trusted certificate
    * in the keystore.
    *
    * @param keyStore KeyStore object.
    * @param aliasName String ceritificate alias.
    * @param trusted Boolean true to return the trusted certificate in the store.
    *
    * @return String base64 encoded string representation of the certificate.
    *
    * @throws java.lang.Exception
    */
   public static String getCertificate(KeyStore keyStore,
                                       String aliasName,
                                       Boolean trusted)
                                       throws Exception
   {
      try {
         Enumeration<String> aliases = keyStore.aliases();

         if (!aliasName.equals("")) {
            /*
             * search for a certificate with the given aliasName first
             */
            while (aliases.hasMoreElements()) {
               String alias = aliases.nextElement();
               log.info("Found certificate for alias " + alias);
               if (alias.equals(aliasName) || alias.contains(aliasName)) {
                  X509Certificate tc = (X509Certificate) keyStore
                           .getCertificate(alias);
                  return Base64.encodeToString(tc.getEncoded(), Boolean.TRUE);
               }
            }
            throw new java.lang.Exception("no matching certificate found");
         }

         aliases = keyStore.aliases();
         while (aliases.hasMoreElements()) {
            String alias = aliases.nextElement();
            X509Certificate tc = (X509Certificate) keyStore
                     .getCertificate(alias);

            if (trusted) {
               try {
                  tc.checkValidity();
                  log.info("Found trusted certificate " + alias);
                  return Base64.encodeToString(tc.getEncoded(),Boolean.TRUE);
               } catch (java.lang.Exception e) {
                  // skip untrusted certificate
               }
            } else {
               if (!keyStore.isCertificateEntry(alias)) {
                  log.info("Found private key certificate " + alias);
                  return Base64.encodeToString(tc.getEncoded(),Boolean.TRUE);
               }
            }
         }
         throw new java.lang.Exception("no matching certificate found");
      } catch (java.lang.Exception e) {
         throw e;
      }
   }

   /**
    * Wrap the certificate bytes in base64 format.
    *
    * @param tc X509Certificate certificate.
    *
    * @return String base 64 encoded string object.
    */
   public static String wrapCertificateBytes(X509Certificate tc)
                                              throws Exception
   {
      /**
       * get PkiPath PKCS#7 encoding and wrap it in a base64 text format
       */
      String b64 = Base64.encodeToString(tc.getEncoded(), Boolean.TRUE);
      StringBuilder certStrBuilder = new StringBuilder();
      certStrBuilder.append(BEGIN_CERT_HEADER).append("\n\n");
      certStrBuilder.append(b64);
      certStrBuilder.append("\n").append(END_CERT_FOOTER);
      return certStrBuilder.toString();
   }

   /**
    * Method to get the certificate object given the certificate String
    *
    * @param certString Certificate as String
    * @return Certificate object.
    * @throws Exception
    */
   public static Certificate buildCertificate(String certString)
      throws Exception
   {
      String str = certString.trim();
      StringBuilder certStrBuilder = new StringBuilder();
      if (!str.startsWith(BEGIN_CERT_HEADER)) {
         certStrBuilder.append(BEGIN_CERT_HEADER).append("\n\n");
      }
      certStrBuilder.append(str);
      if (!str.endsWith(END_CERT_FOOTER)) {
         certStrBuilder.append("\n").append(END_CERT_FOOTER);
      }
      str = certStrBuilder.toString();
      InputStream inBytes = new ByteArrayInputStream(str.getBytes());
      CertificateFactory cf = CertificateFactory.getInstance("X.509");
      Certificate certificate = null;
      if (inBytes.available() > 0) {
         certificate = cf.generateCertificate(inBytes);
      }
      inBytes.close();
      return certificate;
   }

   /**
    * Extract the common name value from the distinguished names of the
    * certificate
    * 
    * @param certificate X509 certificate
    * @return common name assigned to the certificate
    * @throws Exception
    */
   public static String getCertificateCommonName(X509Certificate certificate)
                                                                             throws Exception
   {
      String commonName = null;
      String dnames = certificate.getSubjectX500Principal().getName();
      log.info("Distinguished names in certificate: {}", dnames);
      String[] values = dnames.split(",");
      for (String value : values) {
         value = value.trim();
         if (value.startsWith("CN=")) {
            commonName = value.substring(3);
            log.info("Common name (CN) found: {}", commonName);
            break;
         }
      }
      return commonName;
   }

   /**
    * Try to get the domain name (type 2) and IP address (type 7) from the
    * Subject Alternative Names extension of X509 certificate
    * 
    * @param certificate
    * @return
    * @throws Exception
    */
   public static List<String> getCertificateDNsAndIPsFromSAN(X509Certificate certificate)
                                                                                         throws Exception
   {
      List<String> subjectNames = new ArrayList<String>();
      Collection<List<?>> subAltNames = certificate
               .getSubjectAlternativeNames();
      if (subAltNames != null && !subAltNames.isEmpty()) {
         for (Iterator<List<?>> iter = subAltNames.iterator(); iter.hasNext();) {
            List<?> nameEntry = iter.next();
            Integer type = (Integer) nameEntry.get(0);
            // Only care about dNSName and iPAddress type for now.
            if (type == 2 || type == 7) {
               subjectNames.add((String) nameEntry.get(1));
            }
         }
         log.info("Name values found: {}", subjectNames);
      } else {
         log.info("No SubjectAlternativeNames in certificate");
      }
      return subjectNames;
   }

   /**
    * Method to get the CRL object from a given CRL String
    * 
    * @param crlString CRL as String
    * @return CRL object.
    * @throws Exception
    */
   public static CRL buildCRL(String crlString)
                                               throws Exception
   {
      String str = crlString.trim();
      StringBuilder certStrBuilder = new StringBuilder();
      if (!str.startsWith(BEGIN_CRL_HEADER)) {
         certStrBuilder.append(BEGIN_CRL_HEADER).append("\n\n");
      }
      certStrBuilder.append(str);
      if (!str.endsWith(END_CRL_FOOTER)) {
         certStrBuilder.append("\n").append(END_CRL_FOOTER);
      }
      str = certStrBuilder.toString();
      InputStream inBytes = new ByteArrayInputStream(str.getBytes());
      CertificateFactory cf = CertificateFactory.getInstance("X.509");
      CRL crl = null;
      if (inBytes.available() > 0) {
         crl = (CRL) cf.generateCRL(inBytes);
      }
      inBytes.close();
      return crl;
   }
}
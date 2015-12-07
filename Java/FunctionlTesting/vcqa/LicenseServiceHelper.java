/* **********************************************************************
 * Copyright 2013 VMware, Inc.  All rights reserved. VMware Confidential
 * *********************************************************************/
package com.vmware.vcqa;

import java.security.PrivateKey;
import java.util.concurrent.Executors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.cis.license.client.LicenseClient;
import com.vmware.cis.license.client.impl.LicenseClientFactoryImpl;
import com.vmware.vcqa.CMHelper;
import com.vmware.vcqa.SSOHelper;
import com.vmware.vim.binding.cis.license.accounting.LicenseUsageService;
import com.vmware.vim.binding.cis.license.management.AssetManagementService;
import com.vmware.vim.binding.cis.license.management.SystemManagementService;
import com.vmware.vim.binding.cis.license.report.ReportService;
import com.vmware.vim.binding.vmodl.ManagedObjectReference;
import com.vmware.vim.sso.client.SamlToken;

/**
 * Helper object for License Service, provides access to the different license related
 * services.
 */
public class LicenseServiceHelper {

   private static final String LICENSE_USAGE_SVC_MO_REF_TYPE =
         "CisLicenseAccountingLicenseUsageService";
   private static final String LICENSE_USAGE_SVC_MO_REF_ID =
         "cis.license.accounting.LicenseUsageService";

   private final Logger log = LoggerFactory.getLogger(getClass());

   private SamlToken _logInToken;
   private PrivateKey _privateKey;
   private LicenseClient _lsClient;

   /**
    * Creates and returns a helper object for License Service
    *
    * @param hostName
    * @throws Exception
    */
   public LicenseServiceHelper(String hostName) throws Exception {

      // Get logIn token
      SSOHelper ssoHelper = new SSOHelper(hostName);
      ssoHelper.setSolutionUserSsoGrps(new String[] { "LicenseService.Administrators" });

      _logInToken = ssoHelper.getHokToken();
      _privateKey = SSOHelper.getPrivatekey();

      // Log in to CM
      CMHelper cmHelper = new CMHelper(hostName);
      cmHelper.login(_logInToken, _privateKey);

      try {
         // Get License client
         LicenseClientFactoryImpl lsClientFactory = new LicenseClientFactoryImpl(
               Class.forName("com.vmware.vim.binding.cis.license.version.version1"),
               "com.vmware.vim.binding.cis.license",
               Executors.newFixedThreadPool(1));
         lsClientFactory.initVmodl();

         _lsClient = lsClientFactory.createClient(cmHelper.getClient());
      } finally {
         // Log out from CM
         cmHelper.logout();
      }
   }

   /**
    * Login the to LS
    *
    * @throws Exception
    */
   public void login() throws Exception {
      log.info("Log in to LicenseService");

      _lsClient.login(_logInToken, _privateKey);
   }

   // TODO: Remove the method and leave only the close() one, if
   // it proves to be more convenient. Move the login part to the constructor.
   /**
    * Logout the user session from LS
    *
    * @throws Exception
    */
   public void logout() throws Exception {
      log.info("Log out from LicenseService");

      _lsClient.logout();
   }

   /**
    * Closes the LicenseService client
    *
    * @throws Exception
    */
   public void close() throws Exception {
      log.info("Closes the LicenseService client");

      _lsClient.close();
   }

   /**
    * Returns SystemManagementService
    *
    * @return
    */
   public SystemManagementService getSystemManagementService() {
      return _lsClient.getSystemManagementService();
   }

   /**
    * Returns AssetManagementService
    *
    * @return
    */
   public AssetManagementService getAssetManagementService() {
      return _lsClient.getAssetManagementService();
   }

   /**
    * Returns ReportService
    *
    * @return
    */
   public ReportService getReportService() {
      return _lsClient.getReportService();
   }

   /**
    * Returns LicenseUsageService
    *
    * @return
    */
   public LicenseUsageService getLicenseUsageService() {
      ManagedObjectReference lusMoRef = new ManagedObjectReference(
            LICENSE_USAGE_SVC_MO_REF_TYPE,
            LICENSE_USAGE_SVC_MO_REF_ID);

      return _lsClient.getManagedObject(LicenseUsageService.class, lusMoRef);
   }
}
/* Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package com.vmware.vcqa;



import java.net.URL;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import sun.net.util.IPAddressUtil;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.ServiceContent;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.esxagentmanager.EamConstants;
import com.vmware.vcqa.sm.SmTestConstants;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.ExtensionManager;
import com.vmware.vcqa.vim.SessionManager;

/**
 * SolutionHelper is the class which has helper methods which are used by VC
 * extensions / solutions like DR, Integrity
 */

public class SolutionHelper
{

   private static final Logger log = LoggerFactory.getLogger(SolutionHelper.class);
   /**
    * Log in to vc and finds the registered extension in the vc by the
    * extensionKey
    *
    * @param vcInfo - serviceInfo of the vc instance
    * @param vcLocale - locale to be used to login to vc
    * @param extensionKey - key used to search for the extension in vc
    * @return url of the extension found null if extension is not found in the
    *         registered extensions
    * @throws Exception
    */
   public static URL getExtensionUrlFromVc(ServiceInfo vcInfo,
                                           String vcLocale,
                                           String extensionKey)
      throws Exception
   {
      boolean loggedin = false;
      URL extensionUrl = null;
      if (vcInfo.getConnectAnchor() instanceof ConnectAnchor) {
         ConnectAnchor vimConnectAnchor = (ConnectAnchor) vcInfo.getConnectAnchor();
         AuthorizationManager iauth = new AuthorizationManager(vimConnectAnchor);
         SessionManager sessionManager = new SessionManager(vimConnectAnchor);
         ManagedObjectReference authMor = sessionManager.getSessionManager();
         if (sessionManager.isLoggedIn()) {
            loggedin = true;
         } else {
            UserSession loginSession = sessionManager.login(
                     authMor, vcInfo.getUserName(), vcInfo.getPassword(),
                     vcLocale);
            if (loginSession != null) {
               loggedin = true;
            }
         }

         if (loggedin) {
            ExtensionManager iExt = new ExtensionManager(vimConnectAnchor);
            ManagedObjectReference extMor = iExt.getExtensionManager();
            extensionUrl = iExt.getExtensionUrl(extMor, extensionKey);
            /*
             * Logging out from VC after we have found the extension URL
             */
            new SessionManager(vimConnectAnchor).logout(authMor);
         } else {
            log.error("Unable to login to VC to get the extension url");
         }
      } else {
         log.error("Unable to cast the service info connect anchor to "
                  + "vimConnectAnchor");
      }
      return extensionUrl;
   }

   /**
    * Create extensionURL for Storage Management Service from VC Service Info
    *
    * @param vcInfo - serviceInfo of the VC instance
    * @return url SMS service URL
    * @throws Exception
    */
   private static URL createSmsExtensionUrlFromVc(ServiceInfo vcInfo)
      throws Exception
   {
      String prefix = null;
      if (vcInfo.getConnectAnchor().getEndPointUrl().startsWith(
            TestConstants.HTTPS_PROTOCOL_URL_PREFIX)) {
         prefix = TestConstants.HTTPS_PROTOCOL_URL_PREFIX;
      } else {
         prefix = TestConstants.HTTP_PROTOCOL_URL_PREFIX;
      }
      URL extensionUrl = new URL(prefix + vcInfo.getHostName() + ":"
            + SmTestConstants.SMS_PORT + SmTestConstants.SMS_URL_PATH);
      log.info("SMS extension URL: " + extensionUrl.toString());
      return extensionUrl;
   }

   /**
    * Create the correct extensionURL for VSM Service from VC Service Info
    * @param extensionURL - extensionURL retrieved from the VSM extension
    * @param vcInfo - serviceInfo of the VC instance
    * @return Corrected VSM service URL
    * @throws Exception
    */
   private static URL createVsmExtensionUrl(URL extensionURL, ServiceInfo vcInfo)
      throws Exception
   {
      String url = extensionURL.toString();
      url = url.replace("*", vcInfo.getHostName());
      URL extensionUrl = new URL(url);
      return extensionUrl;
   }

   /**
    * Create the correct extensionURL for EAM Service from VC Service Info.
    * @param extensionURL - extensionURL retrieved from the EAM extension
    * @param vcInfo - serviceInfo of the VC instance
    * @return Modified EAM service URL
    * @throws Exception
    */
   private static URL createEamExtensionUrl(URL extensionURL, ServiceInfo vcInfo)
      throws Exception
   {
      String url = extensionURL.toString();
      if (IPAddressUtil.isIPv6LiteralAddress(vcInfo.getHostName())) {
         log.info("Found IPv6 Hostname, Adding [] for the URL");
         url = url.replace("*", "["+vcInfo.getHostName()+"]");
      }else{
         url = url.replace("*", vcInfo.getHostName());
      }
      URL extensionUrl = new URL(url);
      return extensionUrl;
   }
   /**
    * Check if this serviceInfo is related to DisasterRecovery service for
    * example
    *
    * @param info : ServiceInfo object of the service
    * @return true if this serviceInfo is DisasterRecovery service false
    *         otherwise
    */
   public static boolean isDisasterRecovery(ServiceInfo info)
   {
      return (info.getExtensionKey() == TestConstants.DR_EXTENSION_KEY);
   }

   /**
    * Check if this serviceInfo is related to Integrity service
    *
    * @param info : ServiceInfo object of the service
    * @return true if this serviceInfo is IntegrityService false otherwise
    */
   public static boolean isIntegrity(ServiceInfo info)
   {
      return (info.getExtensionKey() == TestConstants.INTEGRITY_EXTENSION_KEY);
   }

   /**
    * Create service info object for VC. Then, it creates one service info
    * object for each extension that is passed through extensionKeyList
    *
    * @param userName userName to login to VC
    * @param password required to login to VC
    * @param hostName Name of host where Service is running
    * @param port port Number
    * @param keyStorePath
    * @param locale locale string
    * @param extensionIds array of extensions which should be created for this
    *           VC
    * @param customInfo customInfo which can be different for each service
    * @throws Exception
    */
   public static List<ServiceInfo> createVCServiceSet(String userName,
                                                      String password,
                                                      String vcHostName,
                                                      int vcPortNumber,
                                                      String keyStorePath,
                                                      String locale,
                                                      Vector<String> extensionKeyList,
                                                      HashMap<String, String> customInfo)
      throws Exception
   {
      List<ServiceInfo> vecServiceInfo = new Vector<ServiceInfo>();
      /*
       * create a VC serviceInfo
       */
      ServiceInfo vcInfo = new ServiceInfo(userName, password, vcHostName,
               vcPortNumber, keyStorePath, locale, customInfo);
      vecServiceInfo.add(vcInfo);

      if (extensionKeyList != null && extensionKeyList.size() > 0) {
         /*
          * We create two or more serviceInfo objects here
          * One for VC using the hostName and portNumber and etc passed
          * Second for all the extensions requested we create one serviceInfo for
          * each of them.
          * for example if  extensionKeyList contains two extensions
          * DR and INTEGRITY we will create two serviceInfo object for them
          */

         Iterator<String> extensionIter = extensionKeyList.iterator();
         URL extensionUrl = null;

         while (extensionIter.hasNext()) {
            String extKey = extensionIter.next();
            extensionUrl = getExtensionUrlFromVc(vcInfo, locale, extKey);
            /*
             * SMS extension currently does not generate the correct
             * extension URL, hence constructing the extension URL
             * using VC Information
             */
            if (extKey.equals(TestConstants.SM_EXTENSION_KEY)) {
               extensionUrl = createSmsExtensionUrlFromVc(vcInfo);
            }
            if (extKey.equals(TestConstants.VSM_EXTENSION_KEY)) {
               extensionUrl = createVsmExtensionUrl(extensionUrl, vcInfo);
            }
            if (extKey.equals(TestConstants.EAM_EXTENSION_KEY)) {
               extensionUrl = createEamExtensionUrl(extensionUrl, vcInfo);
            }
            if (extensionUrl != null) {
               /*
                * TODO-- Comment this method after bug# 176571 is fixed.
                */
               if (extKey.equals(TestConstants.DR_EXTENSION_KEY)) {
                  extensionUrl = stripDRExtensionURL(extensionUrl);
               }
               if (extensionUrl != null) {
                  log.info(vcInfo.getEndpointUrl() + " is hosting "
                           + extKey + " in url:" + extensionUrl.toString());
                  ServiceInfo extInfo = new ServiceInfo(userName, password,
                           extensionUrl, keyStorePath, locale, extKey,
                           customInfo, vcInfo);
                  vecServiceInfo.add(extInfo);
               } else {
                  log.error(vcInfo.getEndpointUrl() + " is not hosting "
                           + extKey);
                  throw new Exception(vcInfo.getEndpointUrl()
                           + " is not hosting " + extKey);
               }
            }
         }
      }
      return vecServiceInfo.isEmpty() ? null : vecServiceInfo;
   }

   /**
    * This method strips out extensionURL needed to connect to DR, from the
    * actual extension returned by VC
    *
    * @param extensionUrl: extensionUrl returned by VC
    * @return DRUrl needed to connect to the DR web service
    */
   private static URL stripDRExtensionURL(URL extensionUrl)
      throws Exception
   {
      StringBuffer tempURL = new StringBuffer(extensionUrl.toString());
      log.info("Extension URL before converting---> " + tempURL);
      extensionUrl = new URL(tempURL.substring(tempURL.indexOf("|") + 1,
               tempURL.lastIndexOf("/")));
      log.info("Stripped DR extension URL---> " + extensionUrl);

      return extensionUrl;
   }

   /**
    * Get VC user session. If not already logged in, log in to VC server
    *
    * @param vcInfo serviceInfo for VC server
    * @return userSession current user session
    * @throws MethodFault, Exception
    */
   public static UserSession getVcUserSession(ServiceInfo vcInfo)
      throws Exception
   {
      UserSession session = null;
      SessionManager sessionManager = new SessionManager((ConnectAnchor) vcInfo.getConnectAnchor());
      ManagedObjectReference authMor = sessionManager.getSessionManager();

      if (!sessionManager.isLoggedIn()) {
         session = sessionManager.login(
                  authMor, vcInfo.getUserName(), vcInfo.getPassword(), null);
      } else {
         ManagedObjectReference sessionManagerMor = ((ServiceContent) vcInfo.getServiceContent()).getSessionManager();
         session = sessionManager.getCurrentSession(sessionManagerMor);
      }
      return session;
   }

   /**
    * Logout from VC
    *
    * @param vcInfo serviceInfo of the VC
    * @return true if current user logged out successfully from VC false
    *         otherwise
    * @throws MethodFault, Exception
    */
   public static void vcLogOut(ServiceInfo vcInfo)
      throws Exception
   {
      SessionManager sessionManager = new SessionManager((ConnectAnchor) vcInfo.getConnectAnchor());
      ManagedObjectReference authMor = sessionManager.getSessionManager();
      new SessionManager((ConnectAnchor)vcInfo.getConnectAnchor()).logout(authMor);
   }

}
/**
 *
 */
package com.vmware.vcqa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.Assert;

import com.vmware.vcqa.cm.CMConstants;
import com.vmware.vcqa.cm.CMException;
import com.vmware.vcqa.lookupservice.LookupServiceHelper;
import com.vmware.vcqa.lookupservice.sca.ServiceControlAgentFacade;
import com.vmware.vcqa.lookupservice.serviceregistration.ServiceRegistrationFacade;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.vasa.VasaTestConstants;
import com.vmware.vim.binding.lookup.ServiceRegistration;
import com.vmware.vim.binding.lookup.ServiceRegistration.Endpoint;
import com.vmware.vim.binding.lookup.ServiceRegistration.Info;
import com.vmware.vim.binding.sca.ServiceInfo;
import com.vmware.vim.binding.sca.control.ServiceState;
import com.vmware.vim.binding.sca.control.ServiceState.HealthStatus;
import com.vmware.vim.binding.sca.fault.ServiceManagerFault;
import com.vmware.vim.sso.client.SamlToken;

/**
 * @author Zheng Han
 */
public class ServiceHelper
{
   protected static final Logger log = LoggerFactory.getLogger(ServiceHelper.class);

   public static final String SMS_SERVICE_TYPE = "sms";
   public static final String VC_SERVICE_ENDPOINTTYPE = "com.vmware.vim";
   public static final String SMS_SERVICE_ENDPOINTTYPE = "com.vmware.vim.sms";
   public ServiceControlAgentFacade serviceControlAgentFacade;
   public ServiceRegistrationFacade serviceRegistrationFacade;

   private SamlToken token;

   private CMHelper cmHelper;

   private ServiceInfo vcServiceInfo;

   private ServiceInfo invServiceInfo;

   private ServiceInfo smsServiceInfo;

   public ServiceHelper(String hostName)
      throws Exception
   {
      SSOHelper ssoHelper = new SSOHelper(hostName);
      token = ssoHelper.getAdminBearerToken();
      cmHelper = new CMHelper(hostName);
      cmHelper.login(token, null);
      serviceControlAgentFacade = LookupServiceHelper.getServiceControlAgentFacadeForAdmin(hostName);
      serviceRegistrationFacade = LookupServiceHelper.getServiceRegistrationFacadeForAdmin(hostName);
   }

   /**
    * Get VC ServiceInfo from CM
    * @param cmHelper
    * @return
    * @throws CMException
    * @throws ServiceManagerFault
    */
   public ServiceInfo getVcServiceInfo()
      throws CMException, ServiceManagerFault
   {
      if (vcServiceInfo == null) {
         ServiceInfo[] infoArr = serviceControlAgentFacade.getServiceManager().list(
                  new String[] { "vpxd" });
         Assert.assertTrue(infoArr != null && infoArr.length > 0,
                  "Unable to get VCenter service info from CM");
         vcServiceInfo = infoArr[0];
      }
      return vcServiceInfo;
   }

   /**
    * Get Inventory ServiceInfo from CM
    * @param cmHelper
    * @return
    * @throws CMException
    * @throws ServiceManagerFault
    */
   public ServiceInfo getInvServiceInfo()
      throws CMException, ServiceManagerFault
   {
      if (invServiceInfo == null) {
         ServiceInfo[] infoArr = serviceControlAgentFacade.getServiceManager().list(
                  new String[] { "invsvc" });
         Assert.assertTrue(infoArr != null && infoArr.length > 0,
                  "Unable to get Inventory service info from CM");
         invServiceInfo = infoArr[0];
      }
      return invServiceInfo;
   }

   /**
    * Get SMS ServiceInfo from CM
    * @param cmHelper
    * @return
    * @throws CMException
    * @throws ServiceManagerFault
    */
   public ServiceInfo getSmsServiceInfo()
      throws CMException, ServiceManagerFault
   {
      if (smsServiceInfo == null) {
         ServiceInfo[] infoArr = serviceControlAgentFacade.getServiceManager().list(
                  new String[] { "sps" });
         Assert.assertTrue(infoArr != null && infoArr.length > 0,
                  "Unable to get SMS Service info from CM");
         smsServiceInfo = infoArr[0];
      }
      return smsServiceInfo;
   }

   /**
    * Get ServiceEndPoint from the ServiceInfo by serviceType
    * @param serviceInfo
    * @param serviceType
    * @return
    */
   public static ServiceRegistration.Endpoint getServiceEndPointByType(Info serviceInfo,
                                                                       String serviceType)
   {
      Endpoint[] endpoints = serviceInfo.getServiceEndpoints();
      for (Endpoint endpoint : endpoints) {
         if (endpoint.getEndpointType().getType().equals(serviceType)) {
            return endpoint;
         }
      }
      return null;
   }

   /**
    * Get VC Service EndPoint
    * @param cmHelper
    * @return
    * @throws Exception
    */
   public Endpoint getVcServiceEndPoint()
      throws Exception
   {
      Info vcInfo = serviceRegistrationFacade.getServiceByType(
               "com.vmware.cis", "vcenterserver")[0];
      Assert.assertNotNull(vcInfo, "Failed to get VC ServiceInfo");
      Endpoint endpoint = getServiceEndPointByType(vcInfo,
               VC_SERVICE_ENDPOINTTYPE);
      Assert.assertNotNull(endpoint, "Failed to get VC Service EndPoint");
      log.info("VC Service EndPoint {}", endpoint);
      return endpoint;
   }

   /**
    * Get SMS Service EndPoint
    * @param cmHelper
    * @return
    * @throws Exception
    */
   public Endpoint getSmsServiceEndPoint()
      throws Exception
   {
      Info smsInfo = serviceRegistrationFacade.getServiceByType(
               SMS_SERVICE_ENDPOINTTYPE, SMS_SERVICE_TYPE)[0];
      // ServiceInfo smsInfo = getSmsServiceInfo();
      Assert.assertNotNull(smsInfo, "Failed to get SMS ServiceInfo");
      Endpoint endpoint = getServiceEndPointByType(smsInfo,
               SMS_SERVICE_ENDPOINTTYPE);
      Assert.assertNotNull(endpoint, "Failed to get SMS Service EndPoint");
      log.info("SMS Service EndPoint {}", endpoint);
      return endpoint;
   }

   /**
    * Get SMS Localization Service EndPoint
    * @param cmHelper
    * @return
    * @throws Exception
    */
   public Endpoint getSmsLocalizationEndPoint()
      throws Exception
   {
      Info smsInfo =serviceRegistrationFacade.getServiceByType(SMS_SERVICE_ENDPOINTTYPE, SMS_SERVICE_TYPE)[0];
      Assert.assertNotNull(smsInfo, "Failed to get SMS ServiceInfo");
      Endpoint endpoint = getServiceEndPointByType(smsInfo,
               CMConstants.LOCALIZATION_ENDPOINTTYPE);
      Assert.assertNotNull(endpoint, "Failed to get Localization EndPoint");
      log.info("SMS Localization EndPoint {}", endpoint);
      return endpoint;
   }

   /**
    * Get Service Health Status
    * @param serviceId
    * @return
    * @throws CMException
    */
   public ServiceState getHealthStatus(String serviceId)
      throws CMException
   {
      return getHealthStatus(new String[] { serviceId })[0];
   }

   /**
    * Get batch Service Health Status
    * @param serviceId
    * @return
    * @throws CMException
    */
   public ServiceState[] getHealthStatus(String[] serviceIdList)
      throws CMException
   {
      return cmHelper.getHealthStatus(serviceIdList);
   }

   /**
    * Get Service Status
    * @param serviceId
    * @return
    * @throws CMException
    */
   public String getServiceStatus(String serviceId)
      throws CMException
   {
      return cmHelper.getServiceStatus(serviceId);
   }

   /**
    * Start Service
    * @param serviceId
    * @throws CMException
    */
   public void startService(String serviceId)
      throws CMException
   {
      cmHelper.startService(serviceId);
      cmHelper.waitForStatus(serviceId, CMConstants.SERVICE_STATUS_RUNNING);
   }

   /**
    * Stop Service
    * @param serviceId
    * @throws CMException
    */
   public void stopService(String serviceId)
      throws CMException
   {
      cmHelper.stopService(serviceId);
      cmHelper.waitForStatus(serviceId, CMConstants.SERVICE_STATUS_STOPPED);
   }

   /**
    * Restart Service
    * @param serviceId
    * @throws CMException
    */
   public void restartService(String serviceId)
      throws CMException
   {
      cmHelper.reStartService(serviceId);
   }

   /**
    * @return the cmHelper
    */
   public CMHelper getCmHelper()
   {
      return cmHelper;
   }

   /**
    * @return the token
    */
   public SamlToken getSamlToken()
   {
      return token;
   }

   /**
    * Verify service health status
    * @param serviceInfo
    * @param expectedCode
    * @return
    * @throws CMException
    */
   public boolean verifyHealthStaus(ServiceInfo serviceInfo,
                                    HealthStatus expectedCode)
      throws CMException, InterruptedException
   {
      int attemptCount = 1;
      boolean healthStatusCodeMatched = false;
      while (attemptCount <= 3) {
         ServiceState healthStatus = getHealthStatus(serviceInfo.getServiceId());
         log.info("HealthStatus={}", healthStatus);
         HealthStatus code = HealthStatus.valueOf(healthStatus.getHealthStatus());
         if (code != expectedCode) {
            log.info("Attempt {} failed to match expectedCode", attemptCount);
            log.info("code={} does not match expectedCode={}!", code,
                     expectedCode);
            attemptCount++;
            ThreadUtil.sleep(VasaTestConstants.SM_HEALTH_STATUS_POLL_INTERVAL);
         } else {
            healthStatusCodeMatched = true;
            break;
         }
      }
      return healthStatusCodeMatched;
   }
}

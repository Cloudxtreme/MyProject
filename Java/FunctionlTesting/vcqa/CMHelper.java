/* **********************************************************************
 * Copyright 2010-2014 VMware, Inc.  All rights reserved. VMware Confidential
 * *********************************************************************/
package com.vmware.vcqa;

import java.net.URISyntaxException;
import java.security.PrivateKey;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.cis.cm.client.ComponentManagerClient;
import com.vmware.vcqa.cm.CMConstants;
import com.vmware.vcqa.cm.CMException;
import com.vmware.vcqa.lookupservice.sca.ServiceControlAgentFacade;
import com.vmware.vcqa.sso.KeyStoreHelper;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.UrlUtil;
import com.vmware.vim.binding.cis.cm.SearchCriteria;
import com.vmware.vim.binding.cis.cm.ServiceEndPoint;
import com.vmware.vim.binding.cis.cm.ServiceInfo;
import com.vmware.vim.binding.cis.cm.ServiceType;
import com.vmware.vim.binding.cis.cm.site.Folder;
import com.vmware.vim.binding.cis.cm.site.Site;
import com.vmware.vim.binding.cis.cm.site.SiteManager;
import com.vmware.vim.binding.impl.cis.cm.SearchCriteriaImpl;
import com.vmware.vim.binding.impl.cis.cm.ServiceTypeImpl;
import com.vmware.vim.binding.sca.control.ServiceState;
import com.vmware.vim.binding.sca.fault.ServiceManagerFault;
import com.vmware.vim.sso.client.SamlToken;
import com.vmware.vim.vmomi.client.common.impl.ClientFutureImpl;
import com.vmware.vim.vmomi.client.http.impl.AllowAllThumbprintVerifier;
import com.vmware.vim.vmomi.core.Future;

public class CMHelper {
   private final Logger log = LoggerFactory.getLogger(getClass());
   private ComponentManagerClient _cmClient;
   private String hostName;
   private ServiceControlAgentFacade serviceControlAgentFacade;
   /**
    * Empty constructor
    */
   private CMHelper() {

   }
   /**
    * Creates and returns a helper object for CM in the hostname
    * @param hostName
    * @throws CMException
    */
   public CMHelper(String hostName) throws CMException {
      this.hostName = hostName;

      try {
         KeyStoreHelper ks = new KeyStoreHelper("/" +
               CMConstants.KEYSTORE,
               CMConstants.KEYSTORE_PWD.toCharArray());
         _cmClient = new ComponentManagerClient
               (UrlUtil.getURI(UrlUtil.HTTPS_PROTOCOL, hostName,UrlUtil.HTTPS_PORT, "/cm/sdk"), ks.getStore(),
         new AllowAllThumbprintVerifier());
      } catch (NumberFormatException e) {
         throw new CMException("Unable to create cm client " + hostName , e);
      } catch (URISyntaxException e) {
         throw new CMException("Unable to create cm client " + hostName , e);
      } catch (Exception e) {
         throw new CMException("Exception thrown: ", e);
      }
   }

   /**
    * Returns the sso configured to the CM
    * @return
    * @throws CMException
    */
   public ServiceInfo getSSO() throws CMException {
      ServiceInfo serviceInfo = null;
      try {
         serviceInfo = getClient().lookupSso(false);
      } catch (ExecutionException e) {
         throw new CMException("Unable to get SSO service info from CM " , e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to get SSO service info from CM " , e);
      }
      return serviceInfo;
   }
   /**
    * Gets the service id and returns the endpoint Certificate
    * @param serviceId
    * @return
    */
   public String getServiceEndpointCert(String serviceId) throws CMException {
      ServiceEndPoint[] endpointArr = this.getSSO().getServiceEndPoints();
      String sslCert = null;
      for (ServiceEndPoint endpoint : endpointArr) {
         if ( endpoint.getEndPointType().getTypeId().equals(serviceId)) {
            sslCert = endpoint.getSslTrust()[0];
         }
      }
      return sslCert;
   }
   /**
    * login the user to the CM
    * @param token
    * @param key
    * @throws CMException
    */
   public void login(SamlToken token , PrivateKey key) throws CMException {
      try {
         log.info("Logging in to cm " + hostName + " using subject " + token.getSubject().getName());
        _cmClient.login(token, key);
        serviceControlAgentFacade = new ServiceControlAgentFacade(hostName, token, null);
      } catch (ExecutionException e) {
         throw new CMException("Unable to login user "+ token.getSubject() + "from CM " , e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to login user "+ token.getSubject() + "from CM " , e);
      } catch (Exception e) {
         // TODO Auto-generated catch block
         e.printStackTrace();
      }
   }

   /**
    * logout the user session from CM
    * @throws CMException
    */
   public void logout() throws CMException{
      if (_cmClient != null) {
         try {
            try {
               log.info("Logging out user from CM " + hostName);
               _cmClient.logout();
            } catch (ExecutionException e) {
               throw new CMException("Unable to logout user session from CM " , e);
            } catch (InterruptedException e) {
               throw new CMException("Unable to logout user session from CM " , e);
            }
         } finally {
            try {
               _cmClient.shutdown();
            } catch (SecurityException se) {
               throw new CMException("Unable to dispose the CM client" , se);
            }
         }
      }
   }

   public ComponentManagerClient getClient() throws CMException {
      if (_cmClient != null) {
         return _cmClient;
      }
      else {
         throw new CMException("CmClient is not instantiated");
      }
   }

   /**
    * Get all the services registered to the CM
    * @throws CMException
    */
   public void getCoreServices() throws CMException {
      SearchCriteria criteria = new SearchCriteriaImpl();
      ServiceType servicetype = new ServiceTypeImpl();
      servicetype.setProductId(CMConstants.CIS_PRODUCT_ID);
      criteria.setServiceType(servicetype);
      ServiceInfo[] serviceInfo;
      try {
         serviceInfo = _cmClient.lookup(criteria);
         for (int i=0;i < serviceInfo.length; i++) {
            ServiceEndPoint[] endpoints  = serviceInfo[i].getServiceEndPoints();
            for (int j = 0 ;j < endpoints.length; j++) {
               System.out.println(endpoints[i].getUrl());
            }
         }
      } catch (ExecutionException e) {
         throw new CMException("Unable to get all services from CM " , e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to get all services from CM " , e);
      }

   }

   /**
    * Gets the service type id and returns the ServiceInfo
    *
    * @param typeId
    * @return
    * @throws CMException
    */
   public ServiceInfo[] getServiceByType(String typeId)
      throws CMException
   {
      SearchCriteria criteria = new SearchCriteriaImpl();
      ServiceType servicetype = new ServiceTypeImpl();
      servicetype.setTypeId(typeId);
      servicetype.setProductId(CMConstants.CIS_PRODUCT_ID);
      criteria.setServiceType(servicetype);
      ServiceInfo[] serviceInfo = null;
      try {
         Future<ServiceInfo[]> serviceInfoList = new ClientFutureImpl<ServiceInfo[]>();
         _cmClient.getServiceManager().search(criteria, serviceInfoList);
         serviceInfo = serviceInfoList.get();
      } catch (ExecutionException e) {
         throw new CMException("Unable to get service by type " + typeId, e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to get service by type " + typeId, e);
      }
      return serviceInfo;
   }

   /**
    * Gets the service type id and returns the ServiceInfo
    * @param typeId
    * @return
    * @throws CMException
    */
   public ServiceInfo[] getServiceByType(ServiceType serviceType) throws CMException {
      SearchCriteria criteria = new SearchCriteriaImpl();
      criteria.setServiceType(serviceType);
      ServiceInfo[] serviceInfo = null;
      try {
         Future<ServiceInfo[]> serviceInfoList = new ClientFutureImpl<ServiceInfo[]>();
         _cmClient.getServiceManager().search(criteria, serviceInfoList);
         serviceInfo = serviceInfoList.get();
      } catch (ExecutionException e) {
         throw new CMException("Unable to get service by type "+ serviceType.getTypeId() , e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to get service by type "+ serviceType.getTypeId() , e);
      }
      return serviceInfo;
   }

   /**
    * Gets service type and service endpointprotocol and returns the service endpoint URL
    * @param serviceType
    * @param endpointProtocol
    * @return
    * @throws CMException
    */
   public String getServiceByEndpoint(String serviceType, String endpointProtocol) throws CMException {
      ServiceEndPoint[] serviceEndpointsArr = null;
      ServiceInfo[] serviceInfo = getServiceByType(serviceType);
      for (int i = 0; i < serviceInfo.length; i++) {
         log.info("Service Id: " + serviceInfo[i].getServiceId()
               + " owner : " + serviceInfo[i].getOwnerId() + " Folder : "
               + serviceInfo[i].getFolder().getDisplayName()
               + " servicetype :"
               + serviceInfo[i].getServiceType().getTypeId());
         serviceEndpointsArr = serviceInfo[i].getServiceEndPoints();
         break;
      }
      for (int i = 0;i <serviceEndpointsArr.length; i++) {
         if((serviceEndpointsArr[i].getEndPointType().getEndPointProtocol()).equals(endpointProtocol)){
            return serviceEndpointsArr[i].getUrl().toString();
         }
      }
      return null;
   }

   /**
    * Get service end point URL Strings for the given service type id and end
    * point type id.
    *
    * @param serviceTypeId Service id Ex: CMConstants.INVENTORY_SERVICE_ID.
    * @param endpointTypeId End point type. Ex:
    *           InventoryServiceConstants.IS_KVCLIENT_ENDPOINT_TYPE.
    */
   public List<String> getServiceURLFromCM(ServiceType serviceType,
                                           String endpointTypeId)
      throws Exception
   {
      List<String> serviceUrls = new ArrayList<String>();
      ServiceInfo[] serviceInfo = getServiceByType(serviceType);
      if (serviceInfo.length < 1) {
         throw new CMException(
                  "getServiceURLFromCM : Unable to obtain service info from Component Manager."
                           + "Service :" + serviceType.getTypeId());
      }
      for (ServiceInfo sInfo : serviceInfo) {
         ServiceEndPoint[] serviceEndpoints = sInfo.getServiceEndPoints();
         for (ServiceEndPoint endpoint : serviceEndpoints) {
            if (endpoint.getEndPointType().getTypeId().equals(endpointTypeId)) {
               serviceUrls.add(endpoint.getUrl().toString());
               log.info("Service endpoint url " + endpoint.getUrl().toString());
            }
         }
      }

      if (serviceUrls.size() < 1) {
         throw new CMException(
                  "getServiceURLFromCM : Unable to obtain service URL from Component Manager."
                           + "Service :" + serviceType.getTypeId()
                           + "End point Type id : " + endpointTypeId);
      }
      return serviceUrls;
   }

   /**
    * Gets an array of service ids and returns the health status
    * @param serviceIdArr
    * @return
    * @throws CMException
    */
   public ServiceState[] getHealthStatus(String[] serviceIdArr) throws CMException {
      try {
    	  ServiceState[] serviceStates = serviceControlAgentFacade.getServiceStates(serviceIdArr, 
    	           CMConstants.SERVICE_CONTROL_TIMEOUT);
          return serviceStates;
         } catch (IllegalArgumentException e) {
            throw new CMException("Unable to get healthStatus of service ",e);
         } catch (ServiceManagerFault e) {
        	throw new CMException("Unable to get healthStatus of service ",e);
		}
   }

   /**
    * Get the local cm info on a multi site deployment
    * @return
    * @throws CMException
    */
   public ServiceInfo getLocalCM() throws CMException {
      ServiceInfo cmInfo = null;
      try {
         cmInfo = getClient().lookupComponentManager(true);
      } catch (ExecutionException e) {
         throw new CMException("Unable to get local CM info ", e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to get local CM info ", e);
      }
      return cmInfo;
   }
   /**
    * Will return the secondary instance configured to CM
    * @return
    * @throws CMException
    */
   public String getSecondaryLduIp() throws CMException {
      ServiceInfo[] infoArr = getServiceByType(CMConstants.CM_SERVICE_ID);
      String hostIp = null;
      String cmHostId = getLocalCM().getHostId();
      log.debug("Getting local cm host id " + cmHostId );
      for (ServiceInfo info : infoArr) {
         log.debug(info.getServiceEndPoints()[0].getUrl().getHost());
         if (!info.getHostId().equals(cmHostId)) {
            hostIp = info.getServiceEndPoints()[0].getUrl().getHost();
            log.info("Secondary LDU IP for CM : " + hostName + " : "+hostIp);
            break;
         }
      }
      return hostIp;
   }

   /**
    * Returns the ServiceStatus of the service
    * @param serviceId
    * @return
    * @throws CMException
    */
   public String getServiceStatus(String serviceId) throws CMException {
      String status = null;
      Future<ServiceState[]> getServiceStatusOp = new ClientFutureImpl<ServiceState[]>();
      serviceControlAgentFacade.getServiceControlManager().getServiceStates(new String[]{serviceId}, CMConstants.SERVICE_CONTROL_TIMEOUT, getServiceStatusOp);
      try {
         log.info("Waiting for the getservicestatus to complete");
         while (!getServiceStatusOp.isDone()) {
            Thread.sleep(CMConstants.SERVICE_CONTROL_TIMEOUT/10);
         }
         ServiceState[] states = getServiceStatusOp.get();
         Assert.assertNotNull(states, "No state returned");
         Assert.assertNotEmpty(states, "No state returned");
         status = getServiceStatusOp.get()[0].getControlStatus();
      } catch (ExecutionException e) {
         throw new CMException("Unable to getServiceStatus of the service " + serviceId, e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to getServiceStatus of the service " + serviceId, e);
      }
      return status.trim();
   }

   /**
    * Start the service and returns status
    * @throws CMException
    */
   public void startService(String serviceId) throws CMException {
      Future<Void> startServiceOp = new ClientFutureImpl<Void>();
      serviceControlAgentFacade.getServiceControlManager().startService(serviceId, CMConstants.SERVICE_CONTROL_TIMEOUT, startServiceOp);
      try {
         log.info("Waiting for the startService to complete");
         while (!startServiceOp.isDone()) {
            Thread.sleep(CMConstants.SERVICE_CONTROL_TIMEOUT / 10);
         }
         startServiceOp.get();
      } catch (ExecutionException e) {
         throw new CMException("Unable to start the service " + serviceId, e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to start the service " + serviceId, e);
      }
   }

   /**
    * Stop the service and returns status
    * @throws CMException
    */
   public void stopService(String serviceId) throws CMException {
      Future<Void> stopServiceOp = new ClientFutureImpl<Void>();
      serviceControlAgentFacade.getServiceControlManager().stopService(serviceId, CMConstants.SERVICE_CONTROL_TIMEOUT, stopServiceOp);
      try {
         log.info("Waiting for the stopservice to complete");
         while (!stopServiceOp.isDone()) {
            Thread.sleep(CMConstants.SERVICE_CONTROL_TIMEOUT / 10);
         }
         stopServiceOp.get();
      } catch (ExecutionException e) {
         throw new CMException("Unable to stop the service " + serviceId, e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to stop the service " + serviceId, e);
      }
   }

   /**
    * Restart the service and returns status
    * @throws CMException
    */
   public void reStartService(String serviceId) throws CMException {
      Future<Void> restartServiceOp = new ClientFutureImpl<Void>();
      serviceControlAgentFacade.getServiceControlManager().restartService(serviceId, CMConstants.SERVICE_CONTROL_TIMEOUT, restartServiceOp);
      try {
         log.info("Waiting for the restartService to complete");
         while (!restartServiceOp.isDone()) {
            Thread.sleep(CMConstants.SERVICE_CONTROL_TIMEOUT / 10);
         }
         restartServiceOp.get();
      } catch (ExecutionException e) {
         throw new CMException("Unable to restart the service " + serviceId, e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to restart the service " + serviceId, e);
      }
   }
   /**
    * gets the sites from the cm
    * @return
    * @throws CMException
    */
   public Site[] retrieveSites() throws CMException {
      Site[] sites = null;
      try {
         Future<Site[]> retrieveSitesOp = new ClientFutureImpl<Site[]>();
         SiteManager siteManager = getClient().getSubManager(SiteManager.class);
         siteManager.retrieveSites(retrieveSitesOp);
         sites = retrieveSitesOp.get();
      } catch (ExecutionException e) {
         throw new CMException("Unable to get sites from cm ", e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to get sites from cm ", e);
      }
      return sites;
   }

   /**
    * Gets the local site from the cm
    * @return
    * @throws CMException
    */
   public Folder retrieveLocalSite() throws CMException {
      Folder localsite = null;
      try {
         Future<Folder> retrieveLocalSiteOp = new ClientFutureImpl<Folder>();
         SiteManager siteManager = getClient().getSubManager(SiteManager.class);
         siteManager.retrieveLocalSite(retrieveLocalSiteOp);
         localsite = retrieveLocalSiteOp.get();
      } catch (ExecutionException e) {
         throw new CMException("Unable to get localsite from cm ", e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to get localsite from cm ", e);
      }
      return localsite;
   }

   /**
    * Gets the localgroup from the cm
    * @return
    * @throws CMException
    */
   public Folder retrieveLocalGroup() throws CMException {
      Folder localgroup = null;
      try {
         Future<Folder> retrieveGroupOp = new ClientFutureImpl<Folder>();
         SiteManager siteManager = getClient().getSubManager(SiteManager.class);
         siteManager.retrieveLocalGroup(retrieveGroupOp);
         localgroup = retrieveGroupOp.get();
      } catch (ExecutionException e) {
         throw new CMException("Unable to get localGroup from cm ", e);
      } catch (InterruptedException e) {
         throw new CMException("Unable to get localGroup from cm ", e);
      }
      return localgroup;
   }

   /**
    * Waits for a futureoperation to complete
    * @param futureOp
    */
   public void waitForOperation(Future<?> futureOp) {
      while (!futureOp.isDone()) {
         log.info("Waiting for the async operation to complete");
         try {
            Thread.sleep(CMConstants.SERVICE_CONTROL_TIMEOUT / 10);
         } catch (InterruptedException e) {
            e.printStackTrace();
         }
      }
   }

   /**
    * Wait till the service status returns the expected status
    * @param serviceId
    * @param expectedStatus
    * @throws CMException
    */
   public void waitForStatus(String serviceId, String expectedStatus) throws CMException {
      int attemptWait = 0;
      log.info("Get the status of service : " + serviceId );
      while (!getServiceStatus(serviceId).equalsIgnoreCase(expectedStatus)) {
         if (attemptWait++ == 5) {
            break;
         } else {
            log.info("Waiting for the service status " + expectedStatus);
            try {
               Thread.sleep(5 * 1000);
            } catch (InterruptedException e) {
               throw new CMException("Unable to sleep while waiting for " +
                        "service status to return " + expectedStatus, e);
            }
         }
      }
   }
   /**
    * Returns the local service of any type array. Compares the hostid parameter of serviceinfo
    * @param serviceArr
    * @return
    * @throws CMException
    */
   public ServiceInfo getLocalService(ServiceInfo[] serviceArr) throws CMException {
      ServiceInfo cmInfo = getLocalCM();
      log.debug("Matching the serviceinfo hostid with localcm hostid");
      for (ServiceInfo info : serviceArr) {
         if (info.getHostId().equals(cmInfo.getHostId())) {
            return info;
         }
      }
      log.error("the CM does not have the service of specific type ");
      throw new CMException("the CM does not have the service of specific type ", new Exception());
   }

   /*
    * Returns VC/CM host Id
    */

   public String getCMHostId()
      throws CMException
   {
      ServiceInfo[] infoArr = getServiceByType(CMConstants.VCENTER_SERVICE_ID);
      String hostId = infoArr[0].getHostId();
      return hostId;
   }


   public void allowSyncForCM() throws InterruptedException
   {
      log.info("Allow for sync across LDUs");
      Thread.sleep(CMConstants.HEALTH_POLLING_INTERVAL);
   }



}

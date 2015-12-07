/* **********************************************************************
 * Copyright 2010-2014 VMware, Inc.  All rights reserved. VMware Confidential
 * *********************************************************************/
package com.vmware.vcqa;

import static com.vmware.vcqa.TestConstants.TESTINPUT_TESTBEDINFOJSONFILE;
import static com.vmware.vcqa.certmgr.utils.CertConstant.MACHINE_SSL_CERT;
import static com.vmware.vcqa.certmgr.utils.CertConstant.__MACHINE_CERT;
import static com.vmware.vcqa.sso.SSOConstants.SSO_ADMIN_PASSWORD;
import static com.vmware.vcqa.sso.SSOConstants.SSO_ADMIN_USER;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.net.InetAddress;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.security.Key;
import java.security.PrivateKey;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Executors;

import javax.xml.parsers.DocumentBuilderFactory;

import org.apache.commons.codec.binary.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.xml.sax.InputSource;

import sun.net.util.IPAddressUtil;

import com.vmware.vcqa.authorizationservice.AuthorizationServiceHelper;
import com.vmware.vcqa.certmgr.CertMgrCert;
import com.vmware.vcqa.cliwrapper.VecsCli;
import com.vmware.vcqa.cm.CMConstants;
import com.vmware.vcqa.cm.CMException;
import com.vmware.vcqa.execution.TestDataHandler;
import com.vmware.vcqa.mxn.INodeManager;
import com.vmware.vcqa.mxn.NodeManager;
import com.vmware.vcqa.ossupport.OperatingSystemSupport;
import com.vmware.vcqa.ossupport.OsSupportFactory;
import com.vmware.vcqa.sso.KeyStoreHelper;
import com.vmware.vcqa.sso.SSOConstants;
import com.vmware.vcqa.sso.SSOException;
import com.vmware.vcqa.sso.SSOUtil;
import com.vmware.vim.binding.cis.cm.ServiceEndPoint;
import com.vmware.vim.sso.PrincipalId;
import com.vmware.vim.sso.admin.GroupDetails;
import com.vmware.vim.sso.admin.PersonDetails;
import com.vmware.vim.sso.admin.PrincipalSelfManagement;
import com.vmware.vim.sso.admin.SolutionDetails;
import com.vmware.vim.sso.admin.SolutionUser;
import com.vmware.vim.sso.admin.client.AdminClient;
import com.vmware.vim.sso.admin.client.AdminClientFactory;
import com.vmware.vim.sso.admin.client.ClientConfiguration;
import com.vmware.vim.sso.admin.client.ClientConfiguration.AuthenticationData;
import com.vmware.vim.sso.admin.client.vmomi.VmomiClientConfiguration;
import com.vmware.vim.sso.admin.client.vmomi.VmomiClientFactory;
import com.vmware.vim.sso.admin.exception.CertificateValidationException;
import com.vmware.vim.sso.admin.exception.DuplicateSolutionCertificateException;
import com.vmware.vim.sso.admin.exception.InvalidPrincipalException;
import com.vmware.vim.sso.admin.exception.NoPermissionException;
import com.vmware.vim.sso.admin.exception.NotAuthenticatedException;
import com.vmware.vim.sso.admin.exception.PasswordPolicyViolationException;
import com.vmware.vim.sso.client.DefaultSecurityTokenServiceFactory;
import com.vmware.vim.sso.client.SamlToken;
import com.vmware.vim.sso.client.SecurityTokenService;
import com.vmware.vim.sso.client.SecurityTokenServiceConfig;
import com.vmware.vim.sso.client.SecurityTokenServiceConfig.ConnectionConfig;
import com.vmware.vim.sso.client.SecurityTokenServiceConfig.HolderOfKeyConfig;
import com.vmware.vim.sso.client.TokenSpec;
import com.vmware.vim.sso.client.exception.InvalidTokenException;
import com.vmware.vim.sso.client.exception.TokenRequestRejectedException;
import com.vmware.vim.vmomi.client.http.impl.AllowAllThumbprintVerifier;

/**
 * Class to handle the SSO token generation passing sso hostname, username and
 * password.
 *
 * @author psekar
 *
 */
public class SSOHelper {
   private final static Logger log = LoggerFactory.getLogger(SSOHelper.class);
   private URL STS_URL;
   private URI SSO_ADMIN_URI;
   private String hostname;
   private String stsEndpointCert;
   private ServiceInfo vcServiceInfo;
   private String[] solutionUserSsoGrps;
   private OperatingSystemSupport osSupport;
   private VecsCli vecsCli;
   private boolean isCertChanged;

   public SSOHelper(String hostname) throws SSOException, CMException{
      this.hostname = hostname;
      CMHelper cmHelper = null ;
      try {
         cmHelper = new CMHelper(hostname);
         com.vmware.vim.binding.cis.cm.ServiceInfo ssoInfo = cmHelper.getSSO();
         ServiceEndPoint[] ssoEndpoints = ssoInfo.getServiceEndPoints();
         for (ServiceEndPoint endpoint : ssoEndpoints) {
            if (endpoint.getEndPointType().getTypeId().equals(CMConstants.SSO_ADMIN_SERVICE_ENDPOINT_TYPE)) {
               SSO_ADMIN_URI = endpoint.getUrl();
               log.debug("SSO admin sdk endpoint url " + endpoint.getUrl().toString());
            }
            else if (endpoint.getEndPointType().getTypeId().equals(CMConstants.SSO_STS_SERVICE_ENDPOINT_TYPE)) {
               stsEndpointCert = endpoint.getSslTrust()[0];
               try {
                  log.debug("STS endpoint url " + endpoint.getUrl().toString());
                  STS_URL = new URL(endpoint.getUrl().toString());
               } catch (MalformedURLException e) {
                  throw new CMException("Unable to retrieve STS url from the componentManager", e);
               }
            }
         }
      } finally {
         if (cmHelper != null) {
            cmHelper.logout();
         }
      }
   }

   // overloaded constructor to use only when SSL cert is changed in VECS
   public SSOHelper(String hostname, boolean isCertChanged) throws SSOException, CMException{
      CMHelper cmHelper = null ;
      try {
         this.isCertChanged = isCertChanged;
         cmHelper = new CMHelper(hostname);
         // To get any token from SSO, get the Machine SSL cert from VECS (instead of CM SSL Trust)
         // as CM's SSL Trust will be deprecated soon. See PR#1259351
         // Machine SSL cert in VECS is the 'source of truth' moving forward
         // For MxN, construct VECS CLI using NodeManager
         vcServiceInfo = TestInputHandler.getServiceInfo().get(0);
         // if vc service info has infra node set, then it is MxN setup
         if (TestDataHandler.getSingleton().getData().getString(TESTINPUT_TESTBEDINFOJSONFILE) != null
                  && vcServiceInfo.getInfraNode() != null) {
            log.info("Running on MxN setup..");
            // check if the hostname string passed is a DNS hostname instead of IP address
            // Note: NodeManager supports only IP address as testbedInfoJsonFile contains only IP address
            // Hence do a reverse DNS lookup of IP address from DNS hostname
            if(!(IPAddressUtil.isIPv4LiteralAddress(hostname)
                     || IPAddressUtil.isIPv6LiteralAddress(hostname))) {
               log.info("Host name passed is: " + hostname);
               hostname = InetAddress.getByName(hostname).getHostAddress();
               log.info("Got the IP address: " + hostname);
            }
            INodeManager<com.vmware.vcqa.mxn.Node> nodeManager = new NodeManager<com.vmware.vcqa.mxn.Node>(
                     com.vmware.vcqa.mxn.Node.class);
            com.vmware.vcqa.mxn.Node infraNode = nodeManager.getInfrastructureNode(hostname);
            // check if the hostname passed is the infra node's hostname, if not get the infra hostname from
            // management node using NodeManager class
            if(infraNode == null) {
               infraNode = (com.vmware.vcqa.mxn.Node)
                        nodeManager.getManagementNode(hostname).getInfrastructureNode();
               log.info("Found Infrastructure Hostname of the Management Node and using it to "
                        + "get the SSL cert from VECS..");
            } else {
               log.info("Infrastructure Hostname is passed and using it to get the "
                        + "SSL cert from VECS..");
            }
            // VECS do not support VMODL like APIs (remotability) and hence we have to run
            // the command-cli or api on the server machine (cloudvm or ciswin)
            vecsCli = new VecsCli(infraNode);
         } else {
            // For embedded node, construct VECS CLI using ossupport & service info
            String machineUsername = vcServiceInfo.getMachineUsername();
            String machinePassword = vcServiceInfo.getMachinePassword();
            log.info("Running on Embedded setup..");
            // VECS do not support VMODL like APIs (remotability) and hence we have to run
            // the command-cli or api on the server machine (cloudvm or ciswin)
            osSupport = OsSupportFactory.getOsSupport(hostname, machineUsername, machinePassword, null, null);
            vecsCli = new VecsCli(osSupport);
         }
         com.vmware.vim.binding.cis.cm.ServiceInfo ssoInfo = cmHelper.getSSO();
         ServiceEndPoint[] ssoEndpoints = ssoInfo.getServiceEndPoints();
         for (ServiceEndPoint endpoint : ssoEndpoints) {
            if (endpoint.getEndPointType().getTypeId().equals(CMConstants.SSO_ADMIN_SERVICE_ENDPOINT_TYPE)) {
               SSO_ADMIN_URI = endpoint.getUrl();
               log.debug("SSO admin sdk endpoint url " + endpoint.getUrl().toString());
            }
            else if (endpoint.getEndPointType().getTypeId().equals(CMConstants.SSO_STS_SERVICE_ENDPOINT_TYPE)) {
               try {
                  log.debug("STS endpoint url " + endpoint.getUrl().toString());
                  STS_URL = new URL(endpoint.getUrl().toString());
               } catch (MalformedURLException e) {
                  throw new CMException("Unable to retrieve STS url from the componentManager", e);
               }
            }
         }
      } catch(Exception e) {
         log.error("Caught exception during SSOHelper creation: "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } finally {
         if (cmHelper != null) {
            cmHelper.logout();
         }
      }
   }

   /**
    * Will return the private key of the local keystore used by SSO
    * @return
    */
   public static PrivateKey getPrivatekey() {
      KeyStoreHelper ks = new KeyStoreHelper(SSOConstants.HOK_KEYSTORE, null);
      return ks.getPrivateKey(SSOConstants.HOK_CERT_ALIAS, SSOConstants.HOK_CERT_PASSWORD);
   }

   /**
    * temp method to avoid other common code failures Will be removed in next CLN
    * @throws SSOException
    * @throws CMException
    */
   public static SamlToken getSamlToken(String hostname, String subject, String password) throws SSOException, CMException{
      return new SSOHelper(hostname).getBearerToken(subject, password);
   }

   /**
    * Creates a solution User (HokUser) and returns the Samltoken
    * @param ssoServer
    * @return
    * @throws SSOException
    * @throws NotAuthenticatedException
    * @throws NoPermissionException
    */
   public SamlToken getHokToken() throws SSOException, NoPermissionException, NotAuthenticatedException, Exception{
      SamlToken token = null;
      AdminClient adminClient = null;
      try {
         KeyStoreHelper ksHelper =
               new KeyStoreHelper(SSOConstants.HOK_KEYSTORE, null);
         X509Certificate[] signingCerts =
               this.getTrustedCertificates();
         TokenSpec.Builder builder =
               new TokenSpec.Builder(SSOConstants.DEFAULT_TOKEN_VALIDITY_SEC);
         builder.delegationSpec(new TokenSpec.DelegationSpec(
               true  , null ));
         TokenSpec tokenSpec = builder.createTokenSpec();
         CMHelper cmHelper = new CMHelper(hostname);
         String sslCert = cmHelper.getServiceEndpointCert(CMConstants.SSO_STS_SERVICE_ENDPOINT_TYPE);
         ConnectionConfig connConfig =
              new ConnectionConfig(STS_URL,
                      new X509Certificate[] { parseSslCert(sslCert) },
                      null);
         if(isCertChanged) {
            sslCert = vecsCli.getCertString(MACHINE_SSL_CERT, __MACHINE_CERT);
            connConfig = new ConnectionConfig(STS_URL, new X509Certificate[] {
                     CertMgrCert.readCertificateFromStr(sslCert) }, null);
         }
         adminClient = getAuthenticatedAdminClient();
         SolutionUser solutionUser = adminClient.getPrincipalDiscovery().findSolutionUser(
                  SSOConstants.HOK_CERT_ALIAS);
         if (solutionUser != null) {
            log.info("Soution user already exist with name: "
                     + SSOConstants.HOK_CERT_ALIAS);
         } else {
            createSolutionUser(SSOConstants.HOK_CERT_ALIAS,
                     "test solution user for hok token",
                     ksHelper.getCertificate(SSOConstants.HOK_CERT_ALIAS), true);
        }
         HolderOfKeyConfig hokConfig =
               new HolderOfKeyConfig(ksHelper.getPrivateKey(
                     SSOConstants.HOK_CERT_ALIAS, SSOConstants.HOK_CERT_PASSWORD),
                     ksHelper.getCertificate(SSOConstants.HOK_CERT_ALIAS), null);
         SecurityTokenServiceConfig stsConfig =
               new SecurityTokenServiceConfig(connConfig,
                     signingCerts,
                     null , hokConfig);
         SecurityTokenService stsClient =
               DefaultSecurityTokenServiceFactory
                    .getSecurityTokenService(stsConfig);
         token = stsClient
               .acquireTokenByCertificate(tokenSpec);

      } catch (InvalidTokenException e) {
         log.error("Invalid token: "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (TokenRequestRejectedException e) {
         log.error("Token request rejected: "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (com.vmware.vim.sso.client.exception.CertificateValidationException e) {
         log.error("Certificate validation exception "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (CMException e) {
         log.error("Component manager exception: "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } finally {
         if (adminClient != null) {
            adminClient.dispose();
         }
      }
      return token;
   }

   /**
    * Creates a solution User and returns the Holder of Key token Samltoken
    * The solution user certificate has to be in the HokKeystore.jks
    * @param hokSubject
    * @param certificate
    * @param privateKey
    * @return
    * @throws SSOException
    */
   public SamlToken getHokToken(String hokSubject, X509Certificate certificate,
         Key privateKey) throws SSOException, Exception {
      SamlToken token = null;
      try {
         KeyStoreHelper ksHelper =
               new KeyStoreHelper(SSOConstants.HOK_KEYSTORE, null);
         X509Certificate[] signingCerts =
               this.getTrustedCertificates();
         TokenSpec.Builder builder =
               new TokenSpec.Builder(SSOConstants.DEFAULT_TOKEN_VALIDITY_SEC);
         builder.delegationSpec(new TokenSpec.DelegationSpec(
               true  , null ));
         TokenSpec tokenSpec = builder.createTokenSpec();
         CMHelper cmHelper = new CMHelper(hostname);
         String sslCert = cmHelper.getServiceEndpointCert(CMConstants.SSO_STS_SERVICE_ENDPOINT_TYPE);
         ConnectionConfig connConfig =
              new ConnectionConfig(STS_URL,
                      new X509Certificate[] { parseSslCert(sslCert) },
                      null);
         if(isCertChanged) {
            sslCert = vecsCli.getCertString(MACHINE_SSL_CERT, __MACHINE_CERT);
            connConfig = new ConnectionConfig(STS_URL, new X509Certificate[] {
                     CertMgrCert.readCertificateFromStr(sslCert) }, null);
         }
         createSolutionUser(hokSubject, "test solution user for hok token",
               ksHelper.getCertificate(hokSubject), true);
         HolderOfKeyConfig hokConfig =
               new HolderOfKeyConfig(privateKey,
                     certificate, null);
         SecurityTokenServiceConfig stsConfig =
               new SecurityTokenServiceConfig(connConfig,
                     signingCerts,
                     null , hokConfig);
         SecurityTokenService stsClient =
               DefaultSecurityTokenServiceFactory
                    .getSecurityTokenService(stsConfig);
         token = stsClient
               .acquireTokenByCertificate(tokenSpec);

      } catch (InvalidTokenException e) {
         log.error("Invalid token: "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (TokenRequestRejectedException e) {
         log.error("Token request rejected: "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (com.vmware.vim.sso.client.exception.CertificateValidationException e) {
         log.error("Certificate validation exception "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (CMException e) {
         log.error("Component manager exception: "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      }
      return token;
   }

   /**
    * Creates a deletegated token (HokUser) and returns the Samltoken
    * @param token
    * @param delegateTo
    * @param certificate
    * @param privateKey
    * @return
    * @throws SSOException
    */
   public SamlToken getDelegatedToken(SamlToken token, String delegateTo, X509Certificate certificate,
         Key privateKey) throws SSOException{
      SamlToken delegatedToken = null;
      try {
         X509Certificate[] signingCerts =
               getTrustedCertificates();
         CMHelper cmHelper = new CMHelper(hostname);
         String sslCert = cmHelper.getServiceEndpointCert(CMConstants.SSO_STS_SERVICE_ENDPOINT_TYPE);
         ConnectionConfig connConfig =
              new ConnectionConfig(STS_URL,
                      new X509Certificate[] { parseSslCert(sslCert) },
                      null);
         if(isCertChanged) {
            sslCert = vecsCli.getCertString(MACHINE_SSL_CERT, __MACHINE_CERT);
            connConfig = new ConnectionConfig(STS_URL, new X509Certificate[] {
                     CertMgrCert.readCertificateFromStr(sslCert) }, null);
         }
         HolderOfKeyConfig hokConfig =
               new HolderOfKeyConfig(privateKey,
                     certificate, null);
         SecurityTokenServiceConfig stsConfig =
               new SecurityTokenServiceConfig(connConfig,
                     signingCerts,
                     null , hokConfig);
         SecurityTokenService stsClient =
               DefaultSecurityTokenServiceFactory
                    .getSecurityTokenService(stsConfig);
         TokenSpec spec =
               createTokenSpec(SSOConstants.DEFAULT_TOKEN_VALIDITY_SEC, delegateTo);
         delegatedToken = stsClient
               .acquireTokenByToken(token, spec);
      } catch (InvalidTokenException e) {
         log.error("Invalid token: "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (TokenRequestRejectedException e) {
         log.error("Token request rejected: "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (com.vmware.vim.sso.client.exception.CertificateValidationException e) {
         log.error("Certificate validation exception "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (CMException e) {
         log.error("Component manager exception: "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (Exception e) {
         log.error("Caught unknown exception at getBearerToken "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      }
      return delegatedToken;
   }

   /**
    * creates a tokenspec based on the argumetns
    * @param tokenLifetime
    * @param delegateTo
    * @return
    */
   private TokenSpec createTokenSpec(long tokenLifetime, String delegateTo) {
      TokenSpec.Builder builder = new TokenSpec.Builder(tokenLifetime);
      if (delegateTo != null) {
         builder.delegationSpec(new TokenSpec.DelegationSpec(true, delegateTo));
      }
      return builder.createTokenSpec();
   }
   /**
    * converts the string to X509 cert and return
    * @param cert
    * @return
    */
   public static X509Certificate parseSslCert(String cert) {
      InputStream certBytes = null;
      try {
         certBytes =
            new ByteArrayInputStream(
            Base64.decodeBase64(cert.getBytes("UTF-8")));
         CertificateFactory cf = CertificateFactory.getInstance("X.509");
         if (certBytes.available() > 0) {
              return (X509Certificate) cf.generateCertificate(certBytes);
         }
      } catch(Exception e) {
      }
      return null;
      }


   /*
    *  Gets SSO Administrator token
    */
   public SamlToken getAdminBearerToken() throws SSOException
   {
      return getBearerToken(SSOConstants.SSO_ADMIN_USER, SSOConstants.SSO_ADMIN_PASSWORD);
   }


   /**
    * Generates bearer SAML token for a given subject
    * @param ssoServer
    * @param subject
    * @param password
    * @return
    * @throws SSOException
    * @throws URISyntaxException
    */
   public SamlToken getBearerToken(String subject,
      String password) throws SSOException {
      SamlToken token = null;
      try {
         log.info("Requesting a bearer token using crendentials " + subject + " & " + password);
         X509Certificate[] signingCerts =
               getTrustedCertificates();
         TokenSpec.Builder builder =
               new TokenSpec.Builder(SSOConstants.DEFAULT_TOKEN_VALIDITY_SEC);
         builder.delegationSpec(new TokenSpec.DelegationSpec(
               true  , null ));
         TokenSpec tokenSpec = builder.createTokenSpec();
         ConnectionConfig connConfig =
              new ConnectionConfig(STS_URL,
                    new X509Certificate[] { parseSslCert(stsEndpointCert) },
                    null);
         if(isCertChanged) {
            String sslCert = vecsCli.getCertString(MACHINE_SSL_CERT, __MACHINE_CERT);
            connConfig = new ConnectionConfig(STS_URL, new X509Certificate[] {
                     CertMgrCert.readCertificateFromStr(sslCert) }, null);
         }
         HolderOfKeyConfig hokConfig = null;
         SecurityTokenServiceConfig stsConfig =
               new SecurityTokenServiceConfig(connConfig,
                     signingCerts,
                     Executors.newSingleThreadExecutor() , hokConfig);
         SecurityTokenService stsClient =
               DefaultSecurityTokenServiceFactory
                    .getSecurityTokenService(stsConfig);
         token = stsClient
               .acquireToken(subject, new String(password), tokenSpec);
         log.info("Bearer token generated using crendentials " + subject + " & " + password);

      } catch (InvalidTokenException e) {
         log.error("Unable to create bearer token. Invalid sso token "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (TokenRequestRejectedException e) {
         log.error("Unable to create bearer token. token request rejected "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (com.vmware.vim.sso.client.exception.CertificateValidationException e) {
         log.error("Unable to create bearer token. Invalid certificate "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      } catch (Exception e) {
         log.error("Caught unknown exception at getBearerToken "+ e.getMessage());
         throw new SSOException(e.getMessage(), e);
      }
      return token;
   }

   /**
    * Gets the list of trusted certificates from the sso server to use it for
    * secured channel
    *
    * @param ssoServer - hostname/ip of the sso server
    *
    * @return
    *
    * @throws SSOException
    */
   public X509Certificate[] getTrustedCertificates()
         throws SSOException {

      VmomiClientConfiguration.Builder adminClientConfigBuilder = null;
      adminClientConfigBuilder = new VmomiClientConfiguration.Builder(SSO_ADMIN_URI);
      adminClientConfigBuilder
            .setSslConfiguration(new VmomiClientConfiguration.SslConfiguration(
             new AllowAllThumbprintVerifier()));
      VmomiClientConfiguration adminClientConfig =
             adminClientConfigBuilder.createConfig();
      AdminClientFactory adminClientFactory =
             VmomiClientFactory.createAdminClientFactory(adminClientConfig);

      AdminClient adminClient = null;
      X509Certificate[] trustedCerts = null;
      try {
         adminClient = adminClientFactory.createAdminClient();
         trustedCerts =
                  adminClient.getServerConfigurator().getTrustedCertificates()
                       .toArray(new X509Certificate[0]);
      } finally {
         if (adminClient != null) {
            adminClient.dispose();
         }
      }
      return trustedCerts;
   }

   /**
    * Creates a solution user ( with admin permission) that will be used to create HOK Token.
    * method adds authz admin permission to solution user.
    * Note: Need to call SSOHelper().setVCServiceInfo() method or TestInputHandler should be
    * initialized before calling this method.
    * @param solnName
    * @param solnDesc
    * @param cert
    * @param addAdminPermission  add admin permission if it's true.
    * @throws Exception
    *
    */
   public synchronized void createSolutionUser(String solnName,
                                               String solnDesc,
                                               X509Certificate cert,
                                               boolean... addAdminPermission)
      throws SSOException, Exception
   {

      SolutionDetails details = new SolutionDetails(cert, solnDesc);
      AdminClient adminClient = null;
      try {
         adminClient = getAuthenticatedAdminClient();
         SolutionUser solutionUser = adminClient.getPrincipalDiscovery().findSolutionUser(
                  solnName);
         if (solutionUser != null) {
            log.info("Soution user already exist with name: " + solnName
                     + " So, delete it here.");
            deleteLocalPrincipal(adminClient, solnName);
         }
         try {
            PrincipalId principal = adminClient.getPrincipalManagement().createLocalSolutionUser(
                     solnName, details);
            if (principal != null) {
               log.info("Successfully created the solution user with name: "
                        + solnName);

               if (solutionUserSsoGrps != null) {
                  for (String ssoGrp : solutionUserSsoGrps) {
                     ssoGrp = ssoGrp.trim();
                     try {
                        // Assuming verification of *correct* group name is performed by addUserToLocalGroup
                        adminClient.getPrincipalManagement().addUserToLocalGroup(principal, ssoGrp);
                     } catch (Exception e) {
                        log.error(String.format("Failed to add solution user %s to group %s", principal, ssoGrp));
                     }
                     log.info(String.format("Adding solution user %s to group %s", principal, ssoGrp));
                  }
               }

               // Add permission only if required.
               if (addAdminPermission.length > 0
                        && addAdminPermission[0] == true) {
                  List<ServiceInfo> serviceInfoList = new ArrayList<ServiceInfo>();
                  if (vcServiceInfo == null) {
                     log.warn("Make sure that TestInputHandler is initialized/loaded"
                              + " before calling to create solution user. Otherwise set the VC service info by calling SSOHelper.setVCServiceInfo");
                     serviceInfoList = TestInputHandler.getServiceInfo(TestConstants.VC_EXTENSION_KEY);
                     vcServiceInfo = serviceInfoList.get(0);
                  } else {
                     serviceInfoList.add(vcServiceInfo);
                  }
                  AuthorizationServiceHelper authzHelper = new AuthorizationServiceHelper(
                           serviceInfoList, SSO_ADMIN_USER, SSO_ADMIN_PASSWORD,
                           false);
                  authzHelper.addGlobalAuthzAdminPermission(solnName);
                  log.info("Added authz admin permission to Solution user : "
                           + solnName);
               }
            }
         } catch (NoPermissionException e) {
            log.error("Unable to create the principal " + e.getMessage());
            throw new SSOException("Unable to create the principal ", e);
         } catch (InvalidPrincipalException e) {
            log.error("Unable to create the principal " + e.getMessage());
            throw new SSOException("Unable to create the principal ", e);
         } catch (DuplicateSolutionCertificateException e) {
            log.error("Solution certificate in use " + e.getMessage());
            throw new SSOException("Unable to create the principal ", e);
         } catch (NotAuthenticatedException e) {
            log.error("SSO admin client is not authenticated " + e.getMessage());
            throw new SSOException("Unable to create the principal ", e);
         }
      } finally {
         if (adminClient != null) {
            adminClient.dispose();
         }
      }
    }

   /**
    * Delete the local sso person user with the given name.
    *
    * @param username
    *
    * @throws SSOException
    */
   public void deleteLocalUser(String username) throws SSOException {
      AdminClient adminClient = null;
      try {
         adminClient = getAuthenticatedAdminClient();
         deleteLocalPrincipal(adminClient, username);
      } finally {
         if (adminClient != null) {
            adminClient.dispose();
         }
      }
   }

   /**
    * Create a local sso person user with the given name.
    *
    * @param username
    *
    * @throws SSOException
    */
   public void createLocalUser(String username) throws SSOException {
      AdminClient adminClient = null;

      try {
         adminClient = getAuthenticatedAdminClient();
         deleteLocalPrincipal(adminClient, username);
         try {
            PersonDetails.Builder builder = new PersonDetails.Builder();
            builder.setDescription("testuser-description");
            builder.setEmailAddress(TestConstants.EMAIL_TO_VALUE);
            builder.setFirstName("testuser");
            builder.setLastName("testuser");
            PersonDetails personDetails = builder.createPersonDetails();
            adminClient.getPrincipalManagement().createLocalPersonUser(
                username, personDetails,
                SSOConstants.SSO_NEW_USER_VALID_PASSWORD.toCharArray());
         } catch (NoPermissionException e) {
            log.error("No permissiong to create the principal " + e.getMessage());
         } catch (InvalidPrincipalException e) {
            log.error("Unable to create the principal " + e.getMessage());
         } catch (NotAuthenticatedException e) {
            log.error("Unable to create the principal " + e.getMessage());
            throw new SSOException("Unable to delete the principal ", e);
         } catch (PasswordPolicyViolationException e) {
            log.error("Password policy violated: "+ e.getMessage());
            throw new SSOException("Unable to create a local person user", e);
         }
      } finally {
         if (adminClient != null) {
            adminClient.dispose();
         }
      }

   }
   /**
    * Create a local SSO group with the given name.
    *
    * @param groupName
    *
    * @throws SSOException
    */
   public void createLocalGroup(String groupName) throws SSOException {

      AdminClient adminClient = null;

      try {
         adminClient = getAuthenticatedAdminClient();
         deleteLocalPrincipal(adminClient, groupName);
         try {
            GroupDetails groupDetails = new GroupDetails("testgroup-description");
            adminClient.getPrincipalManagement().createLocalGroup(groupName, groupDetails);
         } catch (NoPermissionException e) {
            log.error("No permissiong to create the principal " + e.getMessage());
         } catch (InvalidPrincipalException e) {
            log.error("Unable to create the principal " + e.getMessage());
         } catch (NotAuthenticatedException e) {
            log.error("Unable to create the principal " + e.getMessage());
            throw new SSOException("Unable to delete the principal ", e);
         }
      } finally {
         if (adminClient != null) {
            adminClient.dispose();
         }
      }
   }

   /**
    * Returns the domain name of the SSO local users and groups.
    *
    * @return String SSO system domain name.
    *
    * @throws SSOException
    */
   public String getSSOPrincipalsDomainName() throws SSOException {
      String ssoSystemDomainName = null;
      AdminClient adminClient = null;

      try {
         adminClient = SSOUtil
              .getAdminClientFactory(SSO_ADMIN_URI).createAdminClient();
         try {
            ssoSystemDomainName =
                     adminClient.getDomainManagement().getSystemDomainName();
         } catch (NoPermissionException e) {
            log.error("No permission to get system domain name: " + e.getMessage());
            throw new SSOException("No permission to get system domain name", e);
         }
      } finally {
         if (adminClient != null) {
            adminClient.dispose();
         }
      }
      return ssoSystemDomainName;
   }

   public AdminClient getAuthenticatedAdminClient() throws SSOException {
      AdminClient adminClient = null;
      try {
         SamlToken adminSamlToken = getBearerToken(SSO_ADMIN_USER,
                                                   SSO_ADMIN_PASSWORD);
         AuthenticationData authData = new AuthenticationData(adminSamlToken);
         ClientConfiguration clientConfiguration = new ClientConfiguration(authData);
         adminClient = SSOUtil.getAdminClientFactory(SSO_ADMIN_URI).
                               createAdminClient(clientConfiguration);
      } catch (CertificateValidationException cvee) {
         log.error(cvee.getMessage());
         throw cvee;
      } catch (SSOException ssoe) {
         log.error(ssoe.getMessage());
         throw ssoe;
      }
      return adminClient;
   }

   private void deleteLocalPrincipal(AdminClient adminClient, String principal)
               throws SSOException{
      try {
         adminClient.getPrincipalManagement().deleteLocalPrincipal(principal);
      } catch (NoPermissionException e) {
         log.debug("No permission to delete the principal " + e.getMessage());
         throw new SSOException("No permission to delete the principal", e);
      } catch (InvalidPrincipalException e) {
         log.debug("Invalid principal " + e.getMessage());
      } catch (NotAuthenticatedException e) {
         log.debug("SSO admin client is not authenticated " + e.getMessage());
         throw new SSOException("SSO admin client is not authenticated" , e);
      }
   }

   /**
    * Returns local os domain name
    *
    * @return String SSO local os domain name.
    * @throws SSOException
    * @throws NotAuthenticatedException
    */
   public String getLocalOSDomainName()
      throws NotAuthenticatedException, SSOException
   {
      String ssolocalosDomainName = null;
      AdminClient adminClient = null;
      try {
         adminClient = getAuthenticatedAdminClient();
         try {
            ssolocalosDomainName = adminClient.getDomainManagement().getLocalOSDomainName();
         } catch (NoPermissionException e) {
            log.error("No permission to get system domain name: "
                     + e.getMessage());
            throw new NotAuthenticatedException(
                     "No permission to get system domain name", e);
         }
      } finally {
         if (adminClient != null) {
            adminClient.dispose();
         }
      }
      return ssolocalosDomainName;
   }

   /**
    * Method to get SAML Token Node from the SSO token object. SSO Token object
    * when converted to XML will have saml2:Assertion node containing token
    * Issuer, Signature, Subject, Conditions and AuthnStatement nodes. All of
    * these nodes constitute the SAML token.
    *
    * @return SamlToken Node
    * @throws Exception
    */
    public static Node getSamlTokenNode(SamlToken token)
      throws Exception
   {
      String tokenString = token.toXml();
      DocumentBuilderFactory docBuilder = DocumentBuilderFactory.newInstance();
      docBuilder.setCoalescing(true);
      docBuilder.setNamespaceAware(true);
      docBuilder.setIgnoringElementContentWhitespace(true);
      docBuilder.setValidating(false);
      Document xmlDoc1 = docBuilder.newDocumentBuilder().parse(
               new InputSource(new ByteArrayInputStream(
                        tokenString.getBytes("utf-8"))));
      return xmlDoc1.getFirstChild();
   }

   /**
    * Set VC service info. Needed on create solution user with admin privilege.
    * Solution user no longer will have admin privilege by default.Need to add
    * it explicitly. PS: Set it on class level as VC service info can be used in
    * other methods too.
    *
    * @param serviceInfo
    */
   public void setVCServiceInfo(ServiceInfo serviceInfo)
   {
      vcServiceInfo = serviceInfo;
   }

   public void setSolutionUserSsoGrps(String[] solutionUserSsoGrps) {
      this.solutionUserSsoGrps = solutionUserSsoGrps;
   }

   /**
    * Method to update the password for currently logged in user.
    * @param adminClient - authenticated AdminClient instance
    * @param newPassword - the new password to apply
    * @throws Exception
    *
    */
   public void updateSelfPassword(AdminClient adminClient, String newPassword)
      throws SSOException, Exception
   {
      PrincipalSelfManagement principalSelfMgmt =
               adminClient.getPrincipalSelfManagement();
      try {
         principalSelfMgmt.resetLocalPersonUserPassword(newPassword.toCharArray());
      } catch (InvalidPrincipalException e) {
         log.error("Unable to update the password - Invalid Prinicipal "
                     + e.getMessage());
         throw new SSOException("Invalid Prinicipal Exception ", e);
      } catch (PasswordPolicyViolationException e) {
         log.error("Unable to update the password - Password Policy Violation "
                     + e.getMessage());
         throw new SSOException("Password Policy Violation ", e);
      } catch (NotAuthenticatedException e) {
         log.error("Unable to update the password - Not Authenticated "
                     + e.getMessage());
         throw new SSOException(" Not Authenticated ", e);
      }
   }

   /**
    * Method to get an authenticated admin client instance with updated password.
    * @param user - username for which password has changed.
    * @param password - the changed password for the user
    * @throws Exception
    */
   public AdminClient getAdminClientOnPasswordChange(String user,
                                                     String password)
                                                    throws SSOException {
      AdminClient adminClient = null;
      try {
         SamlToken adminSamlToken = getBearerToken(user, password);
         AuthenticationData authData = new AuthenticationData(adminSamlToken);
         ClientConfiguration clientConfiguration = new ClientConfiguration(authData);
         adminClient = SSOUtil.getAdminClientFactory(SSO_ADMIN_URI).
                               createAdminClient(clientConfiguration);
      } catch (CertificateValidationException cvee) {
         log.error(cvee.getMessage());
         throw cvee;
      } catch (SSOException ssoe) {
         log.error(ssoe.getMessage());
         throw ssoe;
      }
      return adminClient;
   }

   /**
    * Returns the bare username and the domain name strings, parsing the
    * username passed.
    *
    * @param userName String username.
    *
    * @return String[] of length 2, index 0 contains the bare username and
    *         index[1] contains the domain name.
    */
   public static String[] splitUserName(String userName) {
      String bareUsername = userName;
      String domainName  = "";

      if (userName != null) {
         /*
          * Find the index of the first '@' character.
          */
         int index = userName.indexOf('@');
         bareUsername = userName;
         if (index != -1) {
            bareUsername = userName.substring(0, index);
            if (index+1<=userName.length()) {
               domainName = userName.substring(index+1, userName.length());
            }
         } else {
            /*
             * Find the index of the first '\' character.
             */
            index = userName.indexOf('\\');
            if (index != -1) {
               domainName = userName.substring(0, index);
               if (index+1<=userName.length()) {
                  bareUsername = userName.substring(index+1, userName.length());
               }
            }
         }
      }

      return new String[]{bareUsername,  domainName};
   }
}
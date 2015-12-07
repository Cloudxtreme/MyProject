/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostConfigChangeOperation;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * PR# 476092 : test case<br>
 * 1. Create DVS with two uplink ports and add host with free pnic to one of the
 * uplink ports via VC<br>
 * 2. Remove pnic from DVS via VC <br>
 * 3. Add same pnic to same uplink port via HOSTD <br>
 * 4. Add another free pnic to free uplinkport via VC
 */
public class Pos050 extends TestBase
{
   private SessionManager sessionManager = null;
   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Map allHosts = null;
   private ManagedObjectReference hostMor = null;
   private Folder iFolder = null;
   private NetworkSystem ins = null;
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private ManagedObjectReference nsMor = null;
   private ManagedObjectReference dvsMor = null;
   private String esxHostName = null;
   private ConnectAnchor hostConnectAnchor = null;
   private String uplinkPortKey = null;
   private String[] freePnics = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription("PR# 476092  : test case \n"
               + " 1. Create DVS with two uplink ports and add host with free pnic to one of the uplink ports via VC \n"
               + " 2. Remove pnic from DVS via VC \n"
               + " 3. Add same pnic to same uplink port via HOSTD\n"
               + " 4. Add another free pnic to free uplinkport via VC\n");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      sessionManager = new SessionManager(connectAnchor);
      boolean status = false;
      Iterator it = null;
      String[] pnicIds = null;
      log.info("Test setup Begin:");
     
         iFolder = new Folder(connectAnchor);
         iDistributedVirtualSwitch = new DistributedVirtualSwitch(connectAnchor);
         ihs = new HostSystem(connectAnchor);
         ins = new NetworkSystem(connectAnchor);
         allHosts = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
         if ((allHosts != null)) {
            it = allHosts.keySet().iterator();
            hostMor = (ManagedObjectReference) it.next();
            esxHostName = ihs.getHostName(hostMor);
            log.info("Found a host with free pnics in the inventory");
            nsMor = ins.getNetworkSystem(hostMor);
            if (nsMor != null) {
               pnicIds = ins.getPNicIds(hostMor);
               if (pnicIds != null) {
                  status = true;
               } else {
                  log.error("There are no free pnics on the host");
               }
            } else {
               log.error("The network system MOR is null");
            }
         } else {
            log.error("Valid Host MOR not found");
            status = false;
         }
     

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "PR# 476092  : test case \n"
               + " 1. Create DVS with two uplink ports and add host with free pnic to one of the uplink ports via VC \n"
               + " 2. Remove pnic from DVS via VC \n"
               + " 3. Add same pnic to same uplink port via HOSTD\n"
               + " 4. Add another free pnic to free uplinkport via VC\n")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      HostProxySwitchConfig originalHostProxySwitchConfig = null;
      HostProxySwitchConfig updatedHostProxySwitchConfig = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      List<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecList = new ArrayList<DistributedVirtualSwitchHostMemberPnicSpec>();
      HostNetworkConfig updatedNetworkConfig = null;
     
         freePnics = ins.getPNicIds(hostMor);
         if (freePnics != null && freePnics.length >= 2) {
            dvsMor = migrateNetworkToDVS(hostMor, freePnics[0]);
            assertNotNull(dvsMor, "Successfully created the DVSwitch",
                     "Null returned for Distributed Virtual Switch MOR");
            DistributedVirtualSwitchPortCriteria portCriteria = iDistributedVirtualSwitch.getPortCriteria(
                     true, null, null, null, null, true);
            List<DistributedVirtualPort> uplinkDVports = iDistributedVirtualSwitch.fetchPorts(
                     dvsMor, portCriteria);
            assertTrue((uplinkDVports != null && uplinkDVports.size() > 0),
                     "DistributedVirtualPort list is null");
            if (uplinkDVports.size() == 1) {
               for (DistributedVirtualPort dvport : uplinkDVports) {
                  uplinkPortKey = dvport.getKey();
               }
            }
            originalHostProxySwitchConfig = iDistributedVirtualSwitch.getDVSVswitchProxyOnHost(
                     dvsMor, hostMor);
            updatedHostProxySwitchConfig = (HostProxySwitchConfig) TestUtil.deepCopyObject(originalHostProxySwitchConfig);
            updatedHostProxySwitchConfig.setChangeOperation(HostConfigChangeOperation.EDIT.value());
            if (updatedHostProxySwitchConfig.getSpec() != null
                     && updatedHostProxySwitchConfig.getSpec().getBacking() != null
                     && updatedHostProxySwitchConfig.getSpec().getBacking() instanceof DistributedVirtualSwitchHostMemberPnicBacking) {
               pnicBacking = (DistributedVirtualSwitchHostMemberPnicBacking) updatedHostProxySwitchConfig.getSpec().getBacking();
               if (uplinkPortKey != null) {
                  pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
               } else {
                  throw new Exception(
                           DVSTestConstants.ERROR_MESSAGE_NO_FREE_UPLINK);
               }
               pnicBacking.getPnicSpec().clear();
               pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(pnicSpecList.toArray(new DistributedVirtualSwitchHostMemberPnicSpec[pnicSpecList.size()])));
               updatedHostProxySwitchConfig.getSpec().setBacking(pnicBacking);
               updatedNetworkConfig = new HostNetworkConfig();
               if (updatedHostProxySwitchConfig != null) {
                  updatedNetworkConfig.getProxySwitch().clear();
                  updatedNetworkConfig.getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { updatedHostProxySwitchConfig }));
                  status = ins.updateNetworkConfig(nsMor, updatedNetworkConfig,
                           TestConstants.CHANGEMODE_MODIFY);
                  status &= performOperationsOnhostd();
                  status &= ins.refresh(nsMor);
                  /*
                   * Add another free pnic to DVS via VC
                   */
                  originalHostProxySwitchConfig = iDistributedVirtualSwitch.getDVSVswitchProxyOnHost(
                           dvsMor, hostMor);
                  updatedHostProxySwitchConfig = (HostProxySwitchConfig) TestUtil.deepCopyObject(originalHostProxySwitchConfig);
                  updatedHostProxySwitchConfig.setChangeOperation(HostConfigChangeOperation.EDIT.value());
                  if (updatedHostProxySwitchConfig.getSpec() != null
                           && updatedHostProxySwitchConfig.getSpec().getBacking() != null
                           && updatedHostProxySwitchConfig.getSpec().getBacking() instanceof DistributedVirtualSwitchHostMemberPnicBacking) {
                     pnicBacking = (DistributedVirtualSwitchHostMemberPnicBacking) updatedHostProxySwitchConfig.getSpec().getBacking();
                     if (uplinkPortKey != null) {
                        pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                        pnicSpec.setPnicDevice(freePnics[0]);
                        pnicSpec.setUplinkPortKey(uplinkPortKey);
                        pnicSpecList.add(pnicSpec);
                        pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                        String freePort = iDistributedVirtualSwitch.getFreeUplinkPortKey(
                                 dvsMor, hostMor, null);
                        pnicSpec.setPnicDevice(freePnics[1]);
                        pnicSpec.setUplinkPortKey(freePort);
                        pnicSpecList.add(pnicSpec);
                     } else {
                        throw new Exception(
                                 DVSTestConstants.ERROR_MESSAGE_NO_FREE_UPLINK);
                     }
                     pnicBacking.getPnicSpec().clear();
                     pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(pnicSpecList.toArray(new DistributedVirtualSwitchHostMemberPnicSpec[pnicSpecList.size()])));
                     updatedHostProxySwitchConfig.getSpec().setBacking(
                              pnicBacking);
                     updatedNetworkConfig = new HostNetworkConfig();
                     if (updatedHostProxySwitchConfig != null) {
                        updatedNetworkConfig.getProxySwitch().clear();
                        updatedNetworkConfig.getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { updatedHostProxySwitchConfig }));
                        status &= ins.updateNetworkConfig(nsMor,
                                 updatedNetworkConfig,
                                 TestConstants.CHANGEMODE_MODIFY);
                     }
                  }
               }
            }
         } else {
            log.error("Failed to get required(2) no of freePnics");
         }
     
      assertTrue(status, "Test Failed");
   }

   private boolean performOperationsOnhostd()
      throws Exception
   {
      boolean status = true;
      NetworkSystem hostIns = null;
      HostSystem hostIhs = null;
      HostProxySwitchConfig originalHostProxySwitchConfig = null;
      HostProxySwitchConfig updatedHostProxySwitchConfig = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      List<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecList = new ArrayList<DistributedVirtualSwitchHostMemberPnicSpec>();
      HostNetworkConfig updatedNetworkConfig = null;
      ManagedObjectReference hostNWMor = null;
      ManagedObjectReference host = null;
      hostConnectAnchor = new ConnectAnchor(esxHostName,
               data.getInt(TestConstants.TESTINPUT_PORT));
      if (hostConnectAnchor != null) {
         log.info("Successfully obtained the connect"
                  + " anchor to the host");
         UserSession newLoginSession = null;
         AuthorizationManager newAuthentication = null;
         ManagedObjectReference newAuthenticationMor = null;
         newAuthentication = new AuthorizationManager(hostConnectAnchor);
         sessionManager = new SessionManager(hostConnectAnchor);
         newAuthenticationMor = sessionManager.getSessionManager();
         if (newAuthenticationMor != null) {
            newLoginSession = sessionManager.login(newAuthenticationMor,
                     TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD,
                     null);
            if (newLoginSession != null) {
               hostIns = new NetworkSystem(hostConnectAnchor);
               hostIhs = new HostSystem(hostConnectAnchor);
               host = hostIhs.getHost(esxHostName);
               hostNWMor = hostIns.getNetworkSystem(host);
               originalHostProxySwitchConfig = iDistributedVirtualSwitch.getDVSVswitchProxyOnHost(
                        dvsMor, hostMor);
               updatedHostProxySwitchConfig = (HostProxySwitchConfig) TestUtil.deepCopyObject(originalHostProxySwitchConfig);
               updatedHostProxySwitchConfig.setChangeOperation(HostConfigChangeOperation.EDIT.value());
               if (updatedHostProxySwitchConfig.getSpec() != null
                        && updatedHostProxySwitchConfig.getSpec().getBacking() != null
                        && updatedHostProxySwitchConfig.getSpec().getBacking() instanceof DistributedVirtualSwitchHostMemberPnicBacking) {
                  pnicBacking = (DistributedVirtualSwitchHostMemberPnicBacking) updatedHostProxySwitchConfig.getSpec().getBacking();
                  if (uplinkPortKey != null) {
                     pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     pnicSpec.setPnicDevice(freePnics[0]);
                     pnicSpec.setUplinkPortKey(uplinkPortKey);
                     pnicSpecList.add(pnicSpec);
                  } else {
                     throw new Exception(
                              DVSTestConstants.ERROR_MESSAGE_NO_FREE_UPLINK);
                  }
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(pnicSpecList.toArray(new DistributedVirtualSwitchHostMemberPnicSpec[pnicSpecList.size()])));
                  updatedHostProxySwitchConfig.getSpec().setBacking(pnicBacking);
                  updatedNetworkConfig = new HostNetworkConfig();
                  if (updatedHostProxySwitchConfig != null) {
                     updatedNetworkConfig.getProxySwitch().clear();
                     updatedNetworkConfig.getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { updatedHostProxySwitchConfig }));
                     status = hostIns.updateNetworkConfig(hostNWMor,
                              updatedNetworkConfig,
                              TestConstants.CHANGEMODE_MODIFY);
                  }
               }
            } else {
               log.error("Can not login into the host " + esxHostName);
            }
         } else {
            log.error("The session manager object is null");
         }
      } else {
         status = false;
         log.error("Can not obtain the connect " + "anchor to the host");
      }
      return status;
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
     
         if (dvsMor != null) {
            status &= iDistributedVirtualSwitch.destroy(dvsMor);
         }
     

      assertTrue(status, "Cleanup failed");
      return status;
   }

   /*
    * CreateDistributedVirtualSwitch with HostMemberPnicSpec
    */
   private ManagedObjectReference migrateNetworkToDVS(ManagedObjectReference hostMor,
                                                      String pnic)
      throws Exception
   {
      ManagedObjectReference nwSystemMor = null;
      ManagedObjectReference dvsMor = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      nwSystemMor = ins.getNetworkSystem(hostMor);
      hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
      hostMember.setHost(hostMor);
      pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
      pnicSpec.setPnicDevice(pnic);
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
      hostMember.setBacking(pnicBacking);
      DVSConfigSpec dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(getTestId() + "-dvs");
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
      String[] uplinkPortNames = new String[] { "Uplink1", "Uplink2" };
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      uplinkPolicyInst.getUplinkPortName().clear();
      uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
      dvsConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(iFolder.getDataCenter()), dvsConfigSpec);
      if (dvsMor != null
               && ins.refresh(nwSystemMor)
               && iDistributedVirtualSwitch.validateDVSConfigSpec(dvsMor,
                        dvsConfigSpec, null)) {
         log.info("Successfully created the distributed "
                  + "virtual switch");
      } else {
         log.error("Unable to create DistributedVirtualSwitch");
      }
      return dvsMor;
   }
}

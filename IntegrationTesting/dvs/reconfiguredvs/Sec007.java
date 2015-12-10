/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by passing a valid pnic proxy selection with
 * the pnic spec(s) containing a valid pnic key by users having not
 * DVSwitch.Modify and network.assign privilege
 */
public class Sec007 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Vector allHosts = null;
   private ManagedObjectReference hostMor = null;
   private NetworkSystem iNetworkSystem = null;
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;
   private AuthorizationManager authentication = null;
   private int roleId;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription("   Reconfigure an existing DVSwitch by "
               + "  passing a valid pnic proxy  selection with "
               + "the pnic spec(s) containing a valid pnic key "
               + "by users   having DVSwitch.Modify and network.assign"
               + "  privile");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            iFolder = new Folder(super.getConnectAnchor());
            networkFolderMor = iFolder.getNetworkFolder(dcMor);
            if (networkFolderMor != null) {
               ihs = new HostSystem(connectAnchor);
               iNetworkSystem = new NetworkSystem(connectAnchor);
               iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                        connectAnchor);
               allHosts = ihs.getAllHost();

               if (allHosts != null) {
                  hostMor = (ManagedObjectReference) allHosts.get(0);
               } else {
                  log.error("Valid Host MOR not found");
               }
               configSpec = new DVSConfigSpec();
               configSpec.setName(this.getClass().getName());
               dvsMOR = iFolder.createDistributedVirtualSwitch(
                        networkFolderMor, configSpec);
               if (dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");

                  deltaConfigSpec = new DVSConfigSpec();
                  DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
                  DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
                  DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
                  String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
                           + getTestId();
                  DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
                  String validConfigVersion = iDistributedVirtualSwitch.getConfig(
                           dvsMOR).getConfigVersion();
                  String[] uplinkPortNames = new String[32];
                  for (int i = 0; i < 32; i++) {
                     uplinkPortNames[i] = "Uplink" + i;
                  }
                  uplinkPolicyInst.getUplinkPortName().clear();
                  uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
                  deltaConfigSpec.setConfigVersion(validConfigVersion);
                  deltaConfigSpec.setName(dvsName);
                  deltaConfigSpec.setMaxPorts(uplinkPortNames.length);
                  deltaConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
                  String[] physicalNics = iNetworkSystem.getPNicIds(hostMor);
                  if (physicalNics != null) {
                     pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     pnicSpec.setPnicDevice(physicalNics[0]);
                     pnicSpec.setUplinkPortKey(null);
                  }

                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  hostConfigSpecElement.setHost(hostMor);
                  log.info(ihs.getHostName(hostMor));
                  hostConfigSpecElement.setMaxProxySwitchPorts(new Integer(
                           uplinkPortNames.length));
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  deltaConfigSpec.getHost().clear();
                  deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                  permissionSpecMap.put(
                           DVSTestConstants.PRIVILEGE_DVSWITCH_HOSTOP,
                           iDistributedVirtualSwitch.getDataCenter());
                  permissionSpecMap.put(
                           DVSTestConstants.PRIVILEGE_NETWORK_ASSIGN,
                           ihs.getParentNode(hostMor));
                  if (addRolesAndSetPermissions(permissionSpecMap)
                           && performSecurityTestsSetup(connectAnchor)) {
                     status = true;
                  }
               } else {
                  log.error("Cannot create the distributed virtual "
                           + "switch with the config spec passed");
               }
            } else {
               log.error("Failed to create the network folder");
            }
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
   @Test(description = "   Reconfigure an existing DVSwitch by "
               + "  passing a valid pnic proxy  selection with "
               + "the pnic spec(s) containing a valid pnic key "
               + "by users   having DVSwitch.Modify and network.assign"
               + "  privile")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         status = !iDistributedVirtualSwitch.reconfigure(dvsMOR,
                  deltaConfigSpec);
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(hostMor);
         expectedMethodFault.setPrivilegeId(PrivilegeConstants.HOST_CONFIG_NETWORK);
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
      }
      assertTrue(status, "Test Failed");
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
      try {
         status &= performSecurityTestsCleanup(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         status &= super.testCleanUp();
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         status &= SessionManager.logout(connectAnchor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
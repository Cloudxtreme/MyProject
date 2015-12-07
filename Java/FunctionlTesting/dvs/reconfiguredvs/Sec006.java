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
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by passing a valid pnic proxy selection with
 * the pnic spec(s) containing a valid pnic key by users having DVSwitch.Modify
 * and network.assign privilege
 */
public class Sec006 extends CreateDVSTestBase
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

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
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
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.ihs = new HostSystem(connectAnchor);
               this.iNetworkSystem = new NetworkSystem(connectAnchor);
               this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                        connectAnchor);
               allHosts = this.ihs.getAllHost();

               if (allHosts != null) {
                  this.hostMor = (ManagedObjectReference) allHosts.get(0);
               } else {
                  log.error("Valid Host MOR not found");
               }
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  permissionSpecMap.put(
                           DVSTestConstants.PRIVILEGE_DVSWITCH_MODIFY,
                           this.iDistributedVirtualSwitch.getDataCenter());
                  permissionSpecMap.put(
                           DVSTestConstants.PRIVILEGE_NETWORK_ASSIGN,
                           this.dvsMOR);
                  permissionSpecMap.put(
                           DVSTestConstants.PRIVILEGE_HOST_CONFIG_NETWORK,
                           this.ihs.getParentNode(this.hostMor));
                  permissionSpecMap.put(
                           DVSTestConstants.PRIVILEGE_DVSWITCH_HOSTOP,
                           this.ihs.getParentNode(this.hostMor));
                  if (addRolesAndSetPermissions(permissionSpecMap)
                           && performSecurityTestsSetup(connectAnchor)) {
                     status = true;
                  }

                  this.deltaConfigSpec = new DVSConfigSpec();
                  DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
                  DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
                  DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
                  String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
                           + this.getTestId();
                  DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
                  String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                           dvsMOR).getConfigVersion();
                  String[] uplinkPortNames = new String[32];
                  for (int i = 0; i < 32; i++)
                     uplinkPortNames[i] = "Uplink" + i;
                  uplinkPolicyInst.getUplinkPortName().clear();
                  uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
                  this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                  this.deltaConfigSpec.setName(dvsName);
                  this.deltaConfigSpec.setMaxPorts(uplinkPortNames.length);
                  this.deltaConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
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
                  hostConfigSpecElement.setHost(this.hostMor);
                  log.info(ihs.getHostName(hostMor));
                  hostConfigSpecElement.setMaxProxySwitchPorts(new Integer(
                           uplinkPortNames.length));
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  this.deltaConfigSpec.getHost().clear();
                  this.deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                  status = true;
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
     
         status = this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
         assertTrue(status, "Test Failed");
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
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
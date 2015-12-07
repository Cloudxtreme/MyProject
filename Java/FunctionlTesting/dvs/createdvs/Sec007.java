/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

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
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Create a DVSwitch inside a valid folder by passing a valid pnic proxy
 * selection with the pnic spec(s) containing a valid pnic key by an user having
 * DVSwitch.create and network.assign privilege
 */
public class Sec007 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor = null;
   private NetworkSystem iNetworkSystem = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder by"
               + " passing a valid pnic proxy  selection with the pnic spec(s)"
               + " containing a valid pnic key by"
               + "   an user having DVSwitch.create and network.assign privilege");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      String[] uplinkPortNames = new String[32];
      String dvsName = this.getTestId();
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.ihs = new HostSystem(connectAnchor);
            this.iNetworkSystem = new NetworkSystem(connectAnchor);
            allHosts = this.ihs.getAllHost();

            if (allHosts != null) {
               this.hostMor = (ManagedObjectReference) allHosts.get(0);
            } else {
               log.error("Valid Host MOR not found");
            }

            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(dvsName);
               for (int i = 0; i < 32; i++)
                  uplinkPortNames[i] = "Uplink" + i;
               uplinkPolicyInst.getUplinkPortName().clear();
               uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
               this.configSpec.setMaxPorts(2 * uplinkPortNames.length);
               this.configSpec.setNumStandalonePorts(uplinkPortNames.length);
               this.configSpec.setUplinkPortPolicy(uplinkPolicyInst);
               String[] physicalNics = iNetworkSystem.getPNicIds(hostMor);
               if (physicalNics != null) {
                  pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                  pnicSpec.setPnicDevice(physicalNics[0]);
                  pnicSpec.setUplinkPortKey(null);
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  hostConfigSpecElement.setHost(this.hostMor);
                  hostConfigSpecElement.setMaxProxySwitchPorts(new Integer(
                           uplinkPortNames.length));
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  this.configSpec.getHost().clear();
                  this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));

                  permissionSpecMap.put(
                           DVSTestConstants.DVSWITCH_CREATE_PRIVILEGE,
                           this.iDistributedVirtualSwitch.getDataCenter());
                  permissionSpecMap.put(
                           DVSTestConstants.PRIVILEGE_NETWORK_ASSIGN,
                           this.ihs.getParentNode(this.hostMor));
                  if (addRolesAndSetPermissions(permissionSpecMap)
                           && performSecurityTestsSetup(connectAnchor)) {
                     status = true;
                  }
               } else {
                  log.error("No free pnics found on the host.");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         } else {
            log.error("Test setup failed.");
         }
     

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create a DVSwitch inside a valid folder by"
               + " passing a valid pnic proxy  selection with the pnic spec(s)"
               + " containing a valid pnic key by"
               + "   an user having DVSwitch.create and network.assign privilege")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.configSpec != null) {
            this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                     this.networkFolderMor, this.configSpec);
            if (this.dvsMOR != null) {
               log.info("Successfully created the DVSwitch");
               if (iDistributedVirtualSwitch.validateDVSConfigSpec(this.dvsMOR,
                        this.configSpec, null)) {
                  status = true;
               } else {
                  log.info("The config spec of the Distributed Virtual "
                           + "Switch is not created as per specifications");
               }
            } else {
               log.error("Cannot create the distributed "
                        + "virtual switch with the config spec passed");
            }
         }
     
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
      } finally {
         status &= SessionManager.logout(connectAnchor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
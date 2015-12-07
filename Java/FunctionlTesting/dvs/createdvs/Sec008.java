/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_CREATE;

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
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Create a DVSwitch inside a valid folder by passing a valid pnic proxy
 * selection with the pnic spec(s) containing a valid pnic key by an user not
 * having DVSwitch.create and network.assign privilege
 */
public class Sec008 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor = null;
   private NetworkSystem iNetworkSystem = null;
   private String testUser = GENERIC_USER;
   private String privilege = PrivilegeConstants.DVSWITCH_CREATE;
   private AuthorizationHelper authHelper;;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super
               .setTestDescription("Create a DVSwitch inside a valid folder by"
                        + " passing a valid pnic proxy  selection with the pnic spec(s)"
                        + " containing a valid pnic key by"
                        + "   an user not having DVSwitch.create and network.assign privilege");
   }

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst =
               new DVSNameArrayUplinkPortPolicy();
      String[] uplinkPortNames = new String[32];
      String dvsName = this.getTestId();
      log.info("Test setup Begin:");

      if (super.testSetUp()) {
         this.ihs = new HostSystem(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         allHosts = this.ihs.getAllHost();

         if (allHosts != null) {
            this.hostMor = allHosts.get(0);

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
               pnicBacking =
                        new DistributedVirtualSwitchHostMemberPnicBacking();
               hostConfigSpecElement =
                        new DistributedVirtualSwitchHostMemberConfigSpec();
               pnicBacking.getPnicSpec().clear();
               pnicBacking.getPnicSpec()
                        .addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
               hostConfigSpecElement.setBacking(pnicBacking);
               hostConfigSpecElement.setHost(this.hostMor);
               hostConfigSpecElement.setMaxProxySwitchPorts(new Integer(
                        uplinkPortNames.length));
               hostConfigSpecElement
                        .setOperation(TestConstants.CONFIG_SPEC_ADD);
               this.configSpec.getHost().clear();
               this.configSpec.getHost()
                        .addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
               authHelper =
                        new AuthorizationHelper(
                                 connectAnchor,
                                 getTestId(),
                                 data
                                          .getString(TestConstants.TESTINPUT_USERNAME),
                                 data
                                          .getString(TestConstants.TESTINPUT_PASSWORD));
               authHelper.setPermissions(this.ihs.getParentNode(this.hostMor),
                        PrivilegeConstants.NETWORK_ASSIGN, testUser, false);
               status = authHelper.performSecurityTestsSetup(testUser);

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
   @Override
   @Test(description = "Create a DVSwitch inside a valid folder by  passing " +
   		"a valid pnic proxy  selection with the pnic spec(s) containing a " +
   		"valid pnic key by a user not having DVSwitch.create and " +
   		"network.assign privilege." )
   public void test()
      throws Exception
   {
      try {
         this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
            this.networkFolderMor, this.configSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dcMor);
         expectedMethodFault.setPrivilegeId(privilege);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (authHelper != null) {
            status &= authHelper.performSecurityTestsCleanup();
         }
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
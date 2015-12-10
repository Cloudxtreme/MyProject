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

import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NotFound;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.HostSystem;

import dvs.CreateDVSTestBase;

/**
 * Create a DVS inside a valid folder with the following parameters set in the
 * config spec. - rootFolder set to a valid folder object -
 * DVSConfigSpec.configVersion is set to an empty string -
 * DistributedVirtualSwitchHostMemberConfigSpec.operation set to an invalid
 * operation edit - DistributedVirtualSwitchHostMemberConfigSpec.host set to a
 * valid host Mor - DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a
 * valid pnic proxy selection
 */
public class Neg011 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Vector allHosts = null;
   private ManagedObjectReference hostMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVS inside a valid folder with the "
               + "following parameters set in the config spec:"
               + "- rootFolder set to a valid folder object\n"
               + "- DVSConfigSpec.configVersion is set to an empty string\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to edit\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host "
               + "  Mor\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic "
               + " proxy selection\n");
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
      DistributedVirtualSwitchHostMemberConfigSpec dvsHostMemberConfigSpecInst = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.ihs = new HostSystem(connectAnchor);
            allHosts = this.ihs.getAllHost();

            if (allHosts != null) {
               this.hostMor = (ManagedObjectReference) allHosts.get(0);
            } else {
               log.error("Valid Host MOR not found");
            }

            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.configSpec = new VMwareDVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(this.getTestId());
               dvsHostMemberConfigSpecInst = new DistributedVirtualSwitchHostMemberConfigSpec();
               pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
               pnicBacking.getPnicSpec().clear();
               pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
               dvsHostMemberConfigSpecInst.setBacking(pnicBacking);
               dvsHostMemberConfigSpecInst.setOperation(TestConstants.CONFIG_SPEC_EDIT);
               dvsHostMemberConfigSpecInst.setHost(this.hostMor);
               this.configSpec.getHost().clear();
               this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { dvsHostMemberConfigSpecInst }));
               status = true;
            } else {
               log.error("Network folder is null.Setup fail.");
            }
         } else {
            log.error("Failed to login");
         }
     

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create a DVS inside a valid folder with the "
               + "following parameters set in the config spec:"
               + "- rootFolder set to a valid folder object\n"
               + "- DVSConfigSpec.configVersion is set to an empty string\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to edit\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host "
               + "  Mor\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic "
               + " proxy selection\n")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                  this.networkFolderMor, this.configSpec);
         log.error("The API did not throw Exception");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         MethodFault expectedMethodFault = new NotFound();
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
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
     
         if (this.dvsMOR == null && this.networkFolderMor != null) {
            this.dvsMOR = this.iFolder.getDistributedVirtualSwitch(
                     this.networkFolderMor, this.getTestId());
         }
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
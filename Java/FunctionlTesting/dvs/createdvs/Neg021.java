/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.VirtualMachine;

import dvs.CreateDVSTestBase;

/**
 * Create a DVS inside a valid folder with the following parameters set in the
 * config spec. - DVSConfigSpec.configVersion is set to an empty string -
 * DistributedVirtualSwitchHostMemberConfigSpec.operation set to add -
 * DistributedVirtualSwitchHostMemberConfigSpec.host set to an invalid host Mor
 * - DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy
 * selection
 */
public class Neg021 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private VirtualMachine ivm = null;
   private ManagedObjectReference vmFolderMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVS inside a valid folder with the "
               + "following parameters set in the config spec:"
               + "- DVSConfigSpec.configVersion is set to an empty string\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to add\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to an invalid host Mor\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection\n");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.ivm = new VirtualMachine(connectAnchor);
            this.vmFolderMor = this.ivm.getVMFolder();
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.configSpec = new VMwareDVSConfigSpec();
               hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
               pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
               pnicBacking.getPnicSpec().clear();
               pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
               hostConfigSpecElement.setBacking(pnicBacking);
               hostConfigSpecElement.setHost(this.vmFolderMor);
               hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
               this.configSpec.getHost().clear();
               this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
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
               + "- DVSConfigSpec.configVersion is set to an empty string\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to add\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to an invalid host Mor\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection\n")
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
         InvalidArgument expectedMethodFault = new InvalidArgument();
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
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
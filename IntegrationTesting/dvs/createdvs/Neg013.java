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
 * config spec. - ManagedObjectReference set to a valid folder object -
 * DVSConfigSpec.configVersion is set to an empty string - DVSConfigSpec.name is
 * set to "Create DVS-Neg013" -
 * DistributedVirtualSwitchHostMemberConfigSpec.operation set to 'remove'
 */
public class Neg013 extends CreateDVSTestBase
{
   private HostSystem ihs = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVS inside a valid folder with the "
               + "following parameters set in the config spec:"
               + " - ManagedObjectReference set to a valid folder object,\n"
               + " - DVSConfigSpec.configVersion is set to an empty string,\n"
               + " - DVSConfigSpec.name is set to 'Create DVS-Neg013',\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.operation set to "
               + "'remove'.");
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
      DistributedVirtualSwitchHostMemberConfigSpec dvsHostMemberConfigSpecInst = null;
      boolean status = false;
      Vector<ManagedObjectReference> allHosts = null;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.ihs = new HostSystem(connectAnchor);
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               allHosts = this.ihs.getAllHost();
               if (allHosts != null && allHosts.size() > 0
                        && allHosts.get(0) != null) {
                  this.configSpec = new VMwareDVSConfigSpec();
                  this.configSpec.setConfigVersion("");
                  this.configSpec.setName(this.getTestId());
                  dvsHostMemberConfigSpecInst = new DistributedVirtualSwitchHostMemberConfigSpec();
                  dvsHostMemberConfigSpecInst.setHost(allHosts.get(0));
                  dvsHostMemberConfigSpecInst.setOperation(TestConstants.CONFIG_SPEC_REMOVE);
                  this.configSpec.getHost().clear();
                  this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { dvsHostMemberConfigSpecInst }));
                  status = true;
               } else {
                  log.error("Can not find a valid host in the setup");
               }
            } else {
               log.error("Failed to create network folder.");
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
               + " - ManagedObjectReference set to a valid folder object,\n"
               + " - DVSConfigSpec.configVersion is set to an empty string,\n"
               + " - DVSConfigSpec.name is set to 'Create DVS-Neg013',\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.operation set to "
               + "'remove'.")
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
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
 * Create a DVS with parameters set as follows: - ManagedObjectReference set to
 * a valid folder object - DVSConfigSpec.configVersion is set to an empty
 * string. - DVSConfigSpec.name is set to "Create DVS-Neg010" -
 * DVSConfigSpec.host.operation set to "Edit".
 */
public class Neg010 extends CreateDVSTestBase
{

   private HostSystem ihs = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVS with parameters set as "
               + "follows:\n"
               + " - ManagedObjectReference set to a valid folder object, \n"
               + " - DVSConfigSpec.configVersion is set to an empty string, \n"
               + " - DVSConfigSpec.name is set to 'Create DVS-Neg010', \n"
               + " - DVSConfigSpec.host.operation set to 'Edit'.");
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
      Vector<ManagedObjectReference> allHosts = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.ihs = new HostSystem(connectAnchor);
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               allHosts = this.ihs.getAllHost();
               if (allHosts != null && allHosts.size() > 0
                        && allHosts.get(0) != null) {
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  this.configSpec = new VMwareDVSConfigSpec();
                  this.configSpec.setConfigVersion("");
                  this.configSpec.setName(this.getTestId());
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_EDIT);
                  hostConfigSpecElement.setHost(allHosts.get(0));
                  this.configSpec.getHost().clear();
                  this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                  status = true;
               }
            } else {
               log.error("Failed to create the network folder");
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
   @Test(description = "Create a DVS with parameters set as "
               + "follows:\n"
               + " - ManagedObjectReference set to a valid folder object, \n"
               + " - DVSConfigSpec.configVersion is set to an empty string, \n"
               + " - DVSConfigSpec.name is set to 'Create DVS-Neg010', \n"
               + " - DVSConfigSpec.host.operation set to 'Edit'.")
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
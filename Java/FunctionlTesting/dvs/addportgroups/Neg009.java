/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Add two portgroups with valid parameters for the first portgroup and invalid
 * parameters for the second portgroup
 */
public class Neg009 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add two portgroups with valid parameters for the "
               + "first portgroup and invalid parameters for the second portgroup");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
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
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            log.info("Successfully found the datacenter");
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setMaxPorts(10);
            this.dvsConfigSpec.setName(this.getClass().getName());
            this.dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               this.dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[2];
               this.dvPortgroupConfigSpecArray[0] = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpecArray[0].setName(this.getTestId()
                        + "-1");
               this.dvPortgroupConfigSpecArray[0].setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
               this.dvPortgroupConfigSpecArray[0].setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               this.dvPortgroupConfigSpecArray[0].setNumPorts(2);
               this.dvPortgroupConfigSpecArray[0].setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
               this.dvPortgroupConfigSpecArray[1] = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpecArray[1].setName("abcdefghijklmnopqrstuvwxyzabsdjfldsfpfd");
               this.dvPortgroupConfigSpecArray[1].setDescription("abcdefghijklmnopqrstuvwxyzabsdjfldsfpfd");
               this.dvPortgroupConfigSpecArray[1].setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               this.dvPortgroupConfigSpecArray[1].setNumPorts(-2);
               this.dvPortgroupConfigSpecArray[1].setPortNameFormat(DVSTestConstants.DVPORTGROUP_INVALID_PORTNAMEFORMAT);
               status = true;
            } else {
               log.error("Failed to create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a folder");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that adds two portgroups with valid parameters for the first
    * portgroup and invalid parameters for the second portgroup
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add two portgroups with valid parameters for the "
               + "first portgroup and invalid parameters for the second portgroup")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                  dvPortgroupConfigSpecArray);
         log.error("API did not throw an exception");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         InvalidArgument expectedMethodFault = new InvalidArgument();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. Destroy
    * the portgroup, followed by the distributed virtual switch
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
     
         /*if(this.dvPortgroupMorList != null){
            for(ManagedObjectReference mor: dvPortgroupMorList){
               status = this.iManagedEntity.destroy(mor);
            }  
         }*/
         status = this.iManagedEntity.destroy(dvsMor);
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}

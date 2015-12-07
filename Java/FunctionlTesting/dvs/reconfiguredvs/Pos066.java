/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPortgroupPortgroupType;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVS as follows: - Set the DVSConfigSpec.configVersion
 * to a valid config version string - Set DVPortSetting.blocked to false - Set
 * DVPortSetting.pvlanID to a primary pvlanId that belongs to the pvlanMapEntry,
 * promiscuous type.
 */
public class Pos066 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVS as follows:\n"
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n" + "  - Set DVPortSetting.blocked to false,\n" + "");
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
               this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                        connectAnchor);
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  this.deltaConfigSpec = new DVSConfigSpec();
                  this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                  List<ManagedObjectReference> dvPortgroupMorList = null;
                  this.dvPortgroupConfigSpec.setName(this.getClass().getName()
                           + "-upg");
                  this.dvPortgroupConfigSpec.setType(DistributedVirtualPortgroupPortgroupType.EARLY_BINDING.value());
                  this.dvPortgroupConfigSpec.setNumPorts(10);
                  this.dvPortgroupConfigSpec.setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
                  dvPortgroupMorList = this.iDistributedVirtualSwitch.addPortGroups(
                           this.dvsMOR,
                           new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
                  if (dvPortgroupMorList != null
                           && dvPortgroupMorList.get(0) != null) {
                     log.info("The portgroup was successfully"
                              + " added to the dvswitch");
                     this.deltaConfigSpec.getUplinkPortgroup().clear();
                     this.deltaConfigSpec.getUplinkPortgroup().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { dvPortgroupMorList.get(0) }));
                     this.deltaConfigSpec.setConfigVersion(this.iDistributedVirtualSwitch.getConfig(
                              this.dvsMOR).getConfigVersion());
                     status = true;
                  } else {
                     log.error("Failed to add the portgroup to the"
                              + " dvswitch");
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
   @Test(description = "Reconfigure an existing DVS as follows:\n"
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n" + "  - Set DVPortSetting.blocked to false,\n" + "")
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
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
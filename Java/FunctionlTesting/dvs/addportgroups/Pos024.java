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
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Add an early binding portgroup to an existing distributed virtual switch with
 * portNameFormat "portgroupName-portIndex"
 */
public class Pos024 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DistributedVirtualPortgroup iDvPortgroup = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private String portNameFormat = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add a portgroup to an existing"
               + " distributed virtual switch with portNameFormat"
               + " set to <portgroupName>-<portIndex>");
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
      boolean setupDone = false;
      String className = null;
      String nameParts[] = null;
      String portgroupName = null;
      int len = 0;
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDvPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(this.getClass().getName());
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpec.setConfigVersion("");
               this.dvPortgroupConfigSpec.setName(this.getTestId());
               this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
               this.dvPortgroupConfigSpec.setNumPorts(1);
               this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               this.portNameFormat = DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTGROUPNAME
                        + "-"
                        + DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX;
               this.dvPortgroupConfigSpec.setPortNameFormat(portNameFormat);
               setupDone = true;
            } else {
               log.error("Failed to create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a folder");
         }
     
      assertTrue(setupDone, "Setup failed");
      return setupDone;
   }

   /**
    * Method that adds a portgroup to the distributed virtual switch with
    * configVersion set to an empty string, name set to a valid string,
    * description set to a valid string, numPorts set to one and portNameFormat
    * set to "<portgroupName-portIndex>"
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add a portgroup to an existing"
               + " distributed virtual switch with portNameFormat"
               + " set to <portgroupName>-<portIndex>")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      boolean isPortNameValid = false;
     
         if (dvPortgroupConfigSpec != null) {
            dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
            dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                     dvPortgroupConfigSpecArray);
            if (dvPortgroupMorList != null) {
               if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
                  log.info("Successfully added all the portgroups");
                  isPortNameValid = true;
                  for (ManagedObjectReference mor : dvPortgroupMorList) {
                     isPortNameValid &= iDvPortgroup.validatePortNameFormat(
                              mor, dvsMor);
                  }
                  if (isPortNameValid) {
                     testDone = true;
                  } else {
                     log.error("The individual port names do not "
                              + "match the portNameFormat of the portgroup");
                  }
               } else {
                  log.error("Could not add all the portgroups");
               }
            } else {
               log.error("No portgroups were added");
            }
         }
     
      assertTrue(testDone, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test was started. Destroy
    * the distributed virtual switch
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanUpDone = true;
     
         /*
          * Destroy the distributed virtual switch
          */
         cleanUpDone &= this.iManagedEntity.destroy(dvsMor);
     
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}

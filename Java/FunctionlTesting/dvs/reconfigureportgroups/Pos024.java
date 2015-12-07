/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

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
 * Reconfigure an early binding portgroup to an existing distributed virtual
 * switch with portNameFormat "portgroupName-portIndex"
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
      setTestDescription("Reconfigure a portgroup to an existing"
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
      boolean status = false;
      String className = null;
      String nameParts[] = null;
      String portgroupName = null;
      int len = 0;
      log.info("Test setup Begin:");
      try {
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
               this.dvPortgroupConfigSpec.setNumPorts(0);
               this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               this.dvPortgroupMorList = this.iDVSwitch.addPortGroups(dvsMor,
                        new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec });
               if (dvPortgroupMorList != null && dvPortgroupMorList.size() == 1) {
                  log.info("Successfully added the portgroup");
                  status = true;
               } else {
                  log.error("Failed to add the portgroup");
               }
            } else {
               log.error("Failed to create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a folder");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that reconfigures a portgroup to the distributed virtual switch
    * with portNameFormat set to "<dvsName-portIndex>"
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure a portgroup to an existing"
               + " distributed virtual switch with portNameFormat"
               + " set to <portgroupName>-<portIndex>")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      boolean isPortNameValid = false;
      try {
         this.portNameFormat = DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTGROUPNAME
                  + "-" + DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX;
         this.dvPortgroupConfigSpec.setPortNameFormat(portNameFormat);
         this.dvPortgroupConfigSpec.setConfigVersion(this.iDvPortgroup.getConfigInfo(
                  dvPortgroupMorList.get(0)).getConfigVersion());
         this.dvPortgroupConfigSpec.setNumPorts(1);
         if (this.iDvPortgroup.reconfigure(dvPortgroupMorList.get(0),
                  this.dvPortgroupConfigSpec)) {
            log.info("Successfully reconfigured the portgroup");
            isPortNameValid = true;
            for (ManagedObjectReference mor : dvPortgroupMorList) {
               isPortNameValid &= iDvPortgroup.validatePortNameFormat(mor,
                        dvsMor);
            }
            if (isPortNameValid) {
               status = true;
            } else {
               log.error("The individual port names do not "
                        + "match the portNameFormat of the portgroup");
            }
         } else {
            log.error("Could not reconfigure the portgroup");
         }
      } catch (Exception e) {
         status = false;
         TestUtil.handleException(e);
      }
      assertTrue(status, "Test Failed");
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
      boolean status = true;
      try {
         /*
          * Destroy the distributed virtual switch
          */
         status &= this.iManagedEntity.destroy(dvsMor);
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}

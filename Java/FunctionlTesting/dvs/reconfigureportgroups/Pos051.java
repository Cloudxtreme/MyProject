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
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Reconfigure an existing portgroup on an existing distributed virtual switch
 * with an invalid portNameFormat
 */
public class Pos051 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Reconfigure a portgroup on an existing "
               + "distributed virtual switch with an invalid "
               + "portNameFormat");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch and a portgroup on the switch.
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
      try {
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         this.dcMor = this.iFolder.getDataCenter();
         if (this.rootFolderMor != null) {
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(this.getClass().getName());
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
               dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
               this.dvPortgroupConfigSpec.setName(this.getTestId());
               this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               this.dvPortgroupConfigSpec.setNumPorts(0);
               dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                        dvPortgroupConfigSpecArray);
               if (dvPortgroupMorList != null) {
                  if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
                     log.info("Successfully added all the "
                              + "portgroups");
                     status = true;
                  } else {
                     log.error("Could not add all the portgroups");
                  }
               } else {
                  log.error("Failed to add portgroups");
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
    * Method that reconfigures an existing portgroup on a distributed virtual
    * switch with an invalid port name format
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure a portgroup on an existing "
               + "distributed virtual switch with an invalid "
               + "portNameFormat")
   public void test()
      throws Exception
   {
      List<DistributedVirtualPort> ports = null;
      boolean status = false;
      log.info("Test Begin:");
      try {

         if (dvPortgroupMorList != null && dvPortgroupMorList.size() > 0) {
            this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
            this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                     dvPortgroupMorList.get(0)).getConfigVersion());
            this.dvPortgroupConfigSpec.setPortNameFormat(DVSTestConstants.DVPORTGROUP_INVALID_PORTNAMEFORMAT);
            this.dvPortgroupConfigSpec.setNumPorts(1);
            if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                     this.dvPortgroupConfigSpec)) {
               log.info("Successfully reconfigured the portgroup");
               ports = this.iDVPortgroup.getPorts(dvPortgroupMorList.get(0));
               if (ports != null && ports.size() == 1) {
                  log.info("Successfully found the ports within "
                           + "the portgroup");
                  status = true;
                  for (DistributedVirtualPort port : ports) {
                     if (port.getConfig() != null) {
                        status &= port.getConfig().getName().equals(
                                 DVSTestConstants.DVPORTGROUP_INVALID_PORTNAMEFORMAT);
                     } else {
                        status = false;
                        log.error("The port configuration inside the "
                                 + "portgroup is null");
                     }
                  }
               } else {
                  log.error("Could not retrieve the ports within "
                           + "the portgroup");
               }
            } else {
               log.error("Failed to reconfigure the portgroup");
            }
         } else {
            log.error("There are no portgroups to be reconfigured");
         }
      } catch (Exception e) {
         status = false;
         TestUtil.handleException(e);
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
      try {
         /*if(this.dvPortgroupMorList != null){
            for(ManagedObjectReference mor: dvPortgroupMorList){
               status = this.iManagedEntity.destroy(mor);
            }  
         }*/
         if (this.dvsMor != null) {
            status = this.iManagedEntity.destroy(dvsMor);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}

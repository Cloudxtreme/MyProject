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

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a port into the portgroup with the blocked property set to false and
 * reconfigure an existing portgroup on an existing distributed virtual switch
 * with "settingBlockOverrideAllowed" set to false
 */
public class Neg032 extends TestBase
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
   private String portKey = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Move a port into the portgroup with the blocked "
               + "property set to false and reconfigure an existing portgroup on "
               + "an existing distributed virtual switch with "
               + "settingBlockOverrideAllowed set to false");
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
      DVPortConfigSpec portConfigSpec = null;
      DVPortSetting portSetting = null;
      DVPortgroupPolicy policy = null;
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
            this.dvsConfigSpec.setNumStandalonePorts(1);
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               portKey = iDVSwitch.getFreeStandaloneDVPortKey(dvsMor, null);
               if (portKey != null) {
                  log.info("Successfully found a DVPort key");
                  portConfigSpec = new DVPortConfigSpec();
                  portConfigSpec.setKey(portKey);
                  portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
                  portSetting = new DVPortSetting();
                  portSetting.setBlocked(DVSUtil.getBoolPolicy(false, false));
                  portConfigSpec.setSetting(portSetting);
                  if (iDVSwitch.reconfigurePort(dvsMor,
                           new DVPortConfigSpec[] { portConfigSpec })) {
                     log.info("Successfully reconfigured the port");
                     this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                     this.dvPortgroupConfigSpec.setName(this.getTestId());
                     this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                     policy = new DVPortgroupPolicy();
                     policy.setBlockOverrideAllowed(true);
                     this.dvPortgroupConfigSpec.setPolicy(policy);
                     dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
                     dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                              dvPortgroupConfigSpecArray);
                     if (dvPortgroupMorList != null) {
                        if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
                           log.info("Successfully added all the "
                                    + "portgroups");
                           if (this.iDVSwitch.movePort(
                                    dvsMor,
                                    new String[] { portKey },
                                    this.iDVPortgroup.getKey(dvPortgroupMorList.get(0)))) {
                              log.info("Successfully moved the "
                                       + "port into the portgroup.");
                              status = true;
                           } else {
                              log.error("Failed to move the port "
                                       + "into the portgroup.");
                           }
                        } else {
                           log.error("Could not add all the "
                                    + "portgroups");
                        }
                     } else {
                        log.error("Failed to add portgroups");
                     }
                  } else {
                     log.error("Could not reconfigure the port");
                  }
               } else {
                  log.error("Cannot find a free DVPort");
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
    * Method that moves a port into the portgroup with the blocked property set
    * to false and reconfigure an existing portgroup on an existing distributed
    * virtual switch with "settingBlockOverrideAllowed" set to false
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Move a port into the portgroup with the blocked "
               + "property set to false and reconfigure an existing portgroup on "
               + "an existing distributed virtual switch with "
               + "settingBlockOverrideAllowed set to false")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DVPortSetting portgroupSetting = null;
      DVPortgroupPolicy policy = null;
      try {

         if (dvPortgroupMorList != null && dvPortgroupMorList.size() > 0) {
            this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
            this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                     dvPortgroupMorList.get(0)).getConfigVersion());
            portgroupSetting = this.iDVSwitch.getConfig(dvsMor).getDefaultPortConfig();
            portgroupSetting.setBlocked(DVSUtil.getBoolPolicy(false, true));
            policy = new DVPortgroupPolicy();
            policy.setBlockOverrideAllowed(false);
            this.dvPortgroupConfigSpec.setPolicy(policy);
            if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                     this.dvPortgroupConfigSpec)) {
               log.error("Successfully reconfigured the portgroup. "
                        + "The API did not throw an exception.");
            } else {
               log.error("Failed to reconfigure the portgroup. "
                        + "The API did not throw an exception");
            }
         } else {
            log.error("There are no portgroups to be reconfigured");
         }
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
      try {
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

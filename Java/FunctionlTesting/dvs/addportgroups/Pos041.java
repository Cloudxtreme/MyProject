/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortSetting;
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
 * Add an early binding portgroup to an existing distributed virtual switch with
 * settingShapingOverrideAllowed set to true
 */
public class Pos041 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portgroupKey = null;
   private String portKey = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add an early binding portgroup to an existing "
               + "distributed virtual switch with "
               + "settingShapingOverrideAllowed set to true");
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
      final String dvsName = super.getTestId();
      VMwareDVSPortSetting portSetting = null;
      DVSTrafficShapingPolicy dvsInshapingPolicy = null;
      DVPortConfigSpec portConfigSpec = null;
      DVPortgroupPolicy portgroupPolicy = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(dvsName);
            this.dvsConfigSpec.setNumStandalonePorts(1);
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               portKey = iDVSwitch.getFreeStandaloneDVPortKey(dvsMor, null);
               dvsInshapingPolicy = DVSUtil.getTrafficShapingPolicy(false,
                        true, null, null, null);
               settingsMap = new HashMap<String, Object>();
               settingsMap.put(DVSTestConstants.INSHAPING_POLICY_KEY,
                        dvsInshapingPolicy);
               portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
               portConfigSpec = new DVPortConfigSpec();
               portConfigSpec.setSetting(portSetting);
               portConfigSpec.setKey(portKey);
               portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
               if (this.iDVSwitch.reconfigurePort(dvsMor,
                        new DVPortConfigSpec[] { portConfigSpec })) {
                  log.info("Successfully reconfigured the "
                           + "portgroup");
                  portgroupPolicy = new DVPortgroupPolicy();
                  portgroupPolicy.setShapingOverrideAllowed(true);
                  dvsInshapingPolicy = DVSUtil.getTrafficShapingPolicy(false,
                           false, null, null, null);
                  settingsMap.put(DVSTestConstants.INSHAPING_POLICY_KEY,
                           dvsInshapingPolicy);
                  portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
                  this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                  this.dvPortgroupConfigSpec.setConfigVersion("");
                  this.dvPortgroupConfigSpec.setPolicy(portgroupPolicy);
                  this.dvPortgroupConfigSpec.setDefaultPortConfig(portSetting);
                  this.dvPortgroupConfigSpec.setName(getTestId() + "-pg1");
                  this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
                  this.dvPortgroupConfigSpec.setNumPorts(1);
                  this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                  status = true;
               } else {
                  log.error("Failed to reconfigure the portgroup");
               }

            } else {
               log.error("Could not create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a folder");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that adds an early binding portgroup
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add an early binding portgroup to an existing "
               + "distributed virtual switch with "
               + "settingShapingOverrideAllowed set to true")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<DistributedVirtualPort> dvsPort = null;
     
         if (dvPortgroupConfigSpec != null) {
            dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
            dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                     dvPortgroupConfigSpecArray);
            if (dvPortgroupMorList != null) {
               if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
                  log.info("Successfully added all the portgroups");
                  portgroupKey = this.iDVPortgroup.getKey(dvPortgroupMorList.get(0));
                  if (portgroupKey != null) {
                     portCriteria = new DistributedVirtualSwitchPortCriteria();
                     portCriteria.setConnected(false);
                     portCriteria.getPortKey().clear();
                     portCriteria.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { portKey }));
                     dvsPort = this.iDVSwitch.fetchPorts(dvsMor, portCriteria);
                     if (this.iDVSwitch.movePort(dvsMor,
                              new String[] { portKey }, portgroupKey)) {
                        log.info("Successfully moved the port into "
                                 + "the portgroup");
                        portCriteria = new DistributedVirtualSwitchPortCriteria();
                        portCriteria.setConnected(false);
                        portCriteria.getPortKey().clear();
                        portCriteria.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { portKey }));
                        dvsPort = this.iDVSwitch.fetchPorts(dvsMor,
                                 portCriteria);
                        if (dvsPort != null) {
                           log.info("Found the port");
                           if (dvsPort.get(0).getConfig().getSetting().getInShapingPolicy().getEnabled().isValue() == true) {
                              log.info("The inshaping policy of "
                                       + "the port was retained");
                              status = true;
                           } else {
                              log.error("The inshaping policy of the"
                                       + " port was not retained");
                           }
                        } else {
                           log.error("Could not find the port");
                        }
                     } else {
                        log.error("Failed to move the port into the "
                                 + "portgroup");
                     }
                  } else {
                     log.error("Could not get the portgroup key");
                  }
               } else {
                  log.error("Could not add all the portgroups");
               }
            } else {
               log.error("No portgroups were added");
            }
         }

     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM.Destroy the portgroup, followed by the
    * distributed virtual switch
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
     
         /*if(this.dvPortgroupMorList != null){
            for(ManagedObjectReference mor: dvPortgroupMorList){
               status &= this.iManagedEntity.destroy(mor);
            }  
         }*/
         if (this.dvsMor != null) {
            status &= this.iManagedEntity.destroy(dvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}

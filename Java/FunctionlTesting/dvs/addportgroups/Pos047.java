/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSSecurityPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
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
 * settingSecurityPolicyOverrideAllowed set to true
 */
public class Pos047 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
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
   private VMwareDVSPortSetting dvsPortSetting = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add an early binding portgroup to an existing "
               + "distributed virtual switch with "
               + "settingSecurityPolicyOverrideAllowed set to true");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      final String dvsName = super.getTestId();
      VMwareDVSPortSetting dvPortgroupSetting = null;
      DVPortConfigSpec portConfigSpec = null;
      DVSSecurityPolicy portSecurityPolicy = null;
      DVSSecurityPolicy portgroupSecurityPolicy = null;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      log.info("Test setup Begin:");
      Map<String, Object> settingsMap = null;
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      rootFolderMor = iFolder.getRootFolder();
      dcMor = iFolder.getDataCenter();
      if (rootFolderMor != null) {
         dvsConfigSpec = new DVSConfigSpec();
         dvsConfigSpec.setConfigVersion("");
         dvsConfigSpec.setName(dvsName);
         dvsConfigSpec.setNumStandalonePorts(9);
         dvsMor = iFolder.createDistributedVirtualSwitch(
                  iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
         if (dvsMor != null) {
            log.info("Successfully created the distributed " + "virtual switch");
            portKey = iDVSwitch.getFreeStandaloneDVPortKey(dvsMor, null);
            portSecurityPolicy = DVSUtil.getDVSSecurityPolicy(false, false,
                     false, false);
            settingsMap = new HashMap<String, Object>();
            settingsMap.put(DVSTestConstants.SECURITY_POLICY_KEY,
                     portSecurityPolicy);
            dvsPortSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
            portConfigSpec = new DVPortConfigSpec();
            portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
            portConfigSpec.setKey(portKey);
            portConfigSpec.setSetting(dvsPortSetting);
            if (iDVSwitch.reconfigurePort(dvsMor,
                     new DVPortConfigSpec[] { portConfigSpec })) {
               log.info("Successfully reconfigured the port");
               portgroupPolicy = new VMwareDVSPortgroupPolicy();
               portgroupPolicy.setSecurityPolicyOverrideAllowed(true);
               portgroupSecurityPolicy = DVSUtil.getDVSSecurityPolicy(false,
                        true, true, true);
               settingsMap.put(DVSTestConstants.SECURITY_POLICY_KEY,
                        portgroupSecurityPolicy);
               dvPortgroupSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
               dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
               dvPortgroupConfigSpec.setConfigVersion("");
               dvPortgroupConfigSpec.setPolicy(portgroupPolicy);
               dvPortgroupConfigSpec.setDefaultPortConfig(dvPortgroupSetting);
               dvPortgroupConfigSpec.setName(getTestId() + "-pg1");
               dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
               dvPortgroupConfigSpec.setNumPorts(1);
               dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               status = true;
            } else {
               log.error("Failed to reconfigure the port");
            }
         } else {
            log.error("Could not create the distributed " + "virtual switch");
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
   @Override
   @Test(description = "Add an early binding portgroup to an existing "
            + "distributed virtual switch with "
            + "settingSecurityPolicyOverrideAllowed set to true")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<DistributedVirtualPort> dvsPort = null;
      VMwareDVSPortSetting actualPortSetting = null;
      if (dvPortgroupConfigSpec != null) {
         dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
         dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                  dvPortgroupConfigSpecArray);
         if (dvPortgroupMorList != null) {
            if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
               log.info("Successfully added all the portgroups");
               portgroupKey = iDVPortgroup.getKey(dvPortgroupMorList.get(0));
               if (portgroupKey != null) {
                  if (iDVSwitch.movePort(dvsMor, new String[] { portKey },
                           portgroupKey)) {
                     log.info("Successfully moved the port into "
                              + "the portgroup");
                     portCriteria = new DistributedVirtualSwitchPortCriteria();
                     portCriteria.setConnected(false);
                     portCriteria.getPortKey().clear();
                     portCriteria.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { portKey }));
                     dvsPort = iDVSwitch.fetchPorts(dvsMor, portCriteria);
                     if (dvsPort != null) {
                        log.info("Found the port");
                        if (dvsPort.get(0).getConfig().getSetting() instanceof VMwareDVSPortSetting) {
                           actualPortSetting = (VMwareDVSPortSetting) dvsPort.get(
                                    0).getConfig().getSetting();
                           status = TestUtil.compareObject(
                                    actualPortSetting.getSecurityPolicy(),
                                    dvsPortSetting.getSecurityPolicy(), null);
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
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      /*
       * if(this.dvPortgroupMorList != null){ for(ManagedObjectReference mor:
       * dvPortgroupMorList){ status &= this.iManagedEntity.destroy(mor); } }
       */
      if (dvsMor != null) {
         status &= iManagedEntity.destroy(dvsMor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}

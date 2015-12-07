/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
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
 * Reconfigure an early binding portgroup to an existing distributed virtual
 * switch with settingShapingOverrideAllowed set to false
 */
public class Neg038 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
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
      setTestDescription("Reconfigure an early binding portgroup to an "
               + "existing distributed virtual switch with "
               + "settingShapingOverrideAllowed set to false");
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
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      DVPortSetting dvsPortSetting = null;
      DVPortConfigSpec portConfigSpec = null;
      DVPortgroupPolicy portgroupPolicy = null;
      DVSTrafficShapingPolicy dvsInshapingPolicy = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
      try {
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(dvsName);
            this.dvsConfigSpec.setNumStandalonePorts(8);

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
               dvsPortSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);

               portConfigSpec = new DVPortConfigSpec();
               portConfigSpec.setKey(portKey);
               portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
               portConfigSpec.setSetting(dvsPortSetting);
               if (this.iDVSwitch.reconfigurePort(dvsMor,
                        new DVPortConfigSpec[] { portConfigSpec })) {
                  log.info("Successfully reconfigured the port "
                           + "setting");
                  this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                  this.dvPortgroupConfigSpec.setNumPorts(1);
                  this.dvPortgroupConfigSpec.setName(this.getTestId());
                  this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                  portgroupPolicy = new DVPortgroupPolicy();
                  portgroupPolicy.setShapingOverrideAllowed(true);
                  this.dvPortgroupConfigSpec.setPolicy(portgroupPolicy);
                  dvPortgroupMorList = this.iDVSwitch.addPortGroups(
                           dvsMor,
                           new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec });
                  if (dvPortgroupMorList != null
                           && dvPortgroupMorList.get(0) != null) {
                     log.info("Successfully added the portgroup");
                     portgroupKey = this.iDVPortgroup.getKey(dvPortgroupMorList.get(0));
                     if (this.iDVSwitch.movePort(dvsMor,
                              new String[] { portKey }, portgroupKey)) {
                        log.info("Successfully moved the "
                                 + "port into the portgroup");
                        status = true;
                     } else {
                        log.error("Failed to move the port "
                                 + "into the portgroup");
                     }
                  } else {
                     log.error("Failed to add the portgroup");
                  }
               } else {
                  log.error("Failed to reconfigure the port "
                           + "setting");
               }
            } else {
               log.error("Could not create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a data center");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that reconfigures an early binding portgroup
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an early binding portgroup to an "
               + "existing distributed virtual switch with "
               + "settingShapingOverrideAllowed set to false")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DVPortConfigSpec port = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<DistributedVirtualPort> dvsPort = null;
      DVSTrafficShapingPolicy dvPortgroupInshapingPolicy = null;
      DVPortSetting dvPortgroupSetting = null;
      DVPortgroupPolicy portgroupPolicy = null;
      try {
         port = this.iDVSwitch.getPortConfigSpec(dvsMor,
                  new String[] { portKey })[0];
         this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
         this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                  this.dvPortgroupMorList.get(0)).getConfigVersion());
         portgroupPolicy = new DVPortgroupPolicy();
         portgroupPolicy.setShapingOverrideAllowed(false);
         dvPortgroupSetting = new DVPortSetting();
         dvPortgroupInshapingPolicy = DVSUtil.getTrafficShapingPolicy(false,
                  false, null, null, null);
         dvPortgroupSetting.setInShapingPolicy(dvPortgroupInshapingPolicy);
         this.dvPortgroupConfigSpec.setPolicy(portgroupPolicy);
         this.dvPortgroupConfigSpec.setDefaultPortConfig(dvPortgroupSetting);
         if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                  this.dvPortgroupConfigSpec)) {
            log.error("Successfully reconfigured the porgroup "
                     + "but the API did not throw an exception");

         } else {
            log.error("Coud not reconfigure the portgroup but "
                     + "the API did not throw an exception");
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         MethodFault expectedMethodFault = new InvalidArgument();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
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
      try {
         if (this.dvsMor != null) {
            status &= this.iManagedEntity.destroy(dvsMor);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}

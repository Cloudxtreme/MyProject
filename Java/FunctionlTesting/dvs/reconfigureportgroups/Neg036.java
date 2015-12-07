/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortgroupConfigInfo;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
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
 * with "settingUplinkTeamingOverrideAllowed" set to false
 */
public class Neg036 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
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
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a port into the portgroup with the blocked "
               + "property set to false and reconfigure an existing portgroup on "
               + "an existing distributed virtual switch with "
               + "settingUplinkTeamingOverrideAllowed set to false");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch and a portgroup on the switch.
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
      DVPortConfigSpec portConfigSpec = null;
      VMwareDVSPortSetting portSetting = null;
      VMwareDVSPortgroupPolicy dvPortgroupPolicy = null;
      HashMap<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
      try {
         iFolder = new Folder(connectAnchor);
         iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         iManagedEntity = new ManagedEntity(connectAnchor);
         rootFolderMor = iFolder.getRootFolder();
         dcMor = iFolder.getDataCenter();
         if (rootFolderMor != null) {
            dvsConfigSpec = new DVSConfigSpec();
            dvsConfigSpec.setConfigVersion("");
            dvsConfigSpec.setName(this.getClass().getName());
            dvsConfigSpec.setNumStandalonePorts(1);
            dvsMor = iFolder.createDistributedVirtualSwitch(
                     iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               portKey = iDVSwitch.getFreeStandaloneDVPortKey(dvsMor, null);
               if (portKey != null) {
                  log.info("Successfully found a DVPort key");
                  portConfigSpec = new DVPortConfigSpec();
                  portConfigSpec.setKey(portKey);
                  portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
                  settingsMap = new HashMap<String, Object>();
                  settingsMap.put(DVSTestConstants.UPLINK_TEAMING_POLICY_KEY,
                           DVSUtil.getUplinkPortTeamingPolicy(false, null,
                                    null, true, null, null, null));
                  portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
                  portConfigSpec.setSetting(portSetting);
                  if (iDVSwitch.reconfigurePort(dvsMor,
                           new DVPortConfigSpec[] { portConfigSpec })) {
                     log.info("Successfully reconfigured the port");
                     dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                     dvPortgroupConfigSpec.setName(getTestId());
                     dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                     dvPortgroupPolicy = new VMwareDVSPortgroupPolicy();
                     dvPortgroupPolicy.setUplinkTeamingOverrideAllowed(true);
                     dvPortgroupConfigSpec.setPolicy(dvPortgroupPolicy);
                     dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
                     dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                              dvPortgroupConfigSpecArray);
                     if (dvPortgroupMorList != null) {
                        if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
                           log.info("Successfully added all the "
                                    + "portgroups");
                           if (iDVSwitch.movePort(
                                    dvsMor,
                                    new String[] { portKey },
                                    iDVPortgroup.getKey(dvPortgroupMorList.get(0)))) {
                              log.info("Successfully moved the "
                                       + "port into the portgroup.");
                              status = true;
                           } else {
                              log.error("Failed to move the port "
                                       + "into the portgroup.");
                           }
                        } else {
                           log.error("Could not add all the " + "portgroups");
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
               log.error("Failed to create the distributed " + "virtual switch");
            }
         } else {
            log.error("Failed to find a folder");
         }
      } catch (final Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that moves a port into the portgroup and reconfigure an existing
    * portgroup on an existing distributed virtual switch with
    * "settingUplinkTeamingOverrideAllowed" set to false
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Move a port into the portgroup with the blocked "
            + "property set to false and reconfigure an existing portgroup on "
            + "an existing distributed virtual switch with "
            + "settingUplinkTeamingOverrideAllowed set to false")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DVPortgroupConfigInfo pgConfigInfo = null;
      VMwareDVSPortSetting portgroupSetting = null;
      VMwareDVSPortgroupPolicy policy = null;
      VmwareUplinkPortTeamingPolicy portgroupUplinkPolicy = null;
      Map<String, Object> settingsMap = null;
      try {
         if (dvPortgroupMorList != null && dvPortgroupMorList.size() > 0) {
            pgConfigInfo = iDVPortgroup.getConfigInfo(dvPortgroupMorList.get(0));
            dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
            dvPortgroupConfigSpec.setConfigVersion(pgConfigInfo.getConfigVersion());
            portgroupSetting = (VMwareDVSPortSetting) pgConfigInfo.getDefaultPortConfig();
            portgroupUplinkPolicy = portgroupSetting.getUplinkTeamingPolicy();
            if (portgroupUplinkPolicy == null) {
               portgroupUplinkPolicy = DVSUtil.getUplinkPortTeamingPolicy(
                        false, null, null, false, null, null, null);
            } else {
               portgroupUplinkPolicy.setNotifySwitches(DVSUtil.getBoolPolicy(
                        false, true));
               portgroupUplinkPolicy.setInherited(false);
            }
            settingsMap = new HashMap<String, Object>();
            settingsMap.put(DVSTestConstants.UPLINK_TEAMING_POLICY_KEY,
                     portgroupUplinkPolicy);
            portgroupSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
            policy = new VMwareDVSPortgroupPolicy();
            policy.setUplinkTeamingOverrideAllowed(false);
            dvPortgroupConfigSpec.setPolicy(policy);
            dvPortgroupConfigSpec.setDefaultPortConfig(portgroupSetting);
            if (iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                     dvPortgroupConfigSpec)) {
               log.error("Successfully reconfigured the portgroup. "
                        + "The API did not throw an exception.");
            } else {
               log.error("Failed to reconfigure the portgroup. "
                        + "The API did not throw an exception");
            }
         } else {
            log.error("There are no portgroups to be reconfigured");
         }
      } catch (final Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         final InvalidArgument expectedMethodFault = new InvalidArgument();
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
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      try {
         if (dvsMor != null) {
            status = iManagedEntity.destroy(dvsMor);
         }
      } catch (final Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}

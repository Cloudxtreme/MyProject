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
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

/**
 * Move a port into the portgroup with a valid pvlanid and reconfigure an
 * existing portgroup on an existing distributed virtual switch with
 * "settingVlanOverrideAllowed" set to false
 */
public class Neg035 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitchHelper iVMwareDVS = null;
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
      setTestDescription("Move a port into the portgroup with a valid "
               + "pvlanid and reconfigure an existing portgroup on "
               + "an existing distributed virtual switch with "
               + "settingVlanOverrideAllowed set to false");
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
      VMwareDVSPortgroupPolicy policy = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanspec = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
      try {
         iFolder = new Folder(connectAnchor);
         iVMwareDVS = new DistributedVirtualSwitchHelper(connectAnchor);
         iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         dcMor = iFolder.getDataCenter();
         iManagedEntity = new ManagedEntity(connectAnchor);
         rootFolderMor = iFolder.getRootFolder();
         if (rootFolderMor != null) {
            dvsConfigSpec = new DVSConfigSpec();
            dvsConfigSpec.setConfigVersion("");
            dvsConfigSpec.setName(this.getClass().getName());
            dvsConfigSpec.setNumStandalonePorts(5);
            dvsMor = iFolder.createDistributedVirtualSwitch(
                     iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               if (iVMwareDVS.addPrimaryPvlan(dvsMor, 10)) {
                  log.info("Successfully added the pvlan map entry");
                  if (iVMwareDVS.addPrimaryPvlan(dvsMor, 12)) {
                     log.info("Successfully added the pvlan map " + "entry");
                     portKey = iVMwareDVS.getFreeStandaloneDVPortKey(dvsMor,
                              null);
                     if (portKey != null) {
                        log.info("Successfully found a DVPort key");
                        portConfigSpec = new DVPortConfigSpec();
                        portConfigSpec.setKey(portKey);
                        portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
                        pvlanspec = new VmwareDistributedVirtualSwitchPvlanSpec();
                        pvlanspec.setPvlanId(10);
                        pvlanspec.setInherited(false);
                        settingsMap = new HashMap<String, Object>();
                        settingsMap.put(DVSTestConstants.VLAN_KEY, pvlanspec);
                        portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
                        portConfigSpec.setSetting(portSetting);
                        if (iVMwareDVS.reconfigurePort(dvsMor,
                                 new DVPortConfigSpec[] { portConfigSpec })) {
                           log.info("Successfully reconfigured " + "the port");
                           dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                           dvPortgroupConfigSpec.setName(getTestId());
                           dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                           policy = new VMwareDVSPortgroupPolicy();
                           policy.setVlanOverrideAllowed(true);
                           dvPortgroupConfigSpec.setPolicy(policy);
                           dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
                           dvPortgroupMorList = iVMwareDVS.addPortGroups(
                                    dvsMor, dvPortgroupConfigSpecArray);
                           if (dvPortgroupMorList != null) {
                              if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
                                 log.info("Successfully added all"
                                          + " the portgroups");
                                 if (iVMwareDVS.movePort(
                                          dvsMor,
                                          new String[] { portKey },
                                          iDVPortgroup.getKey(dvPortgroupMorList.get(0)))) {
                                    log.info("Successfully moved"
                                             + " the port into the"
                                             + " portgroup");
                                    status = true;
                                 } else {
                                    log.error("Failed to move the"
                                             + " port into the " + "portgroup");
                                 }
                              } else {
                                 log.error("Could not add all the "
                                          + "portgroups");
                              }
                           } else {
                              log.error("Failed to add portgroups");
                           }
                        } else {
                           log.error("Could not reconfigure the " + "port");
                        }
                     } else {
                        log.error("Cannot find a free DVPort");
                     }
                  } else {
                     log.error("Failed to create the distributed "
                              + "virtual switch");
                  }
               } else {
                  log.error("Can not add the pvlan map entry");
               }
            } else {
               log.error("Can not add the pvlan map entry");
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
    * Method that moves a port into the portgroup with a valid pvlanid and
    * reconfigure an existing portgroup on an existing distributed virtual
    * switch with "settingVlanOverrideAllowed" set to false
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Move a port into the portgroup with a valid "
            + "pvlanid and reconfigure an existing portgroup on "
            + "an existing distributed virtual switch with "
            + "settingVlanOverrideAllowed set to false")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      VMwareDVSPortSetting portgroupSetting = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanspec = null;
      VMwareDVSPortgroupPolicy policy = null;
      Map<String, Object> settingsMap = null;
      try {
         if (dvPortgroupMorList != null && dvPortgroupMorList.size() > 0) {
            dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
            dvPortgroupConfigSpec.setConfigVersion(iDVPortgroup.getConfigInfo(
                     dvPortgroupMorList.get(0)).getConfigVersion());
            pvlanspec = new VmwareDistributedVirtualSwitchPvlanSpec();
            pvlanspec.setPvlanId(12);
            settingsMap = new HashMap<String, Object>();
            settingsMap.put(DVSTestConstants.VLAN_KEY, pvlanspec);
            portgroupSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
            portgroupSetting.setVlan(pvlanspec);
            policy = new VMwareDVSPortgroupPolicy();
            policy.setVlanOverrideAllowed(false);
            dvPortgroupConfigSpec.setPolicy(policy);
            dvPortgroupConfigSpec.setDefaultPortConfig(portgroupSetting);
            if (iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                     dvPortgroupConfigSpec)) {
               log.error("Successfully reconfigured the portgroup. "
                        + "The API did not throw an exception");
            } else {
               log.error("Failed to reconfigure the portgroup."
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
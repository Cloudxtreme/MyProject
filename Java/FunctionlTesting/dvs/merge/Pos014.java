/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vc.VmwareDistributedVirtualSwitchPvlanPortType.*;
import static com.vmware.vcqa.util.Assert.*;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

/**
 * Create two dvswitches with the following configuration: configuration:
 * dest_defaultPortConfig with valid pvlan id, valid src_defaultPortConfig pvlan
 * id. Merge the two dvswitches.
 */
public class Pos014 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DVSConfigSpec configSpec = null;
   private DistributedVirtualSwitchHelper iDVSwitch = null;
   private ManagedObjectReference dcMor = null;
   private VMwareDVSConfigInfo destDvsConfigInfo = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create two dvswitches with the following "
               + "configuration: dest_defaultPortConfig with valid pvlan id, "
               + "valid src_defaultPortConfig with valid pvlan id. "
               + "Merge the two dvswitches.");
   }

   /**
    * Method to setup the environment for the test.
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
      DVSConfigInfo configInfo = null;
      final String destDvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId() + DVSTestConstants.DVS_DESTINATION_SUFFIX;
      final String srcDvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId() + DVSTestConstants.DVS_SOURCE_SUFFIX;
      log.info("Test setup Begin:");
      VMwareDVSPortSetting portSetting = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanConfigSpec = null;
      iFolder = new Folder(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitchHelper(connectAnchor);
      dcMor = iFolder.getDataCenter();
      if (dcMor != null) {
         // create the destination dvs
         configSpec = new DVSConfigSpec();
         configSpec.setConfigVersion("");
         configSpec.setName(destDvsName);
         destDvsMor = iFolder.createDistributedVirtualSwitch(
                  iFolder.getNetworkFolder(dcMor), configSpec);
         if (destDvsMor != null) {
            log.info("Successfully created the destination DVS");
            status = iDVSwitch.addPvlan(destDvsMor, PROMISCUOUS.value(), 21,
                     21);
            if (status) {
               log.info("Succesfully added the pvlan map entry to the "
                        + "destination DVS ");
               status = iDVSwitch.addPrimaryPvlan(destDvsMor, 15);
               if (status) {
                  log.info("Successfully added the pvlan id " + 15
                           + "to the destination DVS");
                  configInfo = iDVSwitch.getConfig(destDvsMor);
                  if (configInfo != null) {
                     configSpec = new DVSConfigSpec();
                     configSpec.setConfigVersion(configInfo.getConfigVersion());
                     pvlanConfigSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
                     pvlanConfigSpec.setPvlanId(21);
                     pvlanConfigSpec.setInherited(false);
                     portSetting = (VMwareDVSPortSetting) configInfo.getDefaultPortConfig();
                     portSetting.setVlan(pvlanConfigSpec);
                     portSetting.setVlan(pvlanConfigSpec);
                     configSpec.setDefaultPortConfig(portSetting);
                     if (iDVSwitch.reconfigure(destDvsMor,
                              configSpec)) {
                        log.info("Successfully set the pvlan in the "
                                 + "default port setting");
                        configSpec = new DVSConfigSpec();
                        configSpec.setConfigVersion("");
                        // create the src dvs
                        configSpec.setName(srcDvsName);
                        srcDvsMor = iFolder.createDistributedVirtualSwitch(
                                 iFolder.getNetworkFolder(dcMor),
                                 configSpec);
                        // store the destn dvs config info for matching
                        // description property
                        if (srcDvsMor != null) {
                           log.info("Successfully created the source "
                                    + "and destination distributed virtual "
                                    + "switches");
                           status = iDVSwitch.addPrimaryPvlan(
                                    srcDvsMor, 15);
                           if (status) {
                              log.info("Succesfully added the pvlan map "
                                       + "entry to the source DVS");
                              status = iDVSwitch.addPrimaryPvlan(
                                       srcDvsMor, 21);
                              if (status) {
                                 log.info("Successfully added the primary"
                                          + " pvlan " + 21 + "to the Src DVS");
                                 configInfo = iDVSwitch.getConfig(srcDvsMor);
                                 if (configInfo != null) {
                                    configSpec = new DVSConfigSpec();
                                    configSpec.setConfigVersion(configInfo.getConfigVersion());
                                    pvlanConfigSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
                                    pvlanConfigSpec.setPvlanId(15);
                                    pvlanConfigSpec.setInherited(false);
                                    portSetting = (VMwareDVSPortSetting) configInfo.getDefaultPortConfig();
                                    portSetting.setVlan(pvlanConfigSpec);
                                    configSpec.setDefaultPortConfig(portSetting);
                                    if (iDVSwitch.reconfigure(
                                             srcDvsMor, configSpec)) {
                                       log.info("Successfully set the "
                                                + "pvlan in the default "
                                                + "port setting");
                                       destDvsConfigInfo = iDVSwitch.getConfig(destDvsMor);
                                       destDvsConfigInfo.setMaxPorts(destDvsConfigInfo.getMaxPorts()
                                                + iDVSwitch.getConfig(srcDvsMor).getMaxPorts());
                                    } else {
                                       status &= false;
                                       log.error("Can not reconifgure "
                                                + "the port setting of "
                                                + "the DVS with the "
                                                + "pvlan id");
                                    }
                                 } else {
                                    status &= false;
                                    log.error("the config info is null");
                                 }
                              } else {
                                 log.error("Can nto add the pvlan map "
                                          + "entry " + 21 + "to the Src DVS");
                              }
                           } else {
                              log.error("Can not add the pvlan map entry"
                                       + " to the destination DVS");
                           }
                        } else {
                           status &= false;
                           log.error("Could not create the source or "
                                    + "destination distributed virtual "
                                    + "switches");
                        }
                     } else {
                        status &= false;
                        log.error("Can not reconfigure the destination "
                                 + "DVS");
                     }
                  } else {
                     log.error("The config info is null");
                     status &= false;
                  }
               } else {
                  log.error("Can not add the pvlan entry " + 15 + "to the dvs");
               }
            } else {
               log.error("Can not add the pvlan entry " + 21 + "to the dvs");
            }
         } else {
            log.error("Can not create the destination DVS");
         }
      } else {
         log.error("There is no datacenter in the setup");
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Create two dvswitches with the following "
            + "configuration: dest_defaultPortConfig with valid pvlan id, "
            + "valid src_defaultPortConfig with valid pvlan id. "
            + "Merge the two dvswitches.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      if (iDVSwitch.merge(destDvsMor, srcDvsMor)) {
         log.info("Successfully merged the switches");
         if (iManagedEntity.isExists(srcDvsMor)) {
            log.error("Source DVS still exists.");
         } else {
            final VMwareDVSConfigInfo mergedDVSConfigInfo = iDVSwitch.getConfig(destDvsMor);
            if (mergedDVSConfigInfo != null) {
               Vector<String> props = TestUtil.getIgnorePropertyList(
                        destDvsConfigInfo, false);
               if (props == null) {
                  props = new Vector<String>();
               }
               if (props == null) {
                  props = new Vector<String>();
               }
               props.add("VMwareDVSConfigInfo.ConfigVersion");
               props.add(DVSTestConstants.VMWAREDVSCONFIGINFO_MAXPORTS);
               if (TestUtil.compareObject(mergedDVSConfigInfo,
                        destDvsConfigInfo, props)) {
                  log.info("Merged contact info matched");
                  status = true;
               } else {
                  log.error("Merged contact info not matched.");
               }
            } else {
               log.error("Merged DVS config info is null.");
            }
         }
      } else {
         log.error("Failed to merge the switches");
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      // check if src dvs exists
      if (iManagedEntity.isExists(srcDvsMor)) {
         // check if able to destroy it
         status = iManagedEntity.destroy(srcDvsMor);
      } else {
         status = true; // src does not exist, so set status as true
      }
      // check if destn dvs exists
      if (iManagedEntity.isExists(destDvsMor)) {
         // destroy the destn
         status &= iManagedEntity.destroy(destDvsMor);
      } else {
         status &= true; // the clean up is still true if destn is not
         // present
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
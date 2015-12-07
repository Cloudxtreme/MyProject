/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vc.VmwareDistributedVirtualSwitchPvlanPortType.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

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
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

/**
 * Create two dvswitches with the following configuration: configuration:
 * dest_defaultPortConfig with valid pvlan id, valid src_defaultPortConfig.
 * Merge the two dvswitches.
 */
public class Pos013 extends TestBase
{
   private Folder folder = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DVSConfigSpec configSpec = null;
   private DistributedVirtualSwitchHelper vmwareDvs;
   private VMwareDVSPortSetting src = null;
   private VMwareDVSPortSetting dest = null;
   private VMwareDVSConfigInfo destDvsCfgInfo = null;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      folder = new Folder(connectAnchor);
      final ManagedObjectReference dcMor = folder.getDataCenter();
      assertNotNull(dcMor, DC_MOR_GET_PASS, DC_MOR_GET_FAIL);
      final String destDvsName = getTestId() + DVS_DESTINATION_SUFFIX;
      final String srcDvsName = getTestId() + DVS_SOURCE_SUFFIX;
      vmwareDvs = new DistributedVirtualSwitchHelper(connectAnchor);
      log.info("Creating destination DVS {}", destDvsName);
      configSpec = new DVSConfigSpec();
      configSpec.setConfigVersion("");
      configSpec.setName(destDvsName);
      configSpec.setDefaultPortConfig(dest);
      destDvsMor = folder.createDistributedVirtualSwitch(
               folder.getNetworkFolder(dcMor), configSpec);
      assertNotNull(destDvsMor, "Failed to create destination DVS");
      assertTrue(vmwareDvs.addPvlan(destDvsMor, PROMISCUOUS.value(), 15, 15),
               "Failed to add PVLAN");
      final DVSConfigInfo configInfo = vmwareDvs.getConfig(destDvsMor);
      final VmwareDistributedVirtualSwitchPvlanSpec pvlanSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
      pvlanSpec.setPvlanId(15);
      pvlanSpec.setInherited(false);
      dest = (VMwareDVSPortSetting) configInfo.getDefaultPortConfig();
      dest.setVlan(pvlanSpec);
      configSpec = new DVSConfigSpec();
      configSpec.setConfigVersion(configInfo.getConfigVersion());
      configSpec.setDefaultPortConfig(dest);
      assertTrue(vmwareDvs.reconfigure(destDvsMor, configSpec),
               "Failed to set PVLAN to default DVPort config");
      log.info("Creating source DVS {}", srcDvsName);
      configSpec = new DVSConfigSpec();
      configSpec.setConfigVersion("");
      configSpec.setName(srcDvsName);
      src = new VMwareDVSPortSetting();
      configSpec.setDefaultPortConfig(src);
      srcDvsMor = folder.createDistributedVirtualSwitch(
               folder.getNetworkFolder(dcMor), configSpec);
      assertNotNull(srcDvsMor, "Failed to create source DVS");
      destDvsCfgInfo = vmwareDvs.getConfig(destDvsMor);
      destDvsCfgInfo.setMaxPorts(destDvsCfgInfo.getMaxPorts()
               + vmwareDvs.getConfig(srcDvsMor).getMaxPorts());
      return true;
   }

   @Override
   @Test(description = "Create two dvswitches with the following "
            + "configuration: dest_defaultPortConfig with valid pvlan id, "
            + "valid src_defaultPortConfig. Merge the two dvswitches.")
   public void test()
      throws Exception
   {
      assertTrue(vmwareDvs.merge(destDvsMor, srcDvsMor), "Merge unsuccessful");
      log.info("Successfully merged the switches");
      assertFalse(vmwareDvs.isExists(srcDvsMor), "Source DVS still exists.");
      assertTrue(vmwareDvs.isExists(destDvsMor),
               "Destination DVS doesnot exist");
      final VMwareDVSConfigInfo mergedDVSConfigInfo = vmwareDvs.getConfig(destDvsMor);
      assertNotNull(mergedDVSConfigInfo, "Merged DVS cfg not found.");
      final Vector<String> props = TestUtil.getIgnorePropertyList(
               destDvsCfgInfo, false);
      props.add(DVSTestConstants.VMWARE_DVS_CONFIGINFO_CONFIGVERSION);
      props.add(DVSTestConstants.VMWAREDVSCONFIGINFO_MAXPORTS);
      assertTrue(TestUtil.compareObject(mergedDVSConfigInfo, destDvsCfgInfo,
               props), "Merged config info not matched.");
      log.info("Merged config info matched");
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      // check if src dvs exists
      if (srcDvsMor != null && vmwareDvs.isExists(srcDvsMor)) {
         // check if able to destroy it
         status = vmwareDvs.destroy(srcDvsMor);
      } else {
         status = true; // src does not exist, so set status as true
      }
      // check if destn dvs exists
      if (destDvsMor != null && vmwareDvs.isExists(destDvsMor)) {
         // destroy the destn
         status &= vmwareDvs.destroy(destDvsMor);
      } else {
         status &= true; // the clean up is still true if destn is not present
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
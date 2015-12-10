/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Create two dvswitches with the following configuration:
 * dest_defaultPortConfig blocked = true , src_defaultPortConfig blocked= false.
 * Merge the two dvswitches.
 */
public class Pos009 extends TestBase
{
   private Folder folder = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DistributedVirtualSwitch dvs = null;
   private DVSConfigSpec configSpec = null;
   private DVSConfigInfo destDvsConfigInfo = null;
   private DVPortSetting src = null;
   private DVPortSetting dest = null;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      final String destDvsName = getTestId() + DVS_DESTINATION_SUFFIX;
      final String srcDvsName = getTestId() + DVS_SOURCE_SUFFIX;
      folder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      dcMor = folder.getDataCenter();
      log.info("Creating destination DVS {}", destDvsName);
      configSpec = new DVSConfigSpec();
      configSpec.setConfigVersion("");
      configSpec.setName(destDvsName);
      dest = new VMwareDVSPortSetting();
      dest.setBlocked(DVSUtil.getBoolPolicy(false, true));
      configSpec.setDefaultPortConfig(dest);
      destDvsMor = folder.createDistributedVirtualSwitch(
               folder.getNetworkFolder(dcMor), configSpec);
      assertNotNull(destDvsMor, "Failed to create destination DVS");
      log.info("Creating source DVS {}", srcDvsName);
      configSpec.setName(srcDvsName);
      src = new VMwareDVSPortSetting();
      src.setBlocked(DVSUtil.getBoolPolicy(false, false));
      configSpec.setDefaultPortConfig(src);
      srcDvsMor = folder.createDistributedVirtualSwitch(
               folder.getNetworkFolder(dcMor), configSpec);
      assertNotNull(srcDvsMor, "Failed to create source DVS");
      destDvsConfigInfo = dvs.getConfig(destDvsMor);
      destDvsConfigInfo.setMaxPorts(destDvsConfigInfo.getMaxPorts()
               + dvs.getConfig(srcDvsMor).getMaxPorts());
      return true;
   }

   @Override
   @Test(description = "Create two dvswitches with the following "
            + "configuration: dest_defaultPortConfig.blocked = true, "
            + "src_defaultPortConfig.blocked=false. Merge the two dvswitches.")
   public void test()
      throws Exception
   {
      Vector<String> props = null;
      assertTrue(dvs.merge(destDvsMor, srcDvsMor), "Merge failed");
      log.info("Successfully merged the DVS's");
      assertFalse(dvs.isExists(srcDvsMor), "Source DVS still exists.");
      assertTrue(dvs.isExists(destDvsMor), "Destination DVS doesnot exist");
      final DVSConfigInfo mergedDVSConfigInfo = dvs.getConfig(destDvsMor);
      assertNotNull(mergedDVSConfigInfo, "Merged DVS cfg not found.");
      props = TestUtil.getIgnorePropertyList(destDvsConfigInfo, false);
      props.add(DVSTestConstants.VMWAREDVSCONFIGINFO_MAXPORTS);
      props.add(DVSTestConstants.VMWARE_DVS_CONFIGINFO_CONFIGVERSION);
      assertTrue(TestUtil.compareObject(mergedDVSConfigInfo, destDvsConfigInfo,
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
      if (dvs.isExists(srcDvsMor)) {
         // check if able to destroy it
         status = dvs.destroy(srcDvsMor);
      } else {
         status = true; // src does not exist, so set status as true
      }
      // check if destn dvs exists
      if (dvs.isExists(destDvsMor)) {
         // destroy the destn
         status &= dvs.destroy(destDvsMor);
      } else {
         status &= true; // the clean up is still true if dest is not present
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
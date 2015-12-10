/*
 * ************************************************************************
 *
 * Copyright 20010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Add a portgroup to an existing distributed virtual switch with a valid uplink
 * teaming policy.
 */
public class Pos030 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMors = null;
   private VMwareDVSPortSetting dvPortSetting = null;
   private ManagedObjectReference dcMor = null;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      VmwareUplinkPortTeamingPolicy uplinkPolicy = null;
      Map<String, Object> settingsMap = null;
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      dcMor = iFolder.getDataCenter();
      assertNotNull(dcMor, DC_MOR_GET_PASS, DC_MOR_GET_FAIL);
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(getTestId());
      log.info("Creating DVS {}", dvsConfigSpec.getName());
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
      assertNotNull(dvsMor, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      dvPortgroupConfigSpec.setConfigVersion("");
      dvPortgroupConfigSpec.setName(getTestId() + "-pg1");
      dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
      dvPortgroupConfigSpec.setNumPorts(1);
      dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      dvPortSetting = new VMwareDVSPortSetting();
      uplinkPolicy = DVSUtil.getUplinkPortTeamingPolicy(false,
               "loadbalance_ip", true, true, true, null, null);
      settingsMap = new HashMap<String, Object>();
      settingsMap.put(DVSTestConstants.UPLINK_TEAMING_POLICY_KEY, uplinkPolicy);
      dvPortSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
      dvPortgroupConfigSpec.setDefaultPortConfig(dvPortSetting);
      status = true;
      assertTrue(status, "Setup failed");
      return status;
   }

   @Override
   @Test(description = "Add a portgroup to an existing"
            + "distributed virtual switch with a valid "
            + "uplinkteaming policy")
   public void test()
      throws Exception
   {
      dvPortgroupMors = iDVSwitch.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec });
      assertNotEmpty(dvPortgroupMors, "Successfully added DVPortgroups",
               "Failed to add DVPortgroups");
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      final boolean status = iManagedEntity.destroy(dvsMor);
      assertTrue(status, "Cleanup failed");
      return status;
   }
}

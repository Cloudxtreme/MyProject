/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.PVLAN_TYPE_PROMISCUOUS;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.VLAN_KEY;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Remove a PVLAN map entry by providing a PVLAN ID which is used by a
 * DVPortgroupConfigSpec of a DVPortgroup.
 */
public class Neg034 extends PvlanBase
{
   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Remove a PVLAN map entry by providing a PVLAN ID "
               + "which is used by a DVPortgroupConfigSpec of a DVPortgroup.");
   }

   /**
    * Test setup.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualPortgroup iDVPortgroup = null;
      // VMwareDVSConfigSpec configSpec = null;
      VMwareDVSPortSetting defaultSetting = null;
      VmwareDistributedVirtualSwitchPvlanSpec aPvlan = null;
      List<ManagedObjectReference> portGroups = null;
      Map<String, Object> settingsMap = null;
     
         if (super.testSetUp()) {
            iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            if (iDVPortgroup != null && dvsMor != null) {
               if (iVmwareDVS.addPrimaryPvlan(dvsMor, PVLAN1_PRI_1)) {
                  log.info("Add the PLVAN to DefaultPortConfig of DVPortgroup");
                  aPvlan = new VmwareDistributedVirtualSwitchPvlanSpec();
                  aPvlan.setPvlanId(PVLAN1_PRI_1);
                  settingsMap = new HashMap<String, Object>();
                  settingsMap.put(VLAN_KEY, aPvlan);
                  defaultSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
                  // add DVPortgroup
                  DVPortgroupConfigSpec cfg = new DVPortgroupConfigSpec();
                  cfg.setName(getTestId() + "-PG");
                  cfg.setType(DVPORTGROUP_TYPE_LATE_BINDING);
                  cfg.setNumPorts(1);
                  cfg.setDefaultPortConfig(defaultSetting);
                  portGroups = iVmwareDVS.addPortGroups(dvsMor,
                           new DVPortgroupConfigSpec[] { cfg });
                  if (portGroups != null) {
                     status = true;
                  }
               }
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Remove a PVLAN map entry by providing a PVLAN ID "
               + "which is used by a DVPortgroupConfigSpec of a DVPortgroup.")
   public void test()
      throws Exception
   {
      boolean status = false;
      MethodFault expectedFault = new InvalidArgument();
      try {
         iVmwareDVS.removePvlan(dvsMor, PVLAN_TYPE_PROMISCUOUS, PVLAN1_PRI_1,
                  PVLAN1_PRI_1, true);
         log.error("API didn't throw any exception.");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         status = TestUtil.checkMethodFault(actualMethodFault, expectedFault);
      }
      if (!status) {
         log.error("API didn't throw expected exception: "
                  + expectedFault.getClass().getSimpleName());
      }
      assertTrue(status, "Test Failed");
   }
}

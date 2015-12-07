/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.PVLAN_TYPE_PROMISCUOUS;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.util.TestUtil;

/**
 * Remove a PVLAN map entry by providing a PVLAN ID which is used by a DVS
 * default config.
 */
public class Neg033 extends PvlanBase
{
   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Remove a PVLAN map entry by providing a PVLAN ID "
               + "which is used by a DVS default config.");
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
      VMwareDVSConfigInfo cfgInfo = null;
      VMwareDVSConfigSpec configSpec = null;
      VMwareDVSPortSetting defaultSetting = null;
      VmwareDistributedVirtualSwitchPvlanSpec aPvlan = null;
     
         if (super.testSetUp()) {
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            if (dvsMor != null) {
               if (iVmwareDVS.addPrimaryPvlan(dvsMor, PVLAN1_PRI_1)) {
                  log.info("Add the PLVAN to DefaultPortConfig ");
                  cfgInfo = iVmwareDVS.getConfig(dvsMor);
                  configSpec = new VMwareDVSConfigSpec();
                  aPvlan = new VmwareDistributedVirtualSwitchPvlanSpec();
                  aPvlan.setPvlanId(PVLAN1_PRI_1);
                  aPvlan.setInherited(false);
                  defaultSetting = (VMwareDVSPortSetting) cfgInfo.getDefaultPortConfig();
                  defaultSetting.setVlan(aPvlan);
                  configSpec.setConfigVersion(cfgInfo.getConfigVersion());
                  configSpec.setDefaultPortConfig(defaultSetting);
                  status = iVmwareDVS.reconfigure(dvsMor, configSpec);
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
               + "which is used by a DVS default config.")
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

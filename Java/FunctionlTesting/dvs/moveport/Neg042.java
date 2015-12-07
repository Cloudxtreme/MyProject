/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a DVPort from an early biding DVPortgroup having valid inShapingPolicy
 * and outShapingPolicy in it's default settings to a early binding DVPortgroup
 * with settingShapingOverrideAllowed=false. Procedure: Setup: 1. Create a DVS.
 * 2. Create an early binding DVPortgroup having valid inShapingPolicy and
 * outShapingPolicy. 3. Create another early binding DVPorgroup with
 * ShapingOverrideAllowed=false. Test: 4. Move the DVPort from first to second
 * DVPortgroup. Cleanup: 5. Delete the DVS.
 */
public class Neg042 extends MovePortBase
{
   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort from an early biding DVPortgroup "
               + "having valid inShapingPolicy and outShapingPolicy in it's "
               + "default settings to a early binding DVPortgroup with "
               + "settingShapingOverrideAllowed=false.");
   }

   /**
    * Test setup.
    *
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, if test setup was successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      List<String> portgroupKeys = null;
      DVPortgroupConfigSpec aPortGroupCfg = null;
      DVPortgroupPolicy policy = null;
      DVPortSetting setting = null;
      DVPortConfigSpec portCfg = null;
      Map<String, Object> settingsMap = null;
      DVSTrafficShapingPolicy shapingPolicy = null;

         if (super.testSetUp()) {
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            shapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true, 1024L,
                     null, null);
            settingsMap = new HashMap<String, Object>();
            settingsMap.put(DVSTestConstants.INSHAPING_POLICY_KEY,
                     shapingPolicy);
            settingsMap.put(DVSTestConstants.OUT_SHAPING_POLICY_KEY,
                     shapingPolicy);
            if (iDVSwitch.getConfig(dvsMor).getDefaultPortConfig() instanceof VMwareDVSPortSetting) {
               setting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
            } else {
               setting = DVSUtil.getDefaultPortSetting(settingsMap, null);
            }
            log.info("Creating DVPortgroup with valid shapping policy in "
                     + "default port config.");
            policy = new DVPortgroupPolicy();
            policy.setShapingOverrideAllowed(true);
            aPortGroupCfg = buildDVPortgroupCfg(DVPORTGROUP_TYPE_EARLY_BINDING,
                     1, policy, null);
            aPortGroupCfg.setDefaultPortConfig(setting);
            portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
            if ((portgroupKeys != null) && !portgroupKeys.isEmpty()) {
               log.info("Added late binding DVPortgroup.");
               log.info("Get the DVPort to be moved...");
               portKeys = fetchPortKeys(dvsMor, portgroupKeys.get(0));
               if ((portKeys != null) && !portKeys.isEmpty()) {
                  log.info("Got it DVPort to be moved: " + portKeys);
                  portCfg = new DVPortConfigSpec();
                  portCfg.setKey(portKeys.get(0));
                  portCfg.setSetting(setting);
                  portCfg.setOperation(CONFIG_SPEC_EDIT);
                  if (iDVSwitch.reconfigurePort(dvsMor,
                           new DVPortConfigSpec[] { portCfg })) {
                     log.info("Successfully set value for ShapingPolicy "
                              + "for DVPort: " + portKeys);
                     log.info("Creating destination DVPortgroup... With policy "
                              + "ShapingOverrideAllowed=false");
                     policy = new DVPortgroupPolicy();
                     policy.setShapingOverrideAllowed(false);
                     aPortGroupCfg = buildDVPortgroupCfg(
                              DVPORTGROUP_TYPE_EARLY_BINDING, 0, policy, null);
                     portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
                     if ((portgroupKeys != null) && !portgroupKeys.isEmpty()) {
                        portgroupKey = portgroupKeys.get(0);
                        status = true;
                     } else {
                        log.error("Failed to create destination DVPortgroup.");
                     }
                  }
               } else {
                  log.error("Failed to get the DVPort from added DVPortgroup.");
               }
            }
         } else {
            log.error("Unable to login.");
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
   @Test(description = "Move a DVPort from an early biding DVPortgroup "
               + "having valid inShapingPolicy and outShapingPolicy in it's "
               + "default settings to a early binding DVPortgroup with "
               + "settingShapingOverrideAllowed=false.")
   public void test()
      throws Exception
   {
      boolean status = false;
      final MethodFault expectedFault = new InvalidArgument();
      try {
         movePort(dvsMor, portKeys, portgroupKey);
         log.error("API didn't throw any exception.");
      } catch (final Exception actualMethodFaultExcep) {
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

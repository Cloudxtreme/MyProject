/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.TestConstants.CONFIG_SPEC_EDIT;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

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
 * Move a DVPort which has Settings with valid inShapingPolicy and
 * OutShapingPolicy to a late binding DVPortgroup with
 * settingShapingOverrideAllowed=false.
 */
public class Neg039 extends MovePortBase
{
   DVSTrafficShapingPolicy shapingPolicy = null;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort which has Settings with valid "
               + "inShapingPolicy and OutShapingPolicy to a late binding "
               + "DVPortGroup with settingShapingOverrideAllowed=false.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create late binding DVPortgroup with
    * ShapingOverrideAllowed=false. 3. Create a standalone DVPort and
    * reconfigure it to set valid inShapingPolicy and OutShapingPolicy and use
    * it as the port to be moved.
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
      DVPortSetting setting = null;
      Map<String, Object> settingsMap = null;
     
         if (super.testSetUp()) {
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            /* Add early binding port group. */
            DVPortgroupPolicy policy = null;
            policy = new DVPortgroupPolicy();
            policy.setShapingOverrideAllowed(false);
            log.info("Adding a late binding DVPortgroup with "
                     + "OutShapingPolicy =null in DefaultPortConfig...");
            aPortGroupCfg = buildDVPortgroupCfg(DVPORTGROUP_TYPE_LATE_BINDING,
                     1, policy, null);
            portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
            if (portgroupKeys != null) {
               log.info("Added late binding DVPortgroup.");
               portgroupKey = portgroupKeys.get(0);// use this as destination.
               // Now create a port and set the shaping to some value.
               portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
               if (portKeys != null) {
                  log.info("Added a standalone DVPort to DVS.");
                  DVPortConfigSpec portCfg = null;
                  shapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
                           1024L, null, null);
                  settingsMap = new HashMap<String, Object>();
                  settingsMap.put(DVSTestConstants.INSHAPING_POLICY_KEY,
                           shapingPolicy);
                  settingsMap.put(DVSTestConstants.OUT_SHAPING_POLICY_KEY,
                           shapingPolicy);
                  if (this.iDVSwitch.getConfig(this.dvsMor).getDefaultPortConfig() instanceof VMwareDVSPortSetting) {
                     setting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
                  } else {
                     setting = DVSUtil.getDefaultPortSetting(settingsMap, null);
                  }
                  portCfg = new DVPortConfigSpec();
                  portCfg.setKey(portKeys.get(0));
                  portCfg.setSetting(setting);
                  portCfg.setOperation(CONFIG_SPEC_EDIT);
                  if (iDVSwitch.reconfigurePort(dvsMor,
                           new DVPortConfigSpec[] { portCfg })) {
                     log.info("Successfully set value for outShapingPolicy.");
                     status = true;
                  } else {
                     log.info("Failed to set the policy to port.");
                  }
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
   @Test(description = "Move a DVPort which has Settings with valid "
               + "inShapingPolicy and OutShapingPolicy to a late binding "
               + "DVPortGroup with settingShapingOverrideAllowed=false.")
   public void test()
      throws Exception
   {
      boolean status = false;
      MethodFault expectedFault = new InvalidArgument();
      try {
         movePort(dvsMor, portKeys, portgroupKey);
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

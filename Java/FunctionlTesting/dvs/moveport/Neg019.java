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
import com.vmware.vc.DVSVendorSpecificConfig;
import com.vmware.vc.DistributedVirtualSwitchKeyedOpaqueBlob;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a DVPort with valid blob data to a late binding DVPortGroup with
 * settingVendorConfigOverrideAllowed=false and livePortMovingAllowed=true.
 */
public class Neg019 extends MovePortBase
{
   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort with valid blob data to a late "
               + "binding DVPortGroup with "
               + "settingVendorConfigOverrideAllowed=false "
               + "and livePortMovingAllowed=true.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create late binding DVPortgroup with
    * ShapingOverrideAllowed=false and settingShapingOverrideAllowed=true 3.
    * Create a standalone DVPort and reconfigure it to set valid
    * outShapingPolicy and use it as the port to be moved.
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
      DVSVendorSpecificConfig vendorSpecificConfig = null;
      Map<String, Object> settingsMap = null;
     
         if (super.testSetUp()) {
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            DVPortgroupPolicy policy = null;
            policy = new DVPortgroupPolicy();
            policy.setVendorConfigOverrideAllowed(false);
            policy.setLivePortMovingAllowed(true);
            log.info("Adding a late binding DVPortgroup...");
            aPortGroupCfg = buildDVPortgroupCfg(DVPORTGROUP_TYPE_LATE_BINDING,
                     1, policy, null);
            portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
            if (portgroupKeys != null) {
               log.info("Added late binding DVPortgroup.");
               portgroupKey = portgroupKeys.get(0);// use this as destination.
               // Now create a port and set the shaping to some valid value.
               portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
               if (portKeys != null) {
                  log.info("Added a standalone DVPort to DVS.");
                  DVPortConfigSpec portCfg = null;
                  // TODO need to check whether this is valid blob.
                  DistributedVirtualSwitchKeyedOpaqueBlob[] blob = new DistributedVirtualSwitchKeyedOpaqueBlob[1];
                  blob[0] = new DistributedVirtualSwitchKeyedOpaqueBlob();
                  blob[0].setKey("test");
                  blob[0].setOpaqueData("data");
                  vendorSpecificConfig = new DVSVendorSpecificConfig();
                  vendorSpecificConfig.setInherited(false);
                  vendorSpecificConfig.getKeyValue().clear();
                  vendorSpecificConfig.getKeyValue().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(blob));
                  settingsMap = new HashMap<String, Object>();
                  settingsMap.put(DVSTestConstants.VENDOR_SPECIFIC_CONFIG_KEY,
                           vendorSpecificConfig);
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
   @Test(description = "Move a DVPort with valid blob data to a late "
               + "binding DVPortGroup with "
               + "settingVendorConfigOverrideAllowed=false "
               + "and livePortMovingAllowed=true.")
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

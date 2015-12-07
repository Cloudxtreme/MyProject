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
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

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
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a DVPort which has Settings with inShapingPolicy, to an early binding
 * DVPortGroup with defaultPortConfig.inShapingPolicy is set to null and with
 * settingShapingOverrideAllowed=true. This test is a Functional Feature
 * Acceptance Test (FFAT).
 */
public class Pos025 extends MovePortBase
{
   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort which has Settings with "
               + "inShapingPolicy, to an early binding DVPortGroup with "
               + "defaultPortConfig.inShapingPolicy is set to null and with "
               + "settingShapingOverrideAllowed=true.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create early binding DVPortgroup with
    * InShapingPolicy=null and ShapingOverrideAllowed=true. 3. Create standalone
    * DVPort and reconfigure it to set InShapingPolicy. 4. Use the standalone
    * DVPort as the port to be moved. 5. Use the key of the early binding
    * DVPortgroup as destination.
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
      DVPortgroupPolicy policy = null;// used to set 'LivePortMovingAllowed'.
      Map<String, Object> settingsMap = null;
     
         if (super.testSetUp()) {
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            /* Add early binding port group. */
            policy = new DVPortgroupPolicy();
            policy.setShapingOverrideAllowed(true);
            // set inShapingPolicy of DVPortgroup to null explicitly.
            setting = new DVPortSetting();
            setting.setInShapingPolicy(null);
            aPortGroupCfg = buildDVPortgroupCfg(DVPORTGROUP_TYPE_EARLY_BINDING,
                     1, policy, null);
            aPortGroupCfg.setDefaultPortConfig(setting);
            portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
            if (portgroupKeys != null) {
               log.info("Added early bind port group.");
               portgroupKey = portgroupKeys.get(0);// use this as destination.
               // Now create a port and set the shaping to some value.
               portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
               if (portKeys != null) {
                  log.info("Added a standalone DVPort to DVS.");
                  DVSTrafficShapingPolicy inShapingPolicy = null;
                  DVPortConfigSpec portCfg = null;
                  // Set the inShapingPolicy to the source port.
                  inShapingPolicy = DVSUtil.getTrafficShapingPolicy(false,
                           true, 1024L, null, null);
                  settingsMap = new HashMap<String, Object>();
                  settingsMap.put(DVSTestConstants.INSHAPING_POLICY_KEY,
                           inShapingPolicy);
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
                     log.info("Successfully set value for InShapingPolicy.");
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
   @Test(description = "Move a DVPort which has Settings with "
               + "inShapingPolicy, to an early binding DVPortGroup with "
               + "defaultPortConfig.inShapingPolicy is set to null and with "
               + "settingShapingOverrideAllowed=true.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         Map<String, DistributedVirtualPort> connectedEntitiespMap = DVSUtil.getConnecteeInfo(
                  connectAnchor, dvsMor, portKeys);
         status = movePort(dvsMor, portKeys, portgroupKey);
         status &= DVSUtil.verifyConnecteeInfoAfterMovePort(connectAnchor,
                  connectedEntitiespMap, dvsMor, portKeys, portgroupKey);
     
      assertTrue(status, "Test Failed");
   }
}

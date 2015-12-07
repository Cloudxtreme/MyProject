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
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a DVPort which has Settings with outShapingPolicy, to a late binding
 * DVPortGroup with defaultPortConfig.outShapingPolicy set to null and with
 * settingShapingOverrideAllowed=true.
 */
public class Pos026 extends MovePortBase
{
   DVSTrafficShapingPolicy outShapingPolicy = null;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort which has Settings with "
               + "outShapingPolicy, to a late binding DVPortGroup with "
               + "defaultPortConfig.outShapingPolicy set to null and with "
               + "settingShapingOverrideAllowed=true.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create early binding DVPortgroup with
    * outShapingPolicy=null and ShapingOverrideAllowed=true and use it as
    * destination. 3. Create a standalone DVPort and reconfigure it to set valid
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
      Map<String, Object> settingsMap = null;
     
         if (super.testSetUp()) {
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            /* Add early binding port group. */
            DVPortgroupPolicy policy = null;
            policy = new DVPortgroupPolicy();
            policy.setShapingOverrideAllowed(true);
            log.info("Adding a early binding DVPortgroup with "
                     + "OutShapingPolicy =null in DefaultPortConfig...");
            aPortGroupCfg = buildDVPortgroupCfg(DVPORTGROUP_TYPE_EARLY_BINDING,
                     1, policy, null);
            portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
            if (portgroupKeys != null) {
               log.info("Added early bind port group.");
               portgroupKey = portgroupKeys.get(0);// use this as destination.
               // Now create a port and set the shaping to some value.
               portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
               if (portKeys != null) {
                  log.info("Added a standalone DVPort to DVS.");
                  DVPortConfigSpec portCfg = null;
                  // Set the inShapingPolicy to the source port.
                  this.outShapingPolicy = DVSUtil.getTrafficShapingPolicy(
                           false, true, 1024L, null, null);
                  settingsMap = new HashMap<String, Object>();
                  settingsMap.put(DVSTestConstants.OUT_SHAPING_POLICY_KEY,
                           this.outShapingPolicy);
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
               } else {
                  log.error("Can not add the standalone port to the key");
               }
            } else {
               log.error("Can not add the portgroup");
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
               + "outShapingPolicy, to a late binding DVPortGroup with "
               + "defaultPortConfig.outShapingPolicy set to null and with "
               + "settingShapingOverrideAllowed=true.")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<DistributedVirtualPort> ports = null;
     
         Map<String, DistributedVirtualPort> connectedEntitiespMap = DVSUtil.getConnecteeInfo(
                  connectAnchor, dvsMor, portKeys);
         if (movePort(dvsMor, portKeys, portgroupKey)) {
            status = DVSUtil.verifyConnecteeInfoAfterMovePort(connectAnchor,
                     connectedEntitiespMap, dvsMor, portKeys, portgroupKey);
            portCriteria = iDVSwitch.getPortCriteria(null, null, null, null,
                     portKeys.toArray(new String[portKeys.size()]), null);
            ports = iDVSwitch.fetchPorts(dvsMor, portCriteria);
            if ((ports != null) && !ports.isEmpty()) {
               DistributedVirtualPort port = ports.get(0);
               if ((port.getConfig() != null)
                        && (port.getConfig().getSetting() != null)) {
                  if ((port.getConfig().getSetting().getOutShapingPolicy().getAverageBandwidth().isInherited() == false)
                           && outShapingPolicy.getAverageBandwidth().getValue() == (port.getConfig().getSetting().getOutShapingPolicy().getAverageBandwidth().getValue())) {
                     status = true;
                  } else {
                     log.error("outShapingPolicies doesnot match.");
                  }
               } else {
                  log.error("No Setting found.");
               }
            } else {
               log.error("Could not find DVport");
            }
         }
     
      assertTrue(status, "Test Failed");
   }
}

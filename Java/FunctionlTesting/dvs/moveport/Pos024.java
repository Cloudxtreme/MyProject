/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a DVPort (not bound to any VM) which doesn't have any Settings to a late
 * binding DVPortGroup with defaultPortConfig.blocked=false.
 */
public class Pos024 extends MovePortBase
{
   /* defaultPortConfig value set to false */
   private Boolean blocked = new Boolean(false);

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort (not bound to any VM) which doesn\'t "
               + "have any Settings to a late binding DVPortGroup with "
               + "defaultPortConfig.blocked=false.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create a standalone DVPort. 3. Create late
    * binding DVPortgroup with defaultPortConfig.blocked=false. 4. Use the
    * standalone DVPort as the port to be moved. 5. Use the key of the late
    * binding DVPortgroup as destination.
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
            if (dvsMor != null) {
               portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
               if ((portKeys != null) && !portKeys.isEmpty()) {
                  // create a late binding PG with blocked=false.
                  settingsMap = new HashMap<String, Object>();
                  settingsMap.put(DVSTestConstants.BLOCKED_KEY, this.blocked);
                  if (this.iDVSwitch.getConfig(this.dvsMor).getDefaultPortConfig() instanceof VMwareDVSPortSetting) {
                     setting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
                  } else {
                     setting = DVSUtil.getDefaultPortSetting(settingsMap, null);
                  }
                  aPortGroupCfg = buildDVPortgroupCfg(
                           DVPORTGROUP_TYPE_LATE_BINDING, 1, null, null);
                  aPortGroupCfg.setDefaultPortConfig(setting);
                  portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
                  if ((portgroupKeys != null) && !portgroupKeys.isEmpty()) {
                     portgroupKey = portgroupKeys.get(0);
                     status = true;
                  } else {
                     log.error("failed to create destination DVPortgroup.");
                  }
               } else {
                  log.error("Failed to create standalone DVPort.");
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
   @Test(description = "Move a DVPort (not bound to any VM) which doesn\'t "
               + "have any Settings to a late binding DVPortGroup with "
               + "defaultPortConfig.blocked=false.")
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
               DVPortSetting effectiveSetting = null;
               DistributedVirtualPort port = ports.get(0);
               effectiveSetting = port.getConfig().getSetting();
               log.info("Effective DVPort setting: " + effectiveSetting);
               if (effectiveSetting != null) {
                  if (blocked.equals(effectiveSetting.getBlocked())
                           || effectiveSetting.getBlocked().isInherited()) {
                     status = true;
                  } else {
                     log.error("DVport setting for 'blocked' is not matching.");
                  }
               } else {
                  log.error("No Effective setting found.");
               }
            } else {
               log.error("Could not find DVport");
            }
         }
     
      assertTrue(status, "Test Failed");
   }
}

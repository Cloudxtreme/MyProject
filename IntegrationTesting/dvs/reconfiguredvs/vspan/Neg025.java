/* ************************************************************************
 *
 * Copyright 2010-2011 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.util.Assert.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigInfo;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSSecurityPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VspanPortMoveFault;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Move a port which is used as Tx source to a PG with promiscuous enabled and
 * expect that VspanPortMoveFault is thrown.
 **/
public class Neg025 extends VspanTestBase
{
   String dvPort;
   String pgKey;
   private List<ManagedObjectReference> dvpgs = null;

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      final VMwareVspanPort srcTx;
      dvsMor = folder.createDistributedVirtualSwitch(dvsName);
      final List<String> ports = vmwareDvs.addStandaloneDVPorts(dvsMor, 1);
      assertNotEmpty(ports, "Added standalone port",
               "Failed to add standalone port");
      dvPort = ports.get(0);
      log.info("Adding VSPAN session with a port '{}' mirrored for Tx ", dvPort);
      srcTx = VspanHelper.buildVspanPort(dvPort, null, null);
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      vspanCfg[0] = new VMwareDVSVspanConfigSpec();
      vspanCfg[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      vspanCfg[0].setVspanSession(VspanHelper.buildVspanSession(getTestId(),
               srcTx, null, null));
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfig(dvsMor).getConfigVersion());
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      Assert.assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "successfully added VSPAN session",
               "Failed to add vspan session.");
      log.info("Adding a DVPortgroup with promiscuous mode enabled.");
      VMwareDVSPortSetting dvPortSetting = null;
      DVSSecurityPolicy secPolicy = null;
      Map<String, Object> settingsMap = null;
      dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      dvPortgroupConfigSpec.setConfigVersion("");
      dvPortgroupConfigSpec.setName(getTestId());
      dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
      dvPortgroupConfigSpec.setNumPorts(1);
      dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      secPolicy = DVSUtil.getDVSSecurityPolicy(false, true, null, null);
      settingsMap = new HashMap<String, Object>();
      settingsMap.put(DVSTestConstants.SECURITY_POLICY_KEY, secPolicy);
      dvPortSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
      dvPortgroupConfigSpec.setDefaultPortConfig(dvPortSetting);
      dvpgs = vmwareDvs.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec });
      assertNotEmpty(dvpgs, "Added DVPortgroup with promiscuous mode enabled.",
               "Failed to add DVPortgroup woth promiscuous mode enabled");
      final DVPortgroupConfigInfo cfgInfo = dvpg.getConfigInfo(dvpgs.get(0));
      pgKey = cfgInfo.getKey();
      //
      return true;
   }

   @Test(description = "Move a port which is used as Tx source to a PG with promiscuous "
            + "enabled and expect that VspanPortMoveFault is "
            + "thrown")
   @Override
   public void test()
      throws Exception
   {
      try {
         log.info("Move ports {} to PG {} Should fail...", dvPort, pgKey);
         vmwareDvs.movePort(dvsMor, new String[] { dvPort }, pgKey);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new VspanPortMoveFault();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   @AfterMethod(alwaysRun = true)
   @Override
   public boolean testCleanUp()
      throws Exception
   {
      boolean done = true;
      log.info("Destroying the DVS: {} ", dvsName);
      done &= destroy(dvsMor);
      return done;
   }
}

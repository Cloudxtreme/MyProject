/* ************************************************************************
 *
 * Copyright 2010-2011 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.util.Assert.*;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSSecurityPolicy;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VspanPortPromiscChangeFault;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Enable promiscuous mode to a DVPort which is VSPAN destination and expect
 * VspanPortPromiscChangeFault exception.
 **/
public class Neg031 extends VspanTestBase
{
   VMwareDVSConfigInfo info;
   String dvPort;

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      final VMwareVspanPort dest;
      hostMor = hs.getConnectedHost(false);
      dvsMor = createDVSWithNic(dvsName, hostMor);
      //
      final List<String> ports = vmwareDvs.addStandaloneDVPorts(dvsMor, 1);
      assertNotEmpty(ports, "Added standslone port",
               "Failed to add standalone port");
      dvPort = ports.get(0);
      log.info("Adding VSPAN session with a port '{}' mirrored for Tx ", dvPort);
      dest = VspanHelper.buildVspanPort(dvPort, null, null);
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      vspanCfg[0] = new VMwareDVSVspanConfigSpec();
      vspanCfg[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      vspanCfg[0].setVspanSession(VspanHelper.buildVspanSession(getTestId(),
               null, null, dest));
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfig(dvsMor).getConfigVersion());
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      Assert.assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "Successfully added VSPAN session",
               "Failed to add vspan session.");
      return true;
   }

   @Test(description = "Enable promiscuous mode to a DVPort which "
            + "is mirrored for tx source and expect "
            + "VspanPortPromiscChangeFault exception.")
   @Override
   public void test()
      throws Exception
   {
      try {
         final DVPortConfigSpec configSpec = new DVPortConfigSpec();
         configSpec.setKey(dvPort);
         configSpec.setOperation(ConfigSpecOperation.EDIT.value());
         VMwareDVSPortSetting setting = null;
         setting = DVSUtil.getDefaultVMwareDVSPortSetting(null);
         DVSSecurityPolicy securityPolicy = null;
         securityPolicy = DVSUtil.getDVSSecurityPolicy(false, Boolean.FALSE,
                  Boolean.FALSE, Boolean.FALSE);
         securityPolicy.setAllowPromiscuous(DVSUtil.getBoolPolicy(false,
                  Boolean.TRUE));
         setting.setSecurityPolicy(securityPolicy);
         configSpec.setSetting(setting);
         vmwareDvs.reconfigurePort(dvsMor, new DVPortConfigSpec[] { configSpec });
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new VspanPortPromiscChangeFault();
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

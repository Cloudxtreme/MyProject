/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Add a VSPAN session by providing invalid operation.<br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS.<br>
 * TEST:<br>
 * 2. Reconfigure the DVS with Invalid operation in VSPAN Config spec.<br>
 * 3. Verify that InvalidArgument exception is thrown.<br>
 * CLEANUP:<br>
 * 4. Destroy the DVS<br>
 */
public class Neg004 extends VspanTestBase
{
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a VSPAN session by providing invalid operation.");
   }

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      dvsMor = folder.createDistributedVirtualSwitch(dvsName);
      return true;
   }

   @Test(description = "Add a VSPAN session by providing invalid operation.")
   @Override
   public void test()
      throws Exception
   {
      try {
         final DVSConfigInfo cfgInfo = vmwareDvs.getConfig(dvsMor);
         dvsReCfg = new VMwareDVSConfigSpec();
         dvsReCfg.setConfigVersion(cfgInfo.getConfigVersion());
         vspanCfg = new VMwareDVSVspanConfigSpec[1];
         vspanCfg[0] = new VMwareDVSVspanConfigSpec();
         vspanCfg[0].setOperation("INVALID_OPERATON");
         vspanCfg[0].setVspanSession(VspanHelper.buildVspanSession(getTestId(),
                  null, null, null));
         dvsReCfg.getVspanConfigSpec().clear();
         dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
         vmwareDvs.reconfigure(dvsMor, dvsReCfg);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidArgument();
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
      return vmwareDvs.destroy(dvsMor);
   }
}

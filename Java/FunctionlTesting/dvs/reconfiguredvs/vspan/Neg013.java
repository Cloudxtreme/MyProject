/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidArgument;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Edit a VSPAN session in a DVS by providing name containing >80 chars.
 */
public class Neg013 extends VspanTestBase implements IDataDrivenTest
{
   VMwareDVSConfigInfo info;
   VMwareVspanSession[] existingSessions;
   String name;

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    * @throws Exception
    */
   @Factory
   @Parameters( { "dataFile" })
   public Object[] getTests(@Optional("") final String dataFile)
      throws Exception
   {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }

   @Override
   public String getTestName()
   {
      return getTestId();
   }

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      name = data.getString("name");
      log.info("Given name: {}", name);
      dvsMor = folder.createDistributedVirtualSwitch(dvsName,
               hs.getConnectedHost(false));
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      final VMwareVspanPort sourcePortTx;
      setupPortgroups(dvsMor);
      final String port = VspanHelper.popPort(portGroups);
      sourcePortTx = VspanHelper.buildVspanPort(port, null, null );
      vspanCfg[0] = VspanHelper.buildVspanCfg(VspanHelper.buildVspanSession(
               getTestId(), sourcePortTx, null, null), CONFIG_SPEC_ADD);
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfig(dvsMor).getConfigVersion());
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "Failed to add VSPAN session");
      info = vmwareDvs.getConfig(dvsMor);
      existingSessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(info.getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
      assertNotEmpty(existingSessions, "Added VSPAN not found!");
      return true;
   }

   @Test(description = "Edit a VSPAN session in a DVS by providing name "
            + "containing >80 chars.")
   @Override
   public void test()
      throws Exception
   {
      try {
         VMwareDVSVspanConfigSpec[] recfgSpec = null;
         recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length];
         for (int i = 0; i < existingSessions.length; i++) {
            final VMwareVspanSession editSession = new VMwareVspanSession();
            editSession.setName(name);
            editSession.setKey(existingSessions[i].getKey());
            recfgSpec[i] = VspanHelper.buildVspanCfg(editSession, CONFIG_SPEC_EDIT);
            log.info("Session: {} {} ", i,
                     VspanHelper.toString(recfgSpec[i].getVspanSession()));
         }
         dvsReCfg = new VMwareDVSConfigSpec();
         dvsReCfg.setConfigVersion(info.getConfigVersion());
         dvsReCfg.getVspanConfigSpec().clear();
         dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(recfgSpec));
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

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return vmwareDvs.destroy(dvsMor);
   }
}

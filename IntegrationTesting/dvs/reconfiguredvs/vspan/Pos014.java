/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * EDIT a VSPAN session to DVS by providing different options for source port Tx
 * and Rx with destination as valid port key.<br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS & add host member to it using free pNIC.<br>
 * 2. Create 2 port groups with 2 ports each.<br>
 * 3. Get 2 VM's from the host and power them on.<br>
 * 4. Reconfigure each VM to use 2 ports of DVPortGroup.<br>
 * 5. Add VSPAN session to DVS to edit them.<br>
 * <br>
 * TEST:<br>
 * 6. Generate different combinations of VSPAN sessions using DVPorts with
 * destination as valid port key.<br>
 * 6. Reconfigure the DVS to EDIT the VSPAN sessions.<br>
 * 7. Verify that the VSPAN's are edited from VC & HOSTD.<br>
 * CLEANUP:<br>
 * 8. Restore the VMs to previous network config.<br>
 * 9. Destroy the DVS.<br>
 */
public class Pos014 extends VspanTestBase implements IDataDrivenTest
{
   VMwareVspanSession[] existingSessions;

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

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      getProperties();
      hostMor = hs.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_FAIL);
      dvsMor = createDVSWithNic(dvsName, hostMor);
      setupPortgroups(dvsMor);
      setupVMs(dvsMor);
      return true;
   }

   @Test(description = "Add a VSPAN session to the DVS by providing "
            + "different options for source port Tx and Rx with "
            + "destination as valid port key.")
   @Override
   public void test()
      throws Exception
   {
      // destination to be used for all sessions.
      final List<String> ports = vmwareDvs.addStandaloneDVPorts(dvsMor, 1);
      final VMwareVspanPort vspanPort = VspanHelper.buildVspanPort(
               ports.get(0), null, null);
      final VMwareDVSVspanConfigSpec[] specs = buildVspanCfgs(null, dvsMor);
      for (int i = 0; i < specs.length; i++) {
         log.info("Session: {}: {} ", i + 1,
                  VspanHelper.toString(specs[i].getVspanSession()));
         VMwareVspanSession[] existingSessions;
         // Add session without destination port.
         final VMwareDVSVspanConfigSpec[] aCfg = new VMwareDVSVspanConfigSpec[] { specs[i] };
         assertTrue(reconfigureVspan(dvsMor, aCfg), "Failed to ADD VSPAN.");
         final VMwareDVSConfigInfo cfgInfo = vmwareDvs.getConfig(dvsMor);
         existingSessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(cfgInfo.getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
         assertNotEmpty(existingSessions, "No Sessions found.");
         // Edit vspan session to set dest.
         final VMwareDVSVspanConfigSpec[] cfg = new VMwareDVSVspanConfigSpec[1];
         final VMwareVspanSession edit = new VMwareVspanSession();
         edit.setKey(existingSessions[0].getKey());
         edit.setName(existingSessions[0].getName() + "-edited");
         edit.setDestinationPort(vspanPort);
         cfg[0] = new VMwareDVSVspanConfigSpec();
         cfg[0].setOperation(CONFIG_SPEC_EDIT);
         cfg[0].setVspanSession(edit);
         assertTrue(reconfigureVspan(dvsMor, cfg), "Failed toEdit VSPAN.");
         existingSessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(cfgInfo.getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
         assertNotEmpty(existingSessions, "No Sessions found.");
         // Remove the session..
         final VMwareVspanSession remove = new VMwareVspanSession();
         remove.setKey(existingSessions[0].getKey());
         cfg[0] = new VMwareDVSVspanConfigSpec();
         cfg[0].setOperation(CONFIG_SPEC_REMOVE);
         cfg[0].setVspanSession(remove);
         assertTrue(reconfigureVspan(dvsMor, cfg),
                  "Successfully Removed VSPAN.");
      }
   }

   @AfterMethod(alwaysRun = true)
   @Override
   public boolean testCleanUp()
      throws Exception
   {
      boolean done = true;
      done &= cleanupVMs();
      log.info("Destroying the DVS: {} ", dvsName);
      done &= destroy(dvsMor);
      return done;
   }
}

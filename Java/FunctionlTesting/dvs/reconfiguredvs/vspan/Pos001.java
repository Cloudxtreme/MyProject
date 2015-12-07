/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.util.Assert.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.execution.TestExecutionUtils;

/**
 * DESCRIPTION:<br>
 * Add a VSPAN session to DVS by providing different options for source port Tx
 * and Rx with no destination options.<br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS & add host member to it using free pNIC.<br>
 * 2. Create 3 port groups with 2 ports each.<br>
 * 3. Get 3 VM's from the host and power them on.<br>
 * 4. Reconfigure each VM to use 2 ports of DVPortGroup.<br>
 * <br>
 * TEST:<br>
 * 5. Generate different combinations of VSPAN sessions using DVPorts with no
 * destination ports<br>
 * 6. Reconfigure the DVS to add the VSPAN sessions.<br>
 * 7. Verify that the VSPAN's are created from VC & HOSTD.<br>
 * CLEANUP:<br>
 * 8. Restore the VMs to previous network config.<br>
 * 9. Destroy the DVS.<br>
 */
public class Pos001 extends VspanTestBase implements IDataDrivenTest
{
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
      dvsMor = createDVSWithNic(dvsName, hostMor);
      setupPortgroups(dvsMor);
      setupVMs(dvsMor);
      return true;
   }

   @Test(description = "Add a VSPAN session to DVS by providing different "
            + "options for source port Tx and Rx with no destination options.")
   @Override
   public void test()
      throws Exception
   {
      assertTrue(reconfigureVspan(dvsMor, buildVspanCfgs(null, dvsMor)),
               "Failed to add VSPAN session.");
   }

   @AfterMethod(alwaysRun = true)
   @Override
   public boolean testCleanUp()
      throws Exception
   {
      boolean done = cleanupVMs();
      log.info("Destroying the DVS: {} ", dvsName);
      done &= destroy(dvsMor);
      return done;
   }
}

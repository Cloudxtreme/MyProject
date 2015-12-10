/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_STALONE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_STALONE_PASS;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVS as follows: <br>
 * - Set the DVSConfigSpec.configVersion to a valid config version string <br>
 * - Set the DVSConfigSpec.name to a valid string<br>
 * - Set DistributedVirtualSwitchHostMemberConfigSpec.operation to REMOVE <br>
 * - Set DistributedVirtualSwitchHostMemberConfigSpec.host to a valid hostMor<br>
 */
public class Pos049 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private ManagedObjectReference hostMor = null;
   private DVSConfigSpec deltaConfigSpec = null;

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      assertTrue(super.testSetUp(), "Base setup failed");
      this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
      assertNotNull(this.networkFolderMor, "Got network folder ",
               "Failed to get network folder");
      this.hostMor = ihs.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_STALONE_PASS, HOST_GET_STALONE_FAIL);
      this.configSpec = new DVSConfigSpec();
      this.configSpec.setName(this.getTestId());
      DistributedVirtualSwitchHostMemberConfigSpec[] initialHostCfgSpec;
      initialHostCfgSpec = new DistributedVirtualSwitchHostMemberConfigSpec[1];
      initialHostCfgSpec[0] =
               new DistributedVirtualSwitchHostMemberConfigSpec();
      initialHostCfgSpec[0].setHost(this.hostMor);
      initialHostCfgSpec[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      this.configSpec.getHost().clear();
      this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(initialHostCfgSpec));
      this.dvsMOR =
               this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
      assertNotNull(dvsMOR, "Successfully created DVS", "Failed to create DVS");
      this.deltaConfigSpec = new DVSConfigSpec();
      String validConfigVersion =
               this.iDistributedVirtualSwitch.getConfig(dvsMOR)
                        .getConfigVersion();
      this.deltaConfigSpec.setConfigVersion(validConfigVersion);
      initialHostCfgSpec[0].setOperation(TestConstants.CONFIG_SPEC_REMOVE);
      this.deltaConfigSpec.getHost().clear();
      this.deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(initialHostCfgSpec));
      return true;
   }

   /**
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Reconfigure an existing DVS as follows:\n"
            + "  - Set the DVSConfigSpec.configVersion to a valid config version"
            + " string\n"
            + "  - Set the DVSConfigSpec.name to a valid string\n"
            + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.operation to REMOVE\n"
            + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.host to a valid hostMor.")
   public void test()
      throws Exception
   {
      assertTrue(this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
               this.deltaConfigSpec), "Reconfiguration Successful",
               "Reconfiguration Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
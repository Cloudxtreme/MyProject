/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;

import dvs.CreateDVSTestBase;

/**
 * Create a DVS inside a valid nested folder with the following parameters set
 * in the config spec. DVSConfigSpec.configVersion is set to an empty string.
 * DVSConfigSpec.name is set to A string which contains both alphabetical,
 * numeric and special characters.
 */
public class Pos064 extends CreateDVSTestBase
{
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      assertTrue(super.testSetUp(), TB_SETUP_PASS, TB_SETUP_FAIL);
      networkFolderMor = iFolder.getNetworkFolder(dcMor);
      configSpec = new DVSConfigSpec();
      configSpec.setConfigVersion("");
      configSpec.setName(NAME_ALPHA_NUMERIC_SPECIAL_CHARS);
      return true;
   }

   @Override
   @Test(description = "Create a DVSwitch inside a valid nested "
            + "folder with the following parameters set in "
            + "the config spec: "
            + "1.DVSConfigSpec.configVersion is set to an " + "empty string."
            + "2.DVSConfigSpec.name is set to a string which "
            + "contains both alphabetical, numeric and "
            + "special characters.")
   public void test()
      throws Exception
   {
      log.info("Creating DVS with name {}", configSpec.getName());
      dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
               configSpec);
      assertNotNull(dvsMOR, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      assertTrue(iDistributedVirtualSwitch.validateDVSConfigSpec(dvsMOR,
               configSpec, null), "Failed to validate the DVS");
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      log.info("DVS MOR {}", dvsMOR);
      // In bug 612541 DVS used to get created but MOR was null so get it by
      // name for proper cleanup.
      if (dvsMOR == null) {
         log.info("Getting DVS by name {}", configSpec.getName());
         dvsMOR = iFolder.getDistributedVirtualSwitch(networkFolderMor,
                  configSpec.getName());
      }
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
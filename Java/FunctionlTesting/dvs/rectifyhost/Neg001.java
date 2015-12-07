/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.rectifyhost;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;

/**
 * DESCRIPTION:<br>
 * Invoke Rectifyhost api by passing DVS mo <br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS with host<br>
 * TEST:<br>
 * 2. Invoke Rectifyhost api by passing DVS mor<BR>
 * CLEANUP:<br>
 * 3. Destroy the DVS<br>
 */
public class Neg001 extends TestBase
{
   public static final Logger log = LoggerFactory.getLogger(Neg001.class);
   private ManagedObjectReference dvsMor = null;
   private Folder folder;
   private DistributedVirtualSwitch DVS;
   private String dvsName = null;


   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      this.folder = new Folder(connectAnchor);
      this.DVS = new DistributedVirtualSwitch(connectAnchor);
      dvsName = TestUtil.getShortTime() + "_DVS";
      dvsMor = folder.createDistributedVirtualSwitch(dvsName);
      assertNotNull(dvsMor, "Successfully created DVS: " + dvsName,
               "Failed to create DVS: " + dvsName);
       return true;
   }

   @Override
   @Test(description = "1. Create DVS\n"
            + "2. Invoke Rectifyhost api by passing DVS mor")
   public void test()
      throws Exception
   {
      try {
         assertTrue(this.DVS.rectifyHost(dvsMor,
                  new ManagedObjectReference[] { this.dvsMor }),
                  "Failed to rectifyHost");
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
      if (this.dvsMor != null) {
         assertTrue(this.DVS.destroy(this.dvsMor),
                  "Successfully Destroyed Vds", "Failed to destroy Vds");
      }
      return true;
   }
}
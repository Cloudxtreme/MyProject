/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.querycompatiblehostforexistingdvs;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidRequest;
import com.vmware.vc.InvalidType;
import com.vmware.vc.MethodFault;
import com.vmware.vc.MethodNotFound;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<br>
 * (queryCompatibleHostForExistingDvs  on hostmor ) <br>
 * TARGET: VC <br>
 * <br>
 * SETUP:<br>
 * TEST:<br>>
 * Invoke queryCompatibleHostForExistingDvs on hostmor<BR>
 * CLEANUP:<br>
 */
public class Neg001 extends TestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager DVS = null;
   private Folder folder = null;
   private HostSystem hostSystem = null;

   public void setTestDescription()
   {
      setTestDescription("queryCompatibleHostForExistingDvs  on hostmor");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      DVS = new DistributedVirtualSwitchManager(connectAnchor);
      folder = new Folder(connectAnchor);
      hostSystem = new HostSystem(connectAnchor);
      return true;
   }

   @Test(description = "queryCompatibleHostForExistingDvs  on hostmor")
   public void test()
      throws Exception
   {

      try {
         this.DVS
                  .queryCompatibleHostForExistingDVS(hostSystem
                           .getConnectedHost(null), this.folder.getDataCenter(),
                           true, null);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidRequest();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }

   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new MethodNotFound();
   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      return true;
   }
}

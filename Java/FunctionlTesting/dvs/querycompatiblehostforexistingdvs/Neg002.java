/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.querycompatiblehostforexistingdvs;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidLogin;
import com.vmware.vc.InvalidType;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.MethodNotFound;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<br>
 * (queryCompatibleHostForExistingDvs by passing hostmor instead of dvs mor.<br>
 * TARGET: VC <br>
 * <br>
 * SETUP:<br>
 * TEST:<br>>
 * Invoke queryCompatibleHostForExistingDvs method by passing container as
 * datacenter, recursive as true and hostmor.<BR>
 * CLEANUP:<br>
 */
public class Neg002 extends TestBase
{
   /*
    * private data variables
    */
   private Folder folder = null;
   private HostSystem hostSystem = null;
   private DistributedVirtualSwitchManager dsvManager = null;
   private ManagedObjectReference dvsManagerMor = null;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      dsvManager = new DistributedVirtualSwitchManager(connectAnchor);
      dvsManagerMor = dsvManager.getDvSwitchManager();
      folder = new Folder(connectAnchor);
      hostSystem = new HostSystem(connectAnchor);
      return true;
   }

   @Override
   @Test(description = "Invoke queryCompatibleHostForExistingDvs method by passing container as datacenter, recursive as true and  hostmor.")
   public void test()
      throws Exception
   {
      try {
         this.dsvManager.queryCompatibleHostForExistingDVS(dvsManagerMor,
                  this.folder.getDataCenter(), true, hostSystem
                           .getConnectedHost(null));
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidType();
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
      return true;
   }
}

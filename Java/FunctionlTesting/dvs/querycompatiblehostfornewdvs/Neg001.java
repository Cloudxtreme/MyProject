/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.querycompatiblehostfornewdvs;

import static com.vmware.vc.HostSystemConnectionState.CONNECTED;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.VersionConstants.ESX4x;

import java.util.Vector;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.InvalidType;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.MethodNotFound;
import com.vmware.vcqa.LogUtil;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * 1. Add two ESX4.5 hosts to datacenter 2. Invoke queryCompatibleHostForNewDvs
 * method by passing container as datacenter, recursive as true and
 * switchProductSpec as valid ProductSpec for the old vds version.
 */
public class Neg001 extends TestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager iDistributedVirtualSwitchManager = null;
   private ManagedObjectReference dvsManagerMor = null;
   private Folder iFolder = null;
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = new Vector<ManagedObjectReference>();

   public void setTestDescription()
   {
      setTestDescription("1. Add  two ESX4.5 hosts to datacenter\n"
               + "2.Invoke queryCompatibleHostForNewDvs on hostmor");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
   {
      boolean setupDone = false;
      try {
         iDistributedVirtualSwitchManager = new DistributedVirtualSwitchManager(
                  connectAnchor);
         iFolder = new Folder(connectAnchor);
         ihs = new HostSystem(connectAnchor);
         allHosts = ihs.getAllHost();
         if (allHosts != null && allHosts.size() > 0) {
            log.info("Found " + VersionConstants.ESX410 + " hosts ");
            dvsManagerMor = iDistributedVirtualSwitchManager.getDvSwitchManager();
            setupDone = true;
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      Assert.assertTrue(setupDone, "Setup failed");
      return setupDone;
   }

   @Test(description = "1. Add  two ESX4.5 hosts to datacenter\n"
               + "2.Invoke queryCompatibleHostForNewDvs on hostmor")
   public void test()
      throws Exception
   {
      try {
         DistributedVirtualSwitchProductSpec switchProductSpec = null;
         switchProductSpec = DVSUtil.getProductSpec(connectAnchor,
                  DVSTestConstants.VDS_VERSION_40);
         assertNotNull(switchProductSpec,
                  "Successfully obtained  the productSpec",
                  "Null returned for productSpec");
         LogUtil.printDetailedObject(switchProductSpec, ":");
         ManagedObjectReference[] hosts = this.iDistributedVirtualSwitchManager.queryCompatibleHostForNewDVS(
                  allHosts.get(0), this.iFolder.getDataCenter(), true,
                  switchProductSpec);
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

   /**
    * Setting the expected Exception.
    */
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

/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidType;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;

/**
 * Merge two dvswitches with both the dvswitch MORs set to a valid folder MOR
 */
public class Neg006 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference hostFolder = null;
   private ManagedObjectReference childFolder = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      log.info("Test setup Begin:");

         this.iFolder = new Folder(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            this.hostFolder = this.iFolder.getHostFolder(this.iDVSwitch.getDataCenter());
            if (this.hostFolder != null) {
               this.childFolder = this.iFolder.createFolder(this.hostFolder,
                        this.getTestId() + "-Folder");
               if (this.childFolder != null) {
                  status = true;
               } else {
                  log.error("Can not create the child folder inside the "
                           + "host folder");
               }
            } else {
               log.error("Can not find a host folder in the setup");
            }
         } else {
            log.error("Can not find a data center in the setup");
         }

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge two dvswitches with both the dvswitch MORs"
            + " set to a valid folder MOR")
   public void test()
      throws Exception
   {
      try {
         this.iDVSwitch.merge(this.hostFolder, this.childFolder);
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
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;

         if (this.childFolder != null) {
            status = this.iManagedEntity.destroy(this.childFolder);
         }

      assertTrue(status, "Cleanup failed");
      return status;
   }
}
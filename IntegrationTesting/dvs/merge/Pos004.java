/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Create two dvswitches with the following configuration: a. dest_numPort =
 * Valid Number greater than src_numPorts b. src_numPort = Valid Number Merge
 * the two dvswitches.
 */
public class Pos004 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolder = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DVSConfigSpec configSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dcMor = null;
   private int srcDvports = 0;
   private DVSConfigInfo destDvsConfigInfo = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Create two dvswitches with the following "
               + "configuration: a. dest_numPort = Valid Number greater than "
               + "src_numPorts b. src_numPort = Valid Number. "
               + "Merge the two dvswitches.");
   }

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
      String destDvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + this.getTestId() + DVSTestConstants.DVS_DESTINATION_SUFFIX;
      String srcDvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + this.getTestId() + DVSTestConstants.DVS_SOURCE_SUFFIX;

      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         this.rootFolder = this.iFolder.getRootFolder();
         if (this.rootFolder != null) {
            // create the destination dvs
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setConfigVersion("");
            this.configSpec.setName(destDvsName);
            this.configSpec.setNumStandalonePorts(DVSTestConstants.DVS_NUMPORTS);
            this.configSpec.setMaxPorts(DVSTestConstants.DVS_MAXNUMPORTS);
            destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), configSpec);
            // create the src dvs
            this.configSpec.setName(srcDvsName);
            srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), configSpec);
            // store the destn dvs config info for matching description
            // property
            if (srcDvsMor != null && destDvsMor != null) {
               log.info("Successfully created the source "
                        + "and destination distributed virtual " + "switches");
               DistributedVirtualSwitchPortCriteria portCriteria = this.iDVSwitch.getPortCriteria(
                        true, null, null, null, null, null);
               portCriteria.setUplinkPort(false);
               // get the dv ports for which host/vm nics are connected
               List<DistributedVirtualPort> dvports = this.iDVSwitch.fetchPorts(
                        this.srcDvsMor, portCriteria);
               // store the number of such ports
               if (dvports != null && !dvports.isEmpty()) {
                  this.srcDvports = dvports.size();
                  log.info("Src DVS connected DVPorts:"
                           + this.srcDvports);
               }
               this.destDvsConfigInfo = this.iDVSwitch.getConfig(this.destDvsMor);
               status = true;
            } else {
               log.error("Could not create the source or "
                        + "destination distributed virtual " + "switches");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create two dvswitches with the following "
               + "configuration: a. dest_numPort = Valid Number greater than "
               + "src_numPorts b. src_numPort = Valid Number. "
               + "Merge the two dvswitches.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the switches");
            if (this.iManagedEntity.isExists(srcDvsMor)) {
               log.error("Source DVS still exists.");
            } else {
               if (this.iDVSwitch.isExists(this.destDvsMor)) {
                  DVSConfigInfo mergedDVSConfigInfo = this.iDVSwitch.getConfig(destDvsMor);
                  if (mergedDVSConfigInfo != null) {
                     if (mergedDVSConfigInfo.getNumPorts() == (destDvsConfigInfo.getNumPorts() + this.srcDvports)) {
                        log.info("Merged numPorts count matched");
                        status = true;
                     } else {
                        log.error("Merged numPorts incorrect.");
                     }
                  } else {
                     log.error("Merged DVS config info is null.");
                  }
               } else {
                  log.error("Destn DVS does not exist.");
               }
            }
         } else {
            log.error("Failed to merge the switches");
         }
     
      assertTrue(status, "Test Failed");
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
     
         // check if src dvs exists
         if (this.iManagedEntity.isExists(this.srcDvsMor)) {
            // check if able to destroy it
            status = this.iManagedEntity.destroy(this.srcDvsMor);
         } else {
            status = true; // src does not exist, so set status as true
         }
         // check if destn dvs exists
         if (this.iManagedEntity.isExists(this.destDvsMor)) {
            // destroy the destn
            status &= this.iManagedEntity.destroy(this.destDvsMor);
         } else {
            status &= true; // the clean up is still true if destn is not
            // present
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
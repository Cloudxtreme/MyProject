/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional.storagevmotion;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.dvs.InternalDVSHelper;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.VmotionSystem;

import dvs.functional.FunctionalTestBase;

/**
 * Abstract base class to be used in the storage vmotion related dvs tests.
 */
public abstract class SVMFunctionalTestBase extends FunctionalTestBase
{
   protected VirtualMachineRelocateSpec vmRelocateSpec = null;
   protected boolean relocated = false;
   protected ManagedObjectReference dsMor = null;
   protected ManagedObjectReference vmMor = null;
   protected String vmName = null;
   protected String vnicDevice = null;
   protected VmotionSystem iVmotionSystem = null;
   protected ManagedObjectReference vmotionSystem = null;
   protected HostVirtualNicSpec originalVnicSpec = null;

   /**
    * Test method
    * 
    * @param connectAnchor Reference to the ConnectAnchor object
    */
   @Test
   public void test()
      throws Exception
   {
      boolean testPass = false;

     
         this.relocated = this.ivm.relocateVM(this.vmMor, this.vmRelocateSpec, VirtualMachineMovePriority.DEFAULT_PRIORITY, true);

         if (this.relocated) {
            log.info("Successfully relocated VM " + this.vmName);

            /*
             * Power off the VM
             */
            log.info("Powering off VM " + vmName);
            if (this.ivm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
               log.info("Successfully powered off VM " + vmName);

               /*
                * Power the VM on
                */
               log.info("Powering on VM " + vmName);
               if (this.ivm.powerOnVM(this.vmMor, null, false)) {
                  log.info("Successfully powered on VM " + vmName);
                  ConnectAnchor hostConnectAnchor = new ConnectAnchor(
                           this.ihs.getHostName(this.hostMor),
                           data.getInt(TestConstants.TESTINPUT_PORT));
                  assertTrue(InternalDVSHelper.verifyPortPersistenceLocation(
                           hostConnectAnchor, this.ivm.getName(this.vmMor),
                           this.dvSwitchUUID),
                           "Verification for PortPersistenceLocation failed");
                  DVSUtil.reconfigureWithTrafficShapingPolicy(connectAnchor,
                           this.dvsMor);
                  hostConnectAnchor = new ConnectAnchor(
                           this.ihs.getHostName(this.hostMor),
                           data.getInt(TestConstants.TESTINPUT_PORT));
                  assertTrue(InternalDVSHelper.verifyPortPersistenceLocation(
                           hostConnectAnchor, this.ivm.getName(this.vmMor),
                           this.dvSwitchUUID),
                           "Verification for PortPersistenceLocation failed");
                  testPass = true;
               } else {
                  log.error("Unable to power on VM " + vmName);
               }
            } else {
               log.error("VM " + vmName
                        + " did not power off successfully");
            }
         } else {
            log.error("Failed to relocate VM " + ivm.getName(this.vmMor));
         }

      assertTrue(testPass, "Test Failed");
   }

   /**
    * Method to restore the state, as it was, before setting up the test
    * environment.
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @return true, if test clean up was successful false, otherwise
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanupDone = true;
     
         if (this.vmMor != null) {
            if (this.ivm.getVMState(vmMor) == VirtualMachinePowerState.POWERED_ON) {
               this.ivm.powerOffVM(this.vmMor);
            }
            if (this.ivm.getVMState(this.vmMor) == VirtualMachinePowerState.POWERED_OFF) {
               log.info("Removing VM " + ivm.getName(this.vmMor));
               if (this.ivm.destroy(this.vmMor)) {
                  log.info("Successfully removed VM");
               } else {
                  log.warn("Failed to remove VM");
                  cleanupDone = false;
               }
            } else {
               log.warn("Failed to poweroff VM");
               cleanupDone = false;
            }
         }
         if (this.vnicDevice != null) {
            cleanupDone &= this.ins.removeVirtualNic(nwSystemMor, vnicDevice);
            if (cleanupDone) {
               log.info("Successfully remove the newly added vnicDevice");
            } else {
               log.error("Failed to remove the newly added vnicDevice");
            }
         }
         cleanupDone &= super.testCleanUp();

      assertTrue(cleanupDone, "Cleanup failed");
      return cleanupDone;
   }
}

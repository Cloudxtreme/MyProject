package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.Assert.assertNotNull;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachinePowerState;

public class T27 extends OpaqueNetworkBase
{
   private ManagedObjectReference firstHost = null;

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      /*
       * Init code for all entities in the inventory
       */
      initialize();
      /*
       * Find cluster which hosts are placed in
       */
      ClusterPreparation("NONE");
      /*
       * Get a usable vm.
       */
      getOneTestVm();
      /*
       * Prepare hosts, set firstHost and secondHost properly.
       */
      ManagedObjectReference hostMor = vm.getHost(vmMor);
      this.firstHost = hostMor;
      /* start nsxa on the firstHost */
      assertTrue(startNsxa(null, null, opaque_uplink, this.firstHost),
               "Succeeded to start nsxa on " + this.firstHost,
               "Failed to start nsxa on " + this.firstHost);
      /*
       * Query for the opaque network
       */
      getOpaqueNetwork(this.firstHost);
      /*
       * Set up one test vm to reconfigure vnic to connect to opaque
       * networking and power on the vm.
       */
      oneTestVmSetup();
      /*
       * Power off the vm
       */
      assertTrue(
               vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, true),
               "Successfully powered off the virtual machine",
               "Failed to power off the virtual machine");
      /*
       * Create a vm snapshot
       */
      snapshotMor = vm.createSnapshot(vmMor, "snapshot-1", "First snapshot",
               false, false);
      /*
       * Check if the snapshot is valid
       */
      assertNotNull(snapshotMor, "The snapshot is valid",
               "The snapshot is invalid");
      return true;
   }

   @Test(description = "Create a snapshot of vm connecting to opaque network, "
            + "change nework to vss, delete the opaque network and revert "
            + "the vm back to the snapshot")
   public void test()
      throws Exception
   {
      /*
       * Reconfigure the vm to connect to vss portgroup here
       */
      assertTrue(vm.reconfigVM(vmMor, origVMConfigSpec),
               "Reconfigured the vm to its original settings",
               "Failed to reconfigure the vm to its original settings");
      try {
         stopNsxa(null, null);
      } catch (Throwable e) {
         log.warn("stopNsax throw Exception.");
      }
      /*
       * Revert to the snapshot
       */
      assertTrue(snapShot.revertToSnapshot(snapshotMor, this.firstHost, true),
               "Successfully reverted to the snapshot",
               "Failed to revert to the snapshot");
      /*
       * Power on the vm
       */
      assertTrue(
               vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON, true),
               "Successfully powered on the virtual machine",
               "Failed to power on the virtual machine");
      /*
       * start nsxa again, otherwise reconfig vm to original spec would fail.
       */
      assertTrue(startNsxa(null, null, opaque_uplink, this.firstHost),
               "Succeeded to start nsxa on " + this.firstHost,
               "Failed to start nsxa on " + this.firstHost);
   }
}

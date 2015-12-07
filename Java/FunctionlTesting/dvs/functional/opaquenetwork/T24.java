package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;

public class T24 extends OpaqueNetworkBase
{

   private ManagedObjectReference failoverHost = null;
   private ManagedObjectReference failedHost = null;

   public void MigrateVM()
      throws Exception
   {
      Vector<ManagedObjectReference> hostMorVector = new Vector<ManagedObjectReference>();
      hostMorVector.add(this.failoverHost);
      hostMorVector.add(this.failedHost);
      for (ManagedObjectReference hostMor : hostMorVector) {
         /*
          * Generate the vm relocate spec for moving the vm from one host
          * to another
          */
         VirtualMachineRelocateSpec relocateSpec = new VirtualMachineRelocateSpec();
         relocateSpec.setHost(hostMor);
         relocateSpec.setPool(this.ihs.getResourcePool(hostMor).get(0));
         ProvisioningOpsStorageHelper storageHelper = new ProvisioningOpsStorageHelper(
                  this.connectAnchor);
         ManagedObjectReference dsMor = storageHelper.getVMConfigDatastore(vmMor);
         relocateSpec.setDatastore(dsMor);
         assertTrue(vm.relocateVM(vmMor, relocateSpec,
                  VirtualMachineMovePriority.DEFAULT_PRIORITY),
                  "Successfully relocated the vm with the destination "
                           + "network backing",
                  "Failed to relocate the vm with the "
                           + "destination network backing");
         verifyVmBackingInfo();
         /*
          * Sleep 10 seconds for migrating the vm back
          */
         Thread.sleep(10 * 1000);
      }
   }

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      /*
       * Init code for all entities in the inventory
       */
      initialize();
      /*
       * Find cluster which hosts are placed in and enable HA for it
       */
      ClusterPreparation("HA");
      /*
       * Get a usable vm.
       */
      getOneTestVm();
      /*
       * Set failedHost and failoverHost properly.
       */
      ManagedObjectReference hostMor = vm.getHost(vmMor);
      this.failedHost = hostMor;
      for (ManagedObjectReference tmpHostMor : this.clusterHosts) {
         if (!ihs.getHostName(tmpHostMor).equals(ihs.getHostName(failedHost))) {
            this.failoverHost = tmpHostMor;
         }
      }
      selectVnic(this.failedHost);
      selectVnic(this.failoverHost);
      /* start nsxa on all hosts */
      Vector<ManagedObjectReference> hostVector = new Vector<ManagedObjectReference>();
      hostVector.add(this.failedHost);
      hostVector.add(this.failoverHost);
      for (ManagedObjectReference tmpMor : hostVector) {
         String tmpName = this.ihs.getHostName(tmpMor);
         assertTrue(startNsxa(null, null, opaque_uplink, tmpMor),
                  "Succeeded to start nsxa on " + tmpName,
                  "Failed to start nsxa on " + tmpName);
      }
      /*
       * Query for the opaque network
       */
      getOpaqueNetwork(null);
      /*
       * Set up one test vm
       */
      oneTestVmSetup();

      return true;
   }

   @Test(description = "Attach vm to the opaque network and make another "
            + "opaque network as a failover ha network")
   public void test()
      throws Exception
   {
      /*
       * Migrate VM
       */
      MigrateVM();
      String failedHostName = ihs.getHostName(this.failedHost);
      String failoverHostName = this.ihs.getHostName(this.failoverHost);
      assertTrue(haHelper.rebootHAHost(this.failedHost),
               "successfully rebooted the host :" + failedHostName,
               "Reboot failed on the host:" + failedHostName);
      /*
       * Restart nsxa on failedHost after reboot, otherwise opaque_uplink will be kept
       * in used state.
       */
      assertTrue(startNsxa(null, null, opaque_uplink, this.failedHost),
               "Succeeded to start nsxa on " + failedHostName,
               "Failed to start nsxa on " + failedHostName);
      /*
       * Verifies VMs registration on the failoverHost
       */
      assertTrue(this.icluster.verifyVmRegistration(failoverHostName, vmNames,
               vmsMap, vmStateMap), "All VMs are registered on "
               + failoverHostName, "Failed to register all vms on "
               + failoverHostName);

      /*
       * Verifies VM backinfo is still opaque network.
       */
      verifyVmBackingInfo();
   }
}

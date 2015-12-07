package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.CannotAccessNetwork;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;

public class T32 extends OpaqueNetworkBase
{

   private ManagedObjectReference firstHost = null;
   private ManagedObjectReference secondHost = null;

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      /*
       * Init code for all entities in the inventory
       */
      initialize();
      /*
       * Find cluster which hosts are placed in and enable DRS for it
       */
      ClusterPreparation("NONE");
      /*
       * Get a shared vm for migration.
       */
      getOneTestVm();
      /*
       * Prepare hosts, set firstHost and secondHost properly.
       */
      ManagedObjectReference hostMor = vm.getHost(vmMor);
      this.firstHost = hostMor;
      for (ManagedObjectReference tmpHostMor : this.clusterHosts) {
         if (!ihs.getHostName(tmpHostMor).equals(ihs.getHostName(firstHost))) {
            this.secondHost = tmpHostMor;
         }
      }
      selectVnic(this.firstHost);
      selectVnic(this.secondHost);
      /*
       * Only start nsxa on the first host.
       */
      assertTrue(startNsxa(null, null, opaque_uplink, this.firstHost),
               "Succeeded to start nsxa on " + this.firstHost,
               "Failed to start nsxa on " + this.firstHost);
      /*
       * Query for the opaque network
       */
      getOpaqueNetwork(this.firstHost);
      /*
       * Set up one test vm to reconfigure vnic to connect to opaque networking.
       */
      oneTestVmSetup();
      return true;
   }

   @Test(description = "Migrate a vm from one host to another on an opaque "
              + "network with the target host not having that opaque "
              + "network - exception")
   public void test()
      throws Exception
   {
      /*
       * Generate the vm relocate spec for moving the vm from one host
       * to another
       */
      VirtualMachineRelocateSpec relocateSpec = new VirtualMachineRelocateSpec();
      relocateSpec.setHost(this.secondHost);
      relocateSpec.setPool(this.ihs.getResourcePool(this.secondHost).get(0));
      ProvisioningOpsStorageHelper storageHelper = new ProvisioningOpsStorageHelper(
               this.connectAnchor);
      ManagedObjectReference dsMor = storageHelper.getVMConfigDatastore(vmMor);
      relocateSpec.setDatastore(dsMor);
      try {
         vm.relocateVM(vmMor, relocateSpec,
                  VirtualMachineMovePriority.DEFAULT_PRIORITY);
         throw new Exception("Relocation of vm to host without "
                  + "opaque network passed but it should have failed");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new CannotAccessNetwork();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }
}

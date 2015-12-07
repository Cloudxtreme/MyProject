package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.Assert.assertNotNull;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.vim.host.VmotionSystem;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;

public class T31 extends OpaqueNetworkBase
{

   private ManagedObjectReference firstHost = null;
   private ManagedObjectReference secondHost = null;
   private String firstHostName = null;
   private String secondHostName = null;
   private String message = null;
   private String vnic_id1 = null;
   private String vnic_id2 = null;
   private ManagedObjectReference nsMor1 = null;
   private ManagedObjectReference nsMor2 = null;
   private VmotionSystem vmotionSystem = null;
   private ManagedObjectReference vmotionMor1 = null;
   private ManagedObjectReference vmotionMor2 = null;

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
      firstHostName = ihs.getHostName(firstHost);
      secondHostName = ihs.getHostName(secondHost);
      deselectVnics();
      /*
       * Start nsxa on both hosts.
       */
      message = " to start nsxa on " + this.firstHostName;
      assertTrue(startNsxa(null, null, opaque_uplink, this.firstHost),
               "Succeeded " + message, "Failed " + message);
      message = " to start nsxa on " + this.secondHostName;
      assertTrue(startNsxa(null, null, opaque_uplink, this.secondHost),
               "Succeeded " + message, "Failed " + message);
      /*
       * Query for the opaque network
       */
      getOpaqueNetwork(this.firstHost);
      assertTrue(opaqueNetworkInfo.size() > 1,
               "At least two opaqueNetworks are needed.");
      /*
       * Set up one test vm to reconfigure vnic to connect to opaque networking.
       */
      oneTestVmSetup();
      /*
       * Create vmknic connecting to opaque network and enable vmotion on them.
       */
      buildHostVnicSpec(opaqueNetworkInfo.get(1));
      nsMor1 = ins.getNetworkSystem(this.firstHost);
      vnic_id1 = ins.addVirtualNic(nsMor1, "", this.hostVirtualNicSpec);
      nsMor2 = ins.getNetworkSystem(this.secondHost);
      vnic_id2 = ins.addVirtualNic(nsMor2, "", this.hostVirtualNicSpec);
      vmotionSystem = new VmotionSystem(connectAnchor);
      vmotionMor1 = vmotionSystem.getVMotionSystem(this.firstHost);
      vmotionMor2 = vmotionSystem.getVMotionSystem(this.secondHost);
      message = " to enable vmotion for " + vnic_id1 + " on " + firstHostName;
      assertTrue(vmotionSystem.selectVnic(vmotionMor1, vnic_id1), "succeeded"
               + message, "Failed " + message);
      message = " to enable vmotion for " + vnic_id2 + " on " + secondHostName;
      assertTrue(vmotionSystem.selectVnic(vmotionMor2, vnic_id2), "succeeded"
               + message, "Failed" + message);
      return true;
   }

   @Test(description = "Migrate a vm from one host to another on an opaque "
            + "network with vmotion nic being on an opaque network")
   public void test()
      throws Exception
   {
      /*
       * Make sure vm is connected before vmotion.
       */
      assertTrue(vm.isConnected(vmMor), "vm is connected",
               "vm is disconnected before migration");
      /*
       * Check network connectivity
       */
      String vmknicIp = getOpaqueVmkIp(opaqueNetworkInfo.get(1).getOpaqueNetworkId());
      String vmIp = getVmIPAddress(vmMor);
      assertNotNull(vmknicIp, "vmknic IP is null");
      assertNotNull(vmIp, "vmIP is null");
      log.debug("vmknic IP addresss is " + vmknicIp);
      log.debug("vm IP address is " + vmIp);
      // assertTrue(DVSUtil.checkNetworkConnectivity(vmknicIp, vmIp),
      // "The vm is reachable before migration",
      // "The vm is not reachable before migration");
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
      assertTrue(vm.relocateVM(vmMor, relocateSpec,
               VirtualMachineMovePriority.DEFAULT_PRIORITY),
               "Successfully relocated the vm with the destination "
                        + "network backing",
               "Failed to relocate the vm with the "
                        + "destination network backing");
      /*
       * Verifies VM backinfo is still opaque network.
       */
      verifyVmBackingInfo();
      /*
       * Check if vm is connected after vmotion.
       */
      assertTrue(vm.isConnected(vmMor), "vm is connected",
               "vm gets disconnected after migration");
      /*
       * Check network connectivity
       */
      vmknicIp = getOpaqueVmkIp(opaqueNetworkInfo.get(1).getOpaqueNetworkId());
      vmIp = getVmIPAddress(vmMor);
      assertNotNull(vmknicIp, "vmknic IP is null");
      assertNotNull(vmIp, "vmIP is null");
      log.debug("vmknic IP addresss is " + vmknicIp);
      log.debug("vm IP address is " + vmIp);
      // assertTrue(DVSUtil.checkNetworkConnectivity(vmknicIp, vmIp),
      // "The vm is reachable", "The vm is not reachable");
   }

   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
      if (vnic_id1 != null) {
         /*
          * Delete the vmkernel nic
          */
         assertTrue(ins.removeVirtualNic(nsMor1, vnic_id1),
                  "Removed the vmkernel nic1",
                  "Failed to remove the vmkernel nic1");
      }
      if (vnic_id2 != null) {
         /*
          * Delete the vmkernel nic
          */
         assertTrue(ins.removeVirtualNic(nsMor2, vnic_id2),
                  "Removed the vmkernel nic2",
                  "Failed to remove the vmkernel nic2");
      }
      super.testCleanUp();
      return true;
   }
}

package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachinePowerState;

public class T29 extends OpaqueNetworkBase
{

   private ManagedObjectReference firstHost = null;
   private ManagedObjectReference secondHost = null;
   private HashMap<String, ManagedObjectReference> vmsMap = new HashMap<String, ManagedObjectReference>();
   private HashMap<String, VirtualMachinePowerState> vmStateMap = new HashMap<String, VirtualMachinePowerState>();
   private String vmNames[] = null;

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
      ClusterPreparation("DRS");
      /*
       * Get a usable vm.
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

   @Test(description = "Basic DRS usecase : one vm connecting to an opaque "
            + "network, one host fails to enter maintenance mode if another "
            + "host has no opaque network. The host succeeds to enter "
            + "maintenance mode if another host also has opaque network setup")
   public void test()
      throws Exception
   {
      /*
       * Note that the VM stored in the first host originally.
       */
      String firstHostName = this.ihs.getHostName(this.firstHost);
      String secondHostName = this.ihs.getHostName(this.secondHost);
      this.maintenanceHostList.add(this.firstHost);
      /*
       * Don't start nsxa on the second host, entering into maintenance mode should fail.
       */
      try {
         this.enterMaintenanceMode = this.ihs.hostsEnterMaintenanceMode(
                  this.maintenanceHostList, 300, null);
         assertTrue(this.enterMaintenanceMode == false,
                  "Couldn't enter maintenance mode as expected",
                  "Failed! Entered into maintenance mode unexpectedly.");
      } catch (Exception e) {
         log.info("Successfully got an exception while tring to enter "
                  + "into maintenance mode");
      }
      /*
       * Start nsxa on the second host, entering into maintenance mode should pass.
       */
      assertTrue(startNsxa(null, null, opaque_uplink, this.secondHost),
               "Succeeded to start nsxa on " + this.secondHost,
               "Failed to start nsxa on " + this.secondHost);
      this.enterMaintenanceMode = this.ihs.hostsEnterMaintenanceMode(
               this.maintenanceHostList, 300, null);
      assertTrue(this.enterMaintenanceMode,
               "Succeeded to enter maintenance mode",
               "Faild to enter into maintenance mode");
      /*
       * Verifies VM is migratd to the secondtHost
       */
      assertTrue(this.icluster.verifyVmRegistration(secondHostName, vmNames,
               vmsMap, vmStateMap), "VM is migrated to " + firstHostName,
               "Failed to migrate vm to " + firstHostName);
      /*
       * Verifies VM backinfo is still opaque network.
       */
      verifyVmBackingInfo();
   }
}

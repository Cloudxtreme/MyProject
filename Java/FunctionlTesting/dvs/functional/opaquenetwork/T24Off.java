package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;

public class T24Off extends OpaqueNetworkBase
{

   private ManagedObjectReference failoverHost = null;
   private ManagedObjectReference failedHost = null;
   private String failedHostName = null;

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
      failedHostName = ihs.getHostName(this.failedHost);
      selectVnic(this.failedHost);
      selectVnic(this.failoverHost);
      /* start nsxa on failed host */
      assertTrue(startNsxa(null, null, opaque_uplink, failedHost),
               "Succeeded to start nsxa on " + failedHostName,
               "Failed to start nsxa on " + failedHostName);
      /*
       * Query for the opaque network on failed Host
       */
      getOpaqueNetwork(failedHost);
      /*
       * Set up one test vm
       */
      oneTestVmSetup();

      return true;
   }

   @Test(description = "Verify HA failover can't happen for vm to the "
            + "opaque network if failover host has no opaque network")
   public void test()
      throws Exception
   {
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
       * Verifies VM's registration on the failedHost
       * The VM should be kept on failedHost.
       */
      assertTrue(this.icluster.verifyVmRegistration(failedHostName, vmNames,
               vmsMap, vmStateMap), "As expected VM is kept on "
               + failedHostName, "Failure, VM's migrated out of "
               + failedHostName);

      /*
       * Verifies VM backinfo is still opaque network.
       */
      verifyVmBackingInfo();
   }
}

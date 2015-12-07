package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;

public class T25 extends OpaqueNetworkBase
{
   private ManagedObjectReference hostMor = null;
   private String vnic_id;

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      /*
       * Init code for all entities in the inventory
       */
      initialize();
      /*
       * Start nsxa;
       */
      hostMor = ihs.getConnectedHost(null);
      String hostName = this.ihs.getHostName(hostMor);
      assertTrue(startNsxa(null, null, opaque_uplink, hostMor),
               "Succeeded to start nsxa on " + hostName,
               "Failed to start nsxa on " + hostName);
      /*
       * Query for the opaque network
       */
      getOpaqueNetwork(hostMor);
      buildHostVnicSpec(null);

      return true;
   }

   @Test(description = "Add a host's vmkernel nic to the opaque network "
            + "and test network connectivity")
   public void test()
      throws Exception
   {
      /*
       * vmknic connecting to opaque network only can be created when client
       * is connecting to host directly, not through VC.
       */
      vnic_id = ins.addVirtualNic(nsMor, "", this.hostVirtualNicSpec);
      /*
       * Make sure that the vnic id is not null
       */
      assertTrue(vnic_id != null, "Successfully added a vmkernel nic",
               "Failed to add a vmkernel nic");

      checkDhcpIP();

      /*
       * build hostVirtualNicSpec with opaqueNetworkInfo.get(1)
       * instead of hostOpaqueNetworkInfo(0);
       */
      hostOpaqueNetworkInfo = this.opaqueNetworkInfo.get(1);
      buildHostVnicSpec(hostOpaqueNetworkInfo);
      /*
       * Update the vnic to connect to opaque network
       */
      //vnic_id = "vmk0";
      assertTrue(ins.updateVirtualNic(nsMor, vnic_id, this.hostVirtualNicSpec),
              "Updated the virtual nic to connect to opaque network",
              "Failed to update the virtual nic to connect to opaque "
                       + "network");
      /*
       * Make sure that the host vmkernel nic is reachable
       */
      checkDhcpIP();

   }

   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
      if (vnic_id != null) {
         /*
          * Delete the vmkernel nic
          */
         assertTrue(ins.removeVirtualNic(nsMor, vnic_id),
                  "Removed the vmkernel nic",
                  "Failed to remove the vmkernel nic");
      }
      try {
         stopNsxa(null, null);
      } catch (Throwable e) {
         log.warn("stopNsax throw Exception.");
         e.printStackTrace();
      }
      return true;
   }
}

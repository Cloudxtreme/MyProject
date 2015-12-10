package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Arrays;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

public class T30 extends OpaqueNetworkBase
{

   private DistributedVirtualSwitch vds = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference vdsMor = null;
   private ManagedObjectReference dcMor = null;
   private DVSConfigSpec vdsConfigSpec = null;
   private String pgKey;
   private String vds_uuid = null;
   private String port_key = null;
   private HostVirtualNic vnic;
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
      /*
       *  create a vds in the network folder
       */
      vds = new DistributedVirtualSwitch(connectAnchor);
      dcMor = this.folder.getDataCenter();
      vdsConfigSpec = DVSUtil.createDefaultDVSConfigSpec("vds-1");
      vdsConfigSpec.setNumStandalonePorts(10);
      vdsMor = folder.createDistributedVirtualSwitch(
               folder.getNetworkFolder(dcMor), vdsConfigSpec);
      /*
       * Add a host and a free pnic on the host to the vds
       */
      assertTrue(
               DVSUtil.addFreePnicAndHostToDVS(connectAnchor, hostMor,
                        Arrays.asList(new ManagedObjectReference[] { vdsMor })),
               "Successfully added the free pnic on the host to the vds",
               "Failed to add the free pnic on the host to the vds");
      /*
       * Add a portgroup on the vds
       */
      DVPortgroupConfigSpec[] portgrpSpecArray = new DVPortgroupConfigSpec[1];
      portgrpSpecArray[0] = new DVPortgroupConfigSpec();
      portgrpSpecArray[0].setName("pg-1");
      portgrpSpecArray[0].setNumPorts(10);
      pgKey = this.vds.addPortGroup(vdsMor,
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 10, "vds-pg-1");
      /*
       * Get a free port in the vds
       */
      this.port_key = this.vds.getFreeStandaloneDVPortKey(vdsMor, null);
      this.vds_uuid = this.vds.getConfig(vdsMor).getUuid();

      return true;
   }

   @Test(description = "Basic connection endpoint changes for vmknic "
              + "(vss -> on, dvport -> on, dvportgroup -> on etc...)")
   public void test()
      throws Exception
   {
      /*
       * Add a vmkernel nic
       */
      vnic_id = ins.addVirtualNic(nsMor, "", hostVirtualNicSpec);
      ins.refresh(nsMor);
      checkDhcpIP();
      vnic = ins.getVirtualNicFromOpaqueNetwork(nsMor,
               hostOpaqueNetworkInfo.getOpaqueNetworkId()).get(0);
      assertTrue(vnic != null, "Successfully found the vmkernel nic "
               + "connecting to the opaque network", "Failed to find the "
               + "vmkernel nic connecting to the opaque network");
      /*
       * Connect the vmkernel nic to a vds port
       */
      HostVirtualNicSpec hostVnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(vnic.getSpec());
      DistributedVirtualSwitchPortConnection portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(vds_uuid);
      portConnection.setPortKey(port_key);
      hostVnicSpec.setOpaqueNetwork(null);
      hostVnicSpec.setDistributedVirtualPort(portConnection);
      assertTrue(ins.updateVirtualNic(nsMor, vnic_id, hostVnicSpec, false),
               "Updated the virtual nic to connect to vds port",
               "Failed to update the virtual nic to connect to vds port");
      /*
       * Update the vmkernel nic to connect to an opaque network
       */
      assertTrue(ins.updateVirtualNic(nsMor, vnic_id, this.hostVirtualNicSpec),
               "Updated the virtual nic to connect to opaque network",
               "Failed to update the virtual nic to connect to opaque "
                        + "network");
      /*
       * Make sure that the host vmkernel nic  is reachable
       */
      checkDhcpIP();
      /*
       * Update the vnic to connect to vds portgroup
       */
      portConnection.setPortKey(null);
      portConnection.setPortgroupKey(pgKey);
      hostVnicSpec.setDistributedVirtualPort(portConnection);
      assertTrue(ins.updateVirtualNic(nsMor, vnic_id, hostVnicSpec, false),
               "Updated the virtual nic to connect to vds portgroup",
               "Failed to update the virtual nic to connect to vds portgroup");
      /*
       * Update the vnic to connect to opaque network
       */
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
         assertTrue(ins.removeVirtualNic(nsMor, vnic_id),
                  "Successfully removed the vmkernel nic from the host",
                  "Failed to remove the vmkernel nic from the host");
      }
      if (vdsMor != null) {
         vds.destroy(vdsMor);
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

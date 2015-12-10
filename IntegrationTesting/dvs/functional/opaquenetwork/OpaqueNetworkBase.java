package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;

import static com.vmware.vcqa.ha.HAHelper.HA_ENABLED;
import static com.vmware.vcqa.ha.HAHelper.HA_DISABLED;
import static com.vmware.vcqa.ha.HAHelper.HA_ADMISSIONCONTROL_ENABLED;
import static com.vmware.vcqa.ha.HAHelper.HA_ADMISSIONCONTROL_DISABLED;
import static com.vmware.vcqa.ha.HAHelper.HA_DEFAULT_FAILOVER_LEVEL;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import org.testng.annotations.AfterMethod;

import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicOpaqueNetworkSpec;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceBackingInfo;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualEthernetCardOpaqueNetworkBackingInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.ha.HAHelper;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.ClusterHelper;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.VmotionSystem;
import com.vmware.vcqa.vim.vm.Snapshot;

public abstract class OpaqueNetworkBase extends TestBase
{
   protected VirtualMachine vm = null;
   protected Folder folder = null;
   protected Vector<ManagedObjectReference> vmList = null;
   protected NetworkSystem ins = null;
   protected HostSystem ihs = null;
   protected ManagedObjectReference nsMor = null;
   protected ManagedObjectReference vmMor = null;
   protected ManagedObjectReference templateVmMor = null;
   protected ManagedObjectReference deployedVmMor = null;
   protected ManagedObjectReference snapshotMor = null;
   protected Snapshot snapShot = null;
   protected VirtualMachineConfigSpec origVMConfigSpec = null;
   protected ClusterComputeResource icr = null;
   protected ManagedObjectReference clusterMor = null;
   protected Boolean haConfigured = false;
   protected Boolean drsConfigured = false;
   protected Vector<ManagedObjectReference> clusterHosts = null;
   protected HostOpaqueNetworkInfo hostOpaqueNetworkInfo = null;
   protected ClusterHelper icluster = null;
   protected List<HostOpaqueNetworkInfo> opaqueNetworkInfo = null;
   protected HAHelper haHelper = null;
   protected HashMap<String, ManagedObjectReference> vmsMap = new HashMap<String, ManagedObjectReference>();
   protected HashMap<String, VirtualMachinePowerState> vmStateMap = new HashMap<String, VirtualMachinePowerState>();
   protected String vmNames[] = null;
   protected Vector<ManagedObjectReference> maintenanceHostList = null;
   protected Boolean enterMaintenanceMode = false;
   protected HostVirtualNicSpec hostVirtualNicSpec;
   protected String opaque_uplink = "vmnic1";
   protected String env_opaque_uplink = "OPAQUE_NETWORK_UPLINK";
   protected String nsa_simulator_path = "http://vmweb.vmware.com/~netfvt/nsxa/files.txt";

   public void initialize()
      throws Exception
   {
      vm = new VirtualMachine(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      icr = new ClusterComputeResource(connectAnchor);
      icluster = new ClusterHelper(connectAnchor);
      haHelper = new HAHelper(connectAnchor);
      maintenanceHostList = new Vector<ManagedObjectReference>();
      snapShot = new Snapshot(connectAnchor);
      folder = new Folder(connectAnchor);
      if (System.getenv(env_opaque_uplink) != null) {
         opaque_uplink = System.getenv(env_opaque_uplink);
      }
   }

   /*
    * Prepare cluster and enable HA or DRS for the cluster
    */
   public void ClusterPreparation(String cmd)
      throws Exception
   {
      Vector<ManagedObjectReference> clusters = icr.getAllClusters();
      assertNotEmpty(clusters, "Couldn't find any cluster existing");
      for (ManagedObjectReference clsMor : clusters) {
         clusterHosts = icr.getHosts(clsMor);
         if (clusterHosts.size() > 1) {
            this.clusterMor = clsMor;
            break;
         }
      }
      assertNotNull(clusterMor,
               "Succeeded to find a cluster with at least 2 hosts",
               "Faield to find a cluster with at least 2 hosts.");
      if (cmd.equalsIgnoreCase("HA") || cmd.equalsIgnoreCase("BOTH")) {
         this.icr.removeAllDasVmConfigSpecs(this.clusterMor);
         // Enable HA for the cluster
         haConfigured = this.icr.setDAS(this.clusterMor, HA_ENABLED,
                  HA_ADMISSIONCONTROL_ENABLED, HA_DEFAULT_FAILOVER_LEVEL,
                  Boolean.TRUE);
         assertTrue(haConfigured, "Set the HA cluster config successfully.",
                  "Could not set the HA cluster config for the test.");
      }
      if (cmd.equalsIgnoreCase("DRS") || cmd.equalsIgnoreCase("BOTH")) {
         drsConfigured = this.icr.setDRS(this.clusterMor, true);
         assertTrue(drsConfigured, "Set the DRS cluster config successfully.",
                  "Could not set the DRS cluster config for the test.");
      }
   }

   public void getOpaqueNetwork(ManagedObjectReference hostMor)
      throws Exception
   {
      /*
       * Query for the opaque network
       */
      if (hostMor == null) {
         this.nsMor = ins.getNetworkSystem(this.clusterHosts.get(0));
      } else {
         this.nsMor = ins.getNetworkSystem(hostMor);
      }
      opaqueNetworkInfo = ins.getNetworkInfo(nsMor).getOpaqueNetwork();
      assertTrue(opaqueNetworkInfo != null && opaqueNetworkInfo.size() > 0,
               "The list of opaque networks is not null",
               "The list of opaque networks is null");
      this.hostOpaqueNetworkInfo = opaqueNetworkInfo.get(0);
   }

   public void getOneTestVm()
      throws Exception
   {
      /*
       * Get the first available vm in the inventory
       */
      this.vmList = vm.getAllVM();
      assertTrue(this.vmList != null && this.vmList.size() > 0,
               "Couldn't find a usable VM");
      this.vmMor = vmList.get(0);
   }

   public void oneTestVmSetup()
      throws Exception
   {
      oneTestVmSetup(true);
   }

   public void oneTestVmSetup(boolean poweron)
      throws Exception
   {
      if (this.vmMor == null) {
         getOneTestVm();
      }
      Map<String, String> vmEthernetMap = NetworkUtil.getEthernetCardNetworkMap(
               vmMor, connectAnchor);
      Set<String> ethernetCardDevicesSet = vmEthernetMap.keySet();
      /*
       * Compute a new ethernet card network map
       */
      Map<String, HostOpaqueNetworkInfo> ethernetCardNetworkMap = new HashMap<String, HostOpaqueNetworkInfo>();
      for (String ethernetCard : ethernetCardDevicesSet) {
         log.info("Connect vm vnic to  opaque network device: "
                  + this.hostOpaqueNetworkInfo.getOpaqueNetworkId());
         ethernetCardNetworkMap.put(ethernetCard, this.hostOpaqueNetworkInfo);
      }
      /*
       * Reconfigure the virtual machine to connect to opaque network
       */
      this.origVMConfigSpec = NetworkUtil.reconfigureVMConnectToOpaqueNetwork(
               vmMor, ethernetCardNetworkMap, connectAnchor);
      if (poweron) {
         /*
          * Power on the vm
          */
         assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON,
                  true), "Successfully powered on the virtual machine",
                  "Failed to power on the virtual machine");
      }

      Vector<ManagedObjectReference> tmpVmList = new Vector<ManagedObjectReference>();
      tmpVmList.add(vmMor);
      /*
       * Store vms state in maps:
       */
      vmNames = new String[tmpVmList.size()];
      int vmCount = 0;
      for (ManagedObjectReference vmMor : tmpVmList) {
         vmNames[vmCount] = vm.getName(vmMor);
         vmsMap.put(vmNames[vmCount], vmMor);
         vmStateMap.put(vmNames[vmCount], vm.getVMState(vmMor));
         vmCount++;
      }
   }

   /*
    * Enable vmotion on both the host vnics
    */
   public void selectVnic(ManagedObjectReference hostMor)
      throws Exception
   {
      VmotionSystem vmotionSystem = new VmotionSystem(connectAnchor);
      ManagedObjectReference vmotionMor = vmotionSystem.getVMotionSystem(hostMor);
      HostVirtualNic vnic = vmotionSystem.getVmotionVirtualNic(vmotionMor,
               hostMor);
      if (vnic == null) {
         HostVirtualNic origVnic = ins.getVirtualNic(
                  ins.getNetworkSystem(hostMor), "Management Network", true);
         vmotionSystem.selectVnic(vmotionMor, origVnic.getDevice());
      }
   }

   /*
    * Disable vmotion on hosts
    */
   public void deselectVnics()
      throws Exception
   {
      if (this.clusterHosts != null) {
         VmotionSystem vmotionSystem = new VmotionSystem(connectAnchor);
         for (ManagedObjectReference hostMor : this.clusterHosts) {
            ManagedObjectReference vmotionMor = vmotionSystem.getVMotionSystem(hostMor);
            HostVirtualNic vnic = vmotionSystem.getVmotionVirtualNic(
                     vmotionMor, hostMor);
            if (vnic != null) {
               vmotionSystem.deselectVnic(vmotionMor);
            }
         }
      }
   }

   public void verifyVmBackingInfo()
      throws Exception
   {
      verifyVmBackingInfo(null);
   }

   public void verifyVmBackingInfo(ManagedObjectReference tmpVmMor)
      throws Exception
   {
      ManagedObjectReference verifiedVmMor = null;
      if (tmpVmMor != null) {
         verifiedVmMor = tmpVmMor;
      } else {
         verifiedVmMor = this.vmMor;
      }
      List<VirtualDeviceConfigSpec> currentEthCards;
      currentEthCards = DVSUtil.getAllVirtualEthernetCardDevices(verifiedVmMor,
               connectAnchor);
      for (VirtualDeviceConfigSpec anEthCard : currentEthCards) {
         VirtualEthernetCard vnic = (VirtualEthernetCard) anEthCard.getDevice();
         VirtualDeviceBackingInfo backInfo = (VirtualDeviceBackingInfo) vnic.getBacking();
         assertTrue(
                  (backInfo instanceof VirtualEthernetCardOpaqueNetworkBackingInfo),
                  "BackingInfo is not VirtualEthernetCardOpaqueNetworkBackingInfo object");
         VirtualEthernetCardOpaqueNetworkBackingInfo opaqueBackingInfo = (VirtualEthernetCardOpaqueNetworkBackingInfo) backInfo;
         String currOpaqueNetworkId = opaqueBackingInfo.getOpaqueNetworkId();
         String currOpaqueNetworkType = opaqueBackingInfo.getOpaqueNetworkType();
         String expectedOpaqueNetworkId = this.hostOpaqueNetworkInfo.getOpaqueNetworkId();
         String expectedOpaqueNetworkType = this.hostOpaqueNetworkInfo.getOpaqueNetworkType();
         String expectedOpaqueNetworkName = this.hostOpaqueNetworkInfo.getOpaqueNetworkName();
         log.info("OpaquenetworkName is " + expectedOpaqueNetworkName);
         assertTrue((currOpaqueNetworkId.equals(expectedOpaqueNetworkId))
                  && (currOpaqueNetworkType.equals(expectedOpaqueNetworkType)),
                  "Get the same Backing info " + "OpaqueNetworkId: "
                           + currOpaqueNetworkId + " OpaqueNetworkType: "
                           + currOpaqueNetworkType,
                  "Backing info is not the same, current OpqueNetworkId: "
                           + currOpaqueNetworkId
                           + " current OpaqueNetworkType: "
                           + currOpaqueNetworkType
                           + " expected OpaqueNetworkId: "
                           + expectedOpaqueNetworkId
                           + " expected OpaqueNetworkType: "
                           + expectedOpaqueNetworkType);
      }
   }

   public String getOpaqueVmkIp(String opaqueNetworkId)
      throws Exception
   {
      if (opaqueNetworkId == null) {
         opaqueNetworkId = hostOpaqueNetworkInfo.getOpaqueNetworkId();
      }
      /*
       * Get the vnic device
       */
      HostVirtualNic vnic = ins.getVirtualNicFromOpaqueNetwork(nsMor,
               opaqueNetworkId).get(0);
      /*
       * Check network connectivity
       */
      HostIpConfig hostIpConfig = vnic.getSpec().getIp();
      String vnicIp = hostIpConfig.getIpAddress();
      return vnicIp;
   }

   public String getVmIPAddress(final ManagedObjectReference vmMor)
      throws Exception
   {
      String vmIP = null;
      final Map<String, String> ips = this.vm.getAllIPAddresses(vmMor);
      if (ips != null && !ips.isEmpty()) {
         final Iterator<String> ipIter = ips.values().iterator();
         while (ipIter.hasNext()) {
            final String anIp = ipIter.next();
            if (NetworkUtil.isValidGuestIpAddr(anIp, false)) {
               vmIP = anIp;
               break;
            }
         }
      }

      log.info("GuestIp: " + vmIP);
      return vmIP;
   }

   public void checkDhcpIP()
      throws Exception
   {
      /*
       * Refresh the network system
       */
      ins.refresh(nsMor);
      /*
       * sleep 60 seconds waiting for vmknic to get dhcp address.
       */
      log.info("Sleeping 60 seconds to get dhcp ip address ...");
      Thread.sleep(60 * 1000);
      String vnicIp = getOpaqueVmkIp(null);
      assertTrue(
               ((!vnicIp.startsWith("0.0.0.0") && !vnicIp.startsWith("169.254."))),
               "Passed to verify network connectivity, dhcp ip is " + vnicIp,
               "Didn't get a dhcp address, failed to verify network connectivity");
   }

   public void buildHostVnicSpec(HostOpaqueNetworkInfo paraOpaqueNetworkInfo)
      throws Exception
   {
      /* vsphere-2015 use */
      HostOpaqueNetworkInfo valOpaqueNetworkInfo = null;
      if (paraOpaqueNetworkInfo == null) {
         valOpaqueNetworkInfo = hostOpaqueNetworkInfo;
      } else {
         valOpaqueNetworkInfo = paraOpaqueNetworkInfo;
      }

      HostVirtualNicOpaqueNetworkSpec opaqueNetworkSpec = new HostVirtualNicOpaqueNetworkSpec();
      opaqueNetworkSpec.setOpaqueNetworkId(valOpaqueNetworkInfo.getOpaqueNetworkId());
      opaqueNetworkSpec.setOpaqueNetworkType(valOpaqueNetworkInfo.getOpaqueNetworkType());

      HostIpConfig ipConfig = new HostIpConfig();
      ipConfig.setDhcp(true);

      hostVirtualNicSpec = new HostVirtualNicSpec();
      hostVirtualNicSpec.setOpaqueNetwork(opaqueNetworkSpec);
      hostVirtualNicSpec.setIp(ipConfig);
   }

   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
      /*
       * Do cleanup for VMs
       */
      vm.powerOffVMs(this.vm.getAllVMByState(VirtualMachinePowerState.POWERED_ON));
      if (snapshotMor != null) {
         snapShot.removeSnapshot(snapshotMor, true, false);
         snapshotMor = null;
      }
      if (this.deployedVmMor != null) {
         this.vm.destroy(this.deployedVmMor);
      }
      if (this.templateVmMor != null) {
         this.vm.destroy(this.templateVmMor);
      }
      if ((vmMor != null) && (origVMConfigSpec != null)) {
         /*
          * Restore the vm configuration
          */
         assertTrue(vm.reconfigVM(vmMor, origVMConfigSpec),
                  "Reconfigured the vm to its original settings",
                  "Failed to reconfigure the vm to its original settings");
      }
      /*
       * Disable HA
       */
      if (this.haConfigured) {
         this.icr.setDAS(this.clusterMor, HA_DISABLED,
                  HA_ADMISSIONCONTROL_DISABLED, HA_DEFAULT_FAILOVER_LEVEL,
                  Boolean.TRUE);
      }
      /*
       * Disable DRS
       */
      if (this.drsConfigured) {
         this.icr.setDRS(clusterMor, false);
      }
      /*
       * Exit maintenance mode
       */
      if (this.enterMaintenanceMode) {
         this.ihs.hostsExitMaintenanceMode(this.maintenanceHostList, 300);
      }
      /*
       * Disable vmotion vmknic
       */
      deselectVnics();
      /*
       * Stop and clear nsxa
       */
      try {
         stopNsxa(null, null);
      } catch (Throwable e) {
         log.warn("stopNsax throw Exception.");
         e.printStackTrace();
      }

      return true;
   }

   public boolean startNsxa(String username,
                            String password,
                            String vmnic,
                            ManagedObjectReference hostMor)
      throws Exception
   {
      if (username == null) {
         username = TestConstants.ESX_USERNAME;
      }
      if (password == null) {
         password = TestConstants.ESX_PASSWORD;
      }
      return DVSUtil.startNsxa(connectAnchor, username, password, vmnic,
               hostMor, nsa_simulator_path);
   }

   public boolean stopNsxa(String username,
                           String password)
      throws Exception
   {
      if (username == null) {
         username = TestConstants.ESX_USERNAME;
      }
      if (password == null) {
         password = TestConstants.ESX_PASSWORD;
      }
      return DVSUtil.stopNsxa(connectAnchor, username, password);
   }
}

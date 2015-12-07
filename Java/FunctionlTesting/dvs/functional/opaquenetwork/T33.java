package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.Assert.assertNotNull;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.FaultToleranceSecondaryOpResult;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicManagerNicType;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.PhysicalNicCdpInfo;
import com.vmware.vc.PhysicalNicHintInfo;
import com.vmware.vc.VirtualMachineFaultToleranceState;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.FTTestConstants;
import com.vmware.vcqa.vim.FaultToleranceHelper;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.VirtualNicManager;

public class T33 extends OpaqueNetworkBase
{

   private ManagedObjectReference firstHost = null;
   private ManagedObjectReference secondHost = null;
   private ManagedObjectReference secondaryVmMor = null;
   private String firstHostName = null;
   private String secondHostName = null;
   private String message = null;
   private String vnic_id1 = null;
   private String vnic_id2 = null;
   private String[] host1_pnics = null;
   private String[] host2_pnics = null;
   private ManagedObjectReference nsMor1 = null;
   private ManagedObjectReference nsMor2 = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference vdsMor = null;
   private DistributedVirtualSwitch vds = null;
   private String pgKey = null;
   protected FaultToleranceHelper objFtHelper = null;

   HostVirtualNic getHostVirtualNic(ManagedObjectReference nsMor,
                                    String vnic_id)
      throws Exception
   {
      HostVirtualNic hostVnic = null;
      HostNetworkInfo hostNetworkInfo = ins.getNetworkInfo(nsMor1);
      List<HostVirtualNic> vNics = hostNetworkInfo.getVnic();
      for (HostVirtualNic vNic : vNics) {
         if (vNic.getDevice().equals(vnic_id)) {
            hostVnic = vNic;
            break;
         }
      }
      assertNotNull(hostVnic, "Failed to get HostVirtualNic for " + vnic_id);
      return hostVnic;
   }

   public String[] getFreeUpPNics(final ManagedObjectReference hostMor)
       throws Exception
    {
       String[] workingPnics = ins.getFreePNicsWithNetwork(hostMor);
       if (workingPnics != null) {
          return workingPnics;
       }
       ManagedObjectReference nwSystemMor = null;
       final String[] freePnicIds = ins.getPNicIds(hostMor);
       PhysicalNicHintInfo[] networkHintsInfo = null;

       if (freePnicIds != null && freePnicIds.length > 0) {
          nwSystemMor = ins.getNetworkSystem(hostMor);
          final List<String> workingPnicsList = new Vector<String>();
          /*
           * Gets network hint information for a PhysicalNic
           */
          Thread.sleep(2000);
          final Vector<PhysicalNicHintInfo> hintList = ins.getNetworkHint(
                   nwSystemMor, freePnicIds);
          if (hintList != null && hintList.size() > 0) {
             networkHintsInfo = hintList.toArray(new PhysicalNicHintInfo[hintList.size()]);
             for (int i = 0; i < networkHintsInfo.length; i++) {
                if (networkHintsInfo[i] != null) {
                   PhysicalNicCdpInfo pnicCdpInfo = null;
                   pnicCdpInfo = networkHintsInfo[i].getConnectedSwitchPort();
                   if (pnicCdpInfo != null) {
                      workingPnicsList.add(freePnicIds[i]);
                   }
                }
             }
          }
          if (workingPnicsList.size() > 0) {
             workingPnics = workingPnicsList.toArray(new String[workingPnicsList.size()]);
          }
       }
       return workingPnics;
    }

   void killVM(ManagedObjectReference vmMor)
      throws Exception

   {
      String vmName = vm.getVMName(vmMor);
      String hostName = vm.getHostName(vmMor);
      String pid = null;
      Connection conn = SSHUtil.getSSHConnection(hostName,
               TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD);
      String cmd = "ps -c | grep vmx | grep " + vmName + " | grep -v grep";
      Map<String, String> output = SSHUtil.getRemoteSSHCmdOutput(conn, cmd);
      if (output != null) {
         for (String key : output.keySet()) {
            if (key.equals("SSHOutputStream")) {
               /*
                * The ps output in Esxi host looks like below,
                */
               /*
               # ps -c | grep vmx | grep SharedVM-For-FT | grep -v grep
               1000210093 1000210093 vmx-debug /bin/vmx-debug .../SharedVM-For-FT.vmx
               1000210108 1000210093 vmx-vthread-4:SharedVM-For-FT /bin/vmx-debug ...
               1000210111 1000210093 vmx-mks:SharedVM-For-FT /bin/vmx-debug ...
               1000210119 1000210093 vmx-svga:SharedVM-For-FT /bin/vmx-debug ...
               1000210278 1000210093 vmx-vcpu-0:SharedVM-For-FT /bin/vmx-debug ...
               */
               String[] lines = output.get(key).split("\n");
               for (String line : lines) {
                  String[] cols = line.split("\\s+");
                  if (cols[2].equals("vmx") || cols[2].equals("vmx-debug")) {
                     pid = cols[0];
                     break;
                  }
               }
               if (pid != null && !pid.isEmpty()) {
                  log.info("vmx pid of vm " + vmName + "is " + pid);
                  SSHUtil.executeRemoteSSHCommand(conn, "kill " + pid);
               }
               break;
            }
         }
      }
      assertNotNull(pid, "Failed to get vmx pid for vm " + vmName);
   }

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      /*
       * Init code for all entities in the inventory
       */
      initialize();
      objFtHelper = new FaultToleranceHelper(this.connectAnchor);
      /*
       * Find cluster which hosts are placed in and enable HA for it
       */
      ClusterPreparation("HA");
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
      nsMor1 = ins.getNetworkSystem(firstHost);
      secondHostName = ihs.getHostName(secondHost);
      nsMor2 = ins.getNetworkSystem(secondHost);
      /*
       * Enable vmotion on vmk0
       */
      selectVnic(firstHost);
      selectVnic(secondHost);
      /*
       * Check number of free pnics, at least 2 pnics are needed,
       * one will be used for vds and the other'll be used for opaque network.
       */
      host1_pnics = getFreeUpPNics(firstHost);
      assertTrue((host1_pnics != null && host1_pnics.length >= 2),
               "At least 2 pnics are needed for host1");
      host2_pnics = getFreeUpPNics(secondHost);
      assertTrue((host2_pnics != null && host2_pnics.length >= 2),
               "At least 2 pnics are needed for host2");

      /*
       *  create a vds in the network folder
       */
      vds = new DistributedVirtualSwitch(connectAnchor);
      dcMor = this.folder.getDataCenter();
      String vdsName = "vds-test-33";
      DVSConfigSpec vdsConfigSpec = DVSUtil.createDefaultDVSConfigSpec(vdsName);
      vdsMor = folder.createDistributedVirtualSwitch(
               folder.getNetworkFolder(dcMor), vdsConfigSpec);
      /*
       * Add a host and a free pnic on the host to the vds
       */
      Map<ManagedObjectReference, String> pNicMap = null;
      pNicMap = new HashMap<ManagedObjectReference, String>();
      pNicMap.put(firstHost, host1_pnics[0]);
      pNicMap.put(secondHost, host2_pnics[0]);
      assertTrue(
               DVSUtil.addHostsWithPnicsToDVS(connectAnchor, vdsMor, pNicMap),
               "Successfully added the free pnic on the host to the vds",
               "Failed to add the free pnic on the host to the vds");
      /*
       * Add a portgroup on the vds
       */
      DVPortgroupConfigSpec[] portgrpSpecArray = new DVPortgroupConfigSpec[1];
      portgrpSpecArray[0] = new DVPortgroupConfigSpec();
      portgrpSpecArray[0].setName("vds-pg-1");
      portgrpSpecArray[0].setNumPorts(16);
      pgKey = this.vds.addPortGroup(vdsMor,
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 10, "vds-pg-1");

      String vds_uuid = vds.getConfig(vdsMor).getUuid();
      DistributedVirtualSwitchPortConnection portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(vds_uuid);
      portConnection.setPortgroupKey(pgKey);
      vnic_id1 = DVSUtil.addVnic(connectAnchor, firstHost, portConnection);
      vnic_id2 = DVSUtil.addVnic(connectAnchor, secondHost, portConnection);
      HostVirtualNic hostVnic1 = getHostVirtualNic(nsMor1, vnic_id1);
      HostVirtualNic hostVnic2 = getHostVirtualNic(nsMor2, vnic_id2);
      /*
       * enable ft for vmknic on vds;
       */
      boolean result = false;
      VirtualNicManager vnManager = new VirtualNicManager(connectAnchor);
      result = (boolean) vnManager.modifyvmkNicType(firstHost,
               HostVirtualNicManagerNicType.FAULT_TOLERANCE_LOGGING.value(),
               hostVnic1, true).get(0);
      message = " to set FT logging for " + vnic_id1 + " on " + firstHostName;
      assertTrue(result, "Succeeded" + message, "Faield" + message);
      result = (boolean) vnManager.modifyvmkNicType(secondHost,
               HostVirtualNicManagerNicType.FAULT_TOLERANCE_LOGGING.value(),
               hostVnic2, true).get(0);
      message = " to set FT logging for " + vnic_id2 + " on " + secondHostName;
      assertTrue(result, "Succeeded" + message, "Failed" + message);
      /*
       * Start nsxa on both hosts.
       */
      message = " to start nsxa on " + firstHostName;
      assertTrue(startNsxa(null, null, host1_pnics[1], firstHost), "Succeeded "
               + message, "Failed " + message);
      message = " to start nsxa on " + secondHostName;
      assertTrue(startNsxa(null, null, host2_pnics[1], secondHost),
               "Succeeded " + message, "Failed " + message);
      /*
       * Query for the opaque network
       */
      getOpaqueNetwork(this.firstHost);
      assertTrue(opaqueNetworkInfo.size() > 0, "No opaque network was found.");
      /*
       * Set up one test vm to reconfigure vnic to connect to opaque networking.
       */
      oneTestVmSetup(false);

      return true;
   }

   @Test(description = "FT works OK with VM whose vnic's "
            + "connecting to opaque network")
   public void test()
      throws Exception
   {
      /*
       * Case -1
       * Create secondary for a powered off vm
       */
      FaultToleranceSecondaryOpResult ftOpResult = this.vm.createSecondaryVM(
               vmMor, secondHost);
      /*
       * Verify secondary VM is created successfully.
       */
      secondaryVmMor = ftOpResult.getVm();
      assertNotNull(secondaryVmMor, "Succeeded to get secondary VM Mor",
               "secondary VM Mor is null");
      assertTrue(
               this.vm.getVMState(this.vmMor).equals(
                        VirtualMachinePowerState.POWERED_OFF),
               "Found primary VM in powered off state",
               "Could not find primary VM in powered off state");
      assertTrue(
               this.vm.getVMState(this.secondaryVmMor).equals(
                        VirtualMachinePowerState.POWERED_OFF),
               "Found secondary VM in powered off state",
               "Could not find secondary VM in powered OFF state");

      /*
       * Case -2
       * Power on vm and verify secondary vm is powered on too.
       */
      assertTrue(this.vm.setVMState(this.vmMor,
               VirtualMachinePowerState.POWERED_ON, true),
               "Powered on primary successfully",
               "Could not power ON primary VM");
      assertTrue(this.objFtHelper.waitForVMPowerState(this.secondaryVmMor,
               VirtualMachinePowerState.POWERED_ON,
               FTTestConstants.VM_POWERSTATE_WAIT),
               "Secondary VM powered on successfully",
               "Secondary VM could not be powered on");
      /*
       * Wait for primary FT state to be running
       */
      assertTrue(objFtHelper.waitForVMFTState(this.vmMor,
               VirtualMachineFaultToleranceState.RUNNING,
               FTTestConstants.VM_POWERSTATE_WAIT), "FT state is running",
               "Unable to find VM FT state in running");
      log.info("print primary vm fault tolerance state:");
      this.objFtHelper.printVMFaultToleranceState(this.vmMor);
      log.info("print secondary vm fault tolerance state:");
      this.objFtHelper.printVMFaultToleranceState(this.secondaryVmMor);

      /*
       * Test primary vm failover scenario
       */
      /*
       * Kill the primary vmx process
       */
      killVM(vmMor);
      log.info("Primary vmx process's killed successfully");
      /*
       * Wait for primary FT state to be running.
       * Note that while loop can't be used, use do-while
       * loop to make sure sleep 20 seconds before checking
       * state of secondary and primary vm. We can't check
       * the state tightly following killing vmx.
       */
      int count = 0;
      do {
         log.info("Waiting for FT to kick in");
         Thread.sleep(20000);
         ++count;
      } while (!(this.objFtHelper.getFaultToleranceState(this.secondaryVmMor).equals(
               VirtualMachineFaultToleranceState.RUNNING) && this.objFtHelper.getFaultToleranceState(
               this.vmMor).equals(VirtualMachineFaultToleranceState.RUNNING))
               && count <= 6);
      /*
      * Primary VM now should exist on the secondary host and
      * secondary VM should exist on the first host.
      */
      String primaryHostName = vm.getHostName(vmMor);
      log.debug("Originally primary host name is " + firstHostName);
      log.debug("Currently primay host name is " + primaryHostName);
      String secondarySecondName = vm.getHostName(secondaryVmMor);
      log.debug("Originally secondary host name is " + secondHostName);
      log.debug("Currently secondary host name is " + secondarySecondName);
      assertTrue(primaryHostName.equals(secondHostName),
               "Primary VM was migrated on the second host successfully",
               "Primary VM failed to migrate on second host.");
      assertTrue(secondarySecondName.equals(firstHostName),
               "Secondary VM was migrated on the first host successfully",
               "Secondary VM failed to migrate on the first host.");
   }

   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
      if (secondaryVmMor != null) {
         Thread.sleep(20 * 1000);
         this.vm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_OFF,
                  false);
         this.vm.turnOffFaultToleranceForVM(vmMor);
         secondaryVmMor = null;
      }
      if (vnic_id1 != null) {
         assertTrue(ins.removeVirtualNic(nsMor1, vnic_id1),
                  "Removed the vmkernel nic1",
                  "Failed to remove the vmkernel nic1");
      }
      if (vnic_id2 != null) {
         assertTrue(ins.removeVirtualNic(nsMor2, vnic_id2),
                  "Removed the vmkernel nic2",
                  "Failed to remove the vmkernel nic2");
      }
      if (vdsMor != null) {
         vds.destroy(vdsMor);
      }
      super.testCleanUp();
      return true;
   }
}
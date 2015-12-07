/*
 * *****************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * *****************************************************************************
 */
package dvs.functional;



import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.VM_REGISTER_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_REGISTER_PASS;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.
   DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ClusterAttemptedVmInfo;
import com.vmware.vc.ClusterConfigSpecEx;
import com.vmware.vc.ClusterPowerOnVmResult;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DpmBehavior;
import com.vmware.vc.DrsBehavior;
import com.vmware.vc.HostConfigSpec;
import com.vmware.vc.HostProxySwitch;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.Datastore;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreInformation;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.StorageSystem;
import com.vmware.vcqa.vim.host.VmotionSystem;


/**
 * DESCRIPTION:<br>
 * Bug #424097 Cisco DVPort Use case
 * In a DRS + DPM cluster with two hosts (h1, h2)having two virtual machines
 * each and maximum proxy switch ports of four on each host connecting to a vds.
 * Connect the vmotion nic, physical nic on each host to the proxy switch port
 * and enter one host (h1) into standby mode.
 * TARGET: VC <br>
 * <br>
 * SETUP:<br>
 * 1. Create one virtual distributed switch<br>
 * 2. Extract the host profiles of the existing hosts
 * 3. Add two host members to the switch with maximum proxy switch ports as 4
 * and move free physical nics with wake on lan property enabled to the vds<br>
 * 4. Unregister existing virtual machines<br>
 * 5. Create 2 virtual machines on each host<br>
 * 6. Add a late binding portgroup on the vds and move the vmotion nics on the
 * <br> host to the vds<br>
 * 7. Move both the hosts into the cluster and set enter standby mode on one of
 * the hosts
 *
 * TEST:<br>
 * 8. Power on one virtual machine<br>
 * 9. Power on the other virtual machine at this point and verify that the<br>
 * the other host exists standby mode and this virtual machine is migrated<br>
 * to the other host and powered on<br>
 * CLEANUP:<br>
 * <br>
 * 10. Power off all the virtual machines and destroy the newly created vms<br>
 * 11. Apply the host profiles to restore the host's original network<br>
 * settings<br>
 * 12.Register the original virtual machines on the hosts<br>
 * 13.Remove the cluster
 * 14.Remove the vds
 *
 */
public class Pos049 extends TestBase
{

   private HostSystem ihs = null;
   private List<ManagedObjectReference> allHosts = null;
   private NetworkSystem ins = null;
   private Folder iFolder = null;
   private ManagedObjectReference dvsMor = null;
   private ManagedObjectReference nsMor = null;
   private VirtualMachine ivm = null;
   private DistributedVirtualSwitch iDVS = null;
   private String vdsUuid = null;
   private DistributedVirtualPortgroup iDvPortgroup = null;
   private List<ManagedObjectReference> vmMorList = null;
   private Map<ManagedObjectReference, VirtualMachineConfigSpec>
      vmMorConfigSpecMap = null;
   private String portgroupKey = null;
   private Map<String, String> vmPathMap =
      null;
   private Map<String, String> vmHostMap =
      null;
   private ManagedObjectReference clusterMor = null;
   private ManagedObjectReference hostFolderMor = null;
   private ClusterComputeResource icr = null;
   private ManagedObjectReference dcMor = null;
   private List<ManagedObjectReference> clusterHosts = null;
   private VmotionSystem iVMotionSystem = null;
   private String switchUuid = null;
   private Map<ManagedObjectReference, String> hostNameMap = null;
   private ManagedObjectReference hostSelectedForVmPowerOn = null;
   private ManagedObjectReference hostSelectedForEnterStandby = null;
   private List<ManagedObjectReference> vmsRegisteredOnHost = null;
   private int numAvailablePortBeforeEnterStandby = 0;
   private int numAvailablePortVmPowerOn = 0;
   private ServiceInstance iService = null;
   private List<ManagedObjectReference> allVmsList = null;
   private Datastore ids = null;
   private StorageSystem iss = null;
   private List<ManagedObjectReference> profileListMor = null;
   private List<ManagedObjectReference> newVmMorList = null;
   private Map<ManagedObjectReference, ManagedObjectReference>
      hostProfileMap  = null;
   private Datacenter idc = null;
   private HostConfigSpec srcHostConfigSpec1;
   private Map<ManagedObjectReference, HostConfigSpec> srcHostConfigSpecMap = null;


   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void
   setTestDescription()
   {
      setTestDescription("In a DRS + DPM cluster with two hosts (h1, h2)" +
         "having two virtual machines each and maximum proxy switch ports of " +
            "four on each host connecting to a vds.Connect the vmotion nic, " +
               "physical nic on each host to the proxy switch port and enter " +
                  "one host (h1) into standby mode. ");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    *
    * @param connectAnchor ConnectAnchor object
    *
    * @return boolean true if successful, false otherwise.
    *
    * @throws Exception
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      iService = new ServiceInstance(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
      iDVS = new DistributedVirtualSwitch(connectAnchor);
      iDvPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      icr = new ClusterComputeResource(connectAnchor);
      iVMotionSystem = new VmotionSystem(connectAnchor);
      iFolder = new Folder(connectAnchor);
      ids = new Datastore(connectAnchor);
      iss = new StorageSystem(connectAnchor);
      idc = new Datacenter(connectAnchor);
      this.dcMor = this.iFolder.getDataCenter();
      this.newVmMorList = new ArrayList<ManagedObjectReference>();
      assertNotNull(this.dcMor,"The datacenter mor is null");
      allHosts = ihs.getAllHost();
      assertTrue(allHosts != null && allHosts.size() >=2, "Found atleast " +
         "two hosts in the inventory","Failed to find two hosts in the " +
            "inventory");
      hostNameMap = new HashMap<ManagedObjectReference, String>();
      hostProfileMap = new HashMap<ManagedObjectReference,
         ManagedObjectReference>();
      srcHostConfigSpecMap=  new HashMap<ManagedObjectReference,HostConfigSpec>();
      profileListMor = new ArrayList<ManagedObjectReference>();
      for(ManagedObjectReference host : allHosts){
         String name = this.ihs.getHostName(host);
         hostNameMap.put(host, name);
         srcHostConfigSpec1 = NetworkResourcePoolHelper.
            extractHostConfigSpec(connectAnchor, name+"-hostprofile", host);
         assertNotNull(srcHostConfigSpec1, "The profile for " + name + "is null");
         srcHostConfigSpecMap.put(host, srcHostConfigSpec1);
      }
      /*
       * Unregister the existing vms
       */
      int noOfEthernetCards = 0;
      this.vmMorList = ivm.getAllVM();
      vmPathMap = new HashMap<String, String>();
      vmHostMap = new HashMap<String, String>();
      if(this.vmMorList != null && this.vmMorList.size()>=1){
         for(ManagedObjectReference vmMor : this.vmMorList) {
            String vmName = ivm.getName(vmMor);
            vmPathMap .put(vmName, this.ivm.getVMConfigInfo(vmMor).
               getFiles().getVmPathName());
            vmHostMap.put(vmName, this.ivm.getHostName(vmMor));
            assertTrue(ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false),"Failed to " +
                  "PowerOff " + vmName);
            assertTrue((this.ivm.unregisterVM(vmMor)),"Successfully " +
               "unregistered the VM :" + vmName,"Unable to unregister the " +
                  "VM :" + vmName);
         }
      }
      /*
       * Create a vds with two host members attached to it choosing two free
       * physical nics which have wake on lan property enabled.
       */
      DistributedVirtualSwitchHostMemberConfigSpec[] hostMemberList =
         new DistributedVirtualSwitchHostMemberConfigSpec[allHosts.size()];
      allVmsList = new ArrayList<ManagedObjectReference>();
      List<ManagedObjectReference> sharedDatastores = ids.getSharedDatastores(
         allHosts);
      assertNotEmpty(sharedDatastores, "There is no shared datastore between " +
         "the hosts");
      /*
       * Get the datastore info of the first shared datastore between the hosts
       */
      DatastoreInformation datastoreInfo = ids.getDatastoreInfo(
         sharedDatastores.get(0));
      for(int i = 0; i < allHosts.size(); i++) {
         ManagedObjectReference hostMor = allHosts.get(i);
         String[] freePnics = ins.getFreeWakeOnLanEnabledPhysicalNicIds(
            hostMor);
         String hostName = ihs.getHostName(hostMor);
         assertTrue(freePnics != null && freePnics[0] != null,
            "There are no free pnics on " + hostName);
         hostMemberList[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
         hostMemberList[i].setOperation(TestConstants.CONFIG_SPEC_ADD);
         hostMemberList[i].setHost(hostMor);
         /*
          * Set maximum proxy switch ports to four
          */
         hostMemberList[i].setMaxProxySwitchPorts(4);
         DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new
            DistributedVirtualSwitchHostMemberPnicBacking();
         DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new
            DistributedVirtualSwitchHostMemberPnicSpec();
         pnicSpec.setPnicDevice(freePnics[0]);
         pnicBacking.getPnicSpec().clear();
         pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new
            DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
         hostMemberList[i].setBacking(pnicBacking);
         /*
          * Create two virtual machines on the shared storage
          */
         for(int j=0;j<2;j++){
            ManagedObjectReference vmMor = iss.createVirtualMachine(ihs,
               allHosts.get(i), ivm, hostName+"_vm"+j, datastoreInfo);
            assertNotNull(vmMor,"The virtual machine " + hostName +
               "_vm"+j + " could not be created on the shared datastore");
            this.newVmMorList.add(vmMor);
         }
      }
      DVSConfigSpec dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(this.getTestId());
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostMemberList));
      String[] uplinkPortNames = new String[]{"Uplink1"};
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new
         DVSNameArrayUplinkPortPolicy();
      uplinkPolicyInst.getUplinkPortName().clear();
      uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
      dvsConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
      this.dvsMor = this.iFolder.createDistributedVirtualSwitch(
         this.iFolder.getNetworkFolder(this.iFolder.getDataCenter()),
            dvsConfigSpec);
      assertNotNull(this.dvsMor,"Successfully created the vds","Failed to " +
         "create the vds");
      this.switchUuid = this.iDVS.getConfig(dvsMor).getUuid();
      /*
       * Add a late binding portgroup to the vds
       */
      DVPortgroupConfigSpec pgConfigSpec =  new DVPortgroupConfigSpec();
      pgConfigSpec.setNumPorts(8);
      pgConfigSpec.setType(DVPORTGROUP_TYPE_LATE_BINDING);
      pgConfigSpec.setName(this.getTestId()+"-lpg");
      List<ManagedObjectReference> pgMors = this.iDVS.addPortGroups(this.dvsMor,
         new DVPortgroupConfigSpec[]{pgConfigSpec});
      assertTrue(pgMors != null && pgMors.size() ==1, "Failed to add the " +
         "late binding portgroup");
      portgroupKey = this.iDvPortgroup.getKey(pgMors.get(0));
      assertNotNull(portgroupKey,"The portgroup key is null");
      this.vmMorConfigSpecMap = new HashMap<ManagedObjectReference,
         VirtualMachineConfigSpec>();
      /*
       * Migrate vmotion nics on the hosts to the vds
       */
      for(ManagedObjectReference host : allHosts){
         DVSUtil.migrateVmotionNicsToVds(connectAnchor, host, dvsMor,
            DVSUtil.buildDistributedVirtualSwitchPortConnection(this.switchUuid,
               null, portgroupKey));
      }
      /*
       * Reconfigure all the virtual machines to connect to the late binding
       * portgroup on the vds
       */
      for(ManagedObjectReference vmMor : this.newVmMorList){
         DVSUtil.reconfigVM(vmMor, this.dvsMor, connectAnchor, null,
            portgroupKey);
      }
      hostFolderMor = iFolder.getHostFolder(dcMor);
      /*
       * Move all the hosts into a new cluster
       */
      ClusterConfigSpecEx clusterSpecEx = iFolder.createClusterConfigSpecEx();
      clusterMor = iFolder.createClusterEx(hostFolderMor, getTestId(),
         clusterSpecEx);
      assertNotNull(clusterMor, "Created Cluster "+ icr.getName(clusterMor),
         "Failed to create Cluster.");
      assertTrue(icr.moveInto(clusterMor, allHosts.toArray(new
         ManagedObjectReference[0])),"Moved hosts into cluster " + icr.getName(
            clusterMor),"Failed to move hosts into cluster "+
               icr.getName(clusterMor));
      assertTrue(icr.setDRS(clusterMor, true, DrsBehavior.FULLY_AUTOMATED),
         "Enabled DRS on cluster","Failed to enable DRS on cluster");
      assertTrue(icr.setDRSVmotionRate(clusterMor,TestConstants.
         DRS_DEFAULT_VMOTIONRATE),"DRS Cluster VMotionRate is set to " +
            TestConstants.DRS_DEFAULT_VMOTIONRATE,"Error while setting drs " +
               "cluster vmotion rate");
      clusterHosts = icr.getHosts(clusterMor);
      for(ManagedObjectReference host : clusterHosts){
         HostProxySwitch hostProxySwitch = com.vmware.vcqa.util.TestUtil.vectorToArray(ins.getNetworkInfo(ins.
               getNetworkSystem(host)).getProxySwitch(), com.vmware.vc.HostProxySwitch.class)[0];
         numAvailablePortVmPowerOn = hostProxySwitch.getNumPortsAvailable();
         assertTrue(numAvailablePortVmPowerOn >0,"There are ports available " +
            "on host " + hostNameMap.get(host),"There are no ports available " +
               "on host " + hostNameMap.get(host));
         vmsRegisteredOnHost = ihs.getVMs(host, VirtualMachinePowerState.POWERED_OFF);
         if(vmsRegisteredOnHost != null && vmsRegisteredOnHost.size() >=
            numAvailablePortVmPowerOn) {
            hostSelectedForVmPowerOn = host;
            break;
         } else{
            log.error(hostNameMap.get(host) + " host does not have "
               + numAvailablePortVmPowerOn + " or more number of VMs.");
         }
      }
      hostSelectedForEnterStandby = clusterHosts.get(0) ==
         hostSelectedForVmPowerOn ? clusterHosts.get(1): clusterHosts.get(0);
      log.info("Host where VMs will be Powered on : " + hostNameMap.get(
         hostSelectedForVmPowerOn));
      log.info("Host which will be entered Standby : "
         + hostNameMap.get(hostSelectedForEnterStandby));
      assertTrue(icr.setDPM(clusterMor, true, DpmBehavior.MANUAL), "Enabled " +
         "DPM on cluster","Failed to enable DPM on cluster");
      assertTrue(icr.setDPMPowerActionRate(clusterMor, 1),"Set DPM Power " +
         "Action rate to Aggressive.","Failed to set DPM Power Action rate " +
            "to Aggressive.");
      HostProxySwitch proxySwitch = com.vmware.vcqa.util.TestUtil.vectorToArray(ins.getNetworkInfo(
            ins.getNetworkSystem(hostSelectedForEnterStandby)).getProxySwitch(), com.vmware.vc.HostProxySwitch.class)[0];
      numAvailablePortBeforeEnterStandby = proxySwitch.getNumPortsAvailable();
      icr.refreshRecommendation(clusterMor);
      /*
       * When putting the host into Standby, set DPM to manual to ensure, DPM
       * does not pick any other host to enter Standby in the mean time.
       */
      assertTrue(ihs.enterStandbyMode(hostSelectedForEnterStandby,0, false),
         hostNameMap.get(hostSelectedForEnterStandby)+ " entered Standby " +
            "successfully ", hostNameMap.get(hostSelectedForEnterStandby)
                  + " failed to enter Standby ");
      assertTrue(icr.setDPM(clusterMor, true, DpmBehavior.AUTOMATED),
         "Enabled DPM on cluster","Failed to enable DPM on cluster");
      return true;
   }

   /**
    *
    * @throws Exception
    */
   @Test(description = "In a DRS + DPM cluster with two hosts (h1, h2)" +
         "having two virtual machines each and maximum proxy switch ports of " +
            "four on each host connecting to a vds.Connect the vmotion nic, " +
               "physical nic on each host to the proxy switch port and enter " +
                  "one host (h1) into standby mode. ")
   public void test()
      throws Exception
   {
      List<ManagedObjectReference> vmsPoweredOnHost = new ArrayList
         <ManagedObjectReference>();
      ManagedObjectReference virtualMachineToMigrateMor= null;
      vmsPoweredOnHost.add(vmsRegisteredOnHost.get(0));
      virtualMachineToMigrateMor = vmsRegisteredOnHost.get(1);
      /*
       * TODO Please insert a loop here and remove other parts of the code
       */
      ClusterPowerOnVmResult powerOnVMResult = idc.powerOnVm(dcMor,
         vmsPoweredOnHost.toArray(new ManagedObjectReference[
            vmsPoweredOnHost.size()]),false);
      /*
       * Verify that the virtual machines was attempted to be powered on
       */
      ClusterAttemptedVmInfo[] vmAttempted = com.vmware.vcqa.util.TestUtil.vectorToArray(powerOnVMResult.getAttempted(), com.vmware.vc.ClusterAttemptedVmInfo.class);
      assertTrue(vmAttempted.length == 1, "Could not power on a virtual " +
         "machine on the first host");
      Calendar filterStartTime = iService.getServerCurrentTime();
      /*
       * Introduce a delay be
       */
      Thread.sleep(15000);
      /*
       * Power on the other virtual machine and check whether the other host
       * exited standbymode
       */
      ClusterPowerOnVmResult powerOnVMResultToMigrate = idc.
         powerOnVm(dcMor, new ManagedObjectReference[]{
            virtualMachineToMigrateMor},false);
      assertTrue(ihs.monitorStandbyModeTasks(TestConstants.DPM_EXITSTANDBY_TASK,
         1,0,filterStartTime),"The second host " +
            "exited from standby mode successfully.","None of the hosts " +
               "exited from standby mode.");
      /*
       * Verify that the virtual machine is powered on after migrating to the
       * other host
       */
      int itr=0;
      List<ManagedObjectReference> vmPowerOnList = null;
      while(itr < 10) {
         vmPowerOnList = ihs.getVMs(hostSelectedForEnterStandby, VirtualMachinePowerState.POWERED_ON);
         if(vmPowerOnList!=null && vmPowerOnList.size()== 1) {
            log.info("VM got powered on once "+ ihs.getHostName(
               hostSelectedForEnterStandby)+ " exited from standby mode");
               break;
         } else {
            log.warn("VM was not powered on yet "+ ihs.getHostName(
               hostSelectedForEnterStandby) + " exited from Standby");
            log.info(" Wait for few seconds for VM to get Powered on");
            Thread.sleep(20* 1000);
         }
         itr++;
      }
      assertTrue((vmPowerOnList != null) && (vmPowerOnList.size() == 1),
         "The virtual machine on the second host that exited standby mode " +
            "was successfully powered on","The virtual machine on the second "
               +"host that exited standby mode could not be powered on");
   }

   /**
    * @throws Exception
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      /*
       * Destroy all the new virtual machines
       */
      for(ManagedObjectReference vmMor : this.newVmMorList){
         String vmName = ivm.getName(vmMor);
         ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false);
         assertTrue(ivm.destroy(vmMor),"Successfully destroyed the vm : " +
            vmName, "Failed to destroy the vm : " + vmName);
      }
      /*
       * Apply the host profiles on the host to restore the state of the host
       */
      for(int i=0 ;i < allHosts.size() ; i++){
         assertTrue(NetworkResourcePoolHelper.applyHostConfig(
            connectAnchor, allHosts.get(i),srcHostConfigSpecMap.get(allHosts.get(i))),"Successfully applied and deleted the profile",
                  "Failed to apply and delete the profile");
         if(!ihs.isHostInMaintenanceMode(allHosts.get(i))){
            ihs.enterMaintenanceMode(allHosts.get(i), 0, false);
         }
      }
      /*
       * Move the hosts out of the cluster
       */
      assertTrue(iFolder.moveInto(iFolder.getHostFolder(dcMor), allHosts.
         toArray(new ManagedObjectReference[allHosts.size()])),
            "Successfully moved the hosts outside the cluster into the " +
               "datacenter","Failed to move the hosts out of the cluster");
      for(int i=0;i<allHosts.size();i++){
         assertTrue(ihs.exitMaintenanceMode(allHosts.get(i), 0),
            "Successfully exited maintenance mode for " + ihs.getHostName(
               allHosts.get(i)) + "Failed to exit maintenance mode for " +
                  ihs.getHostName(allHosts.get(i)));
      }
      /*
       * Register the original virtual machines back into the hosts
       */
      if (vmPathMap != null && vmPathMap.size() > 0) {
         for (String vmName : vmPathMap.keySet()) {
            ManagedObjectReference hostMor =  this.ihs.getHost(this.vmHostMap.
               get(vmName));
            assertNotNull(this.iFolder.registerVm(this.iFolder.getVMFolder(
               this.dcMor), vmPathMap.get(vmName), vmName,false,
                  this.ihs.getResourcePool(hostMor).get(0),hostMor),
                     VM_REGISTER_PASS + vmName, VM_REGISTER_FAIL + vmName);
         }
      }
      /*
       * Remove the cluster
       */
      assertTrue(icr.destroy(this.clusterMor),"Successfully destroyed the " +
         "cluster","Failed to destroy the cluster");
      /*
       * Remove the vds
       */
      assertTrue(iDVS.destroy(dvsMor),"Successfully removed the vds","Failed " +
         "to remove the vds");
      return true;
   }
}

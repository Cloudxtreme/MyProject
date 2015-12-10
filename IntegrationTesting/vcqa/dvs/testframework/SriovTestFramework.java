package com.vmware.vcqa.vim.dvs.testframework;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.Vector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.vmware.vc.ConfigTarget;
import com.vmware.vc.HostConfigManager;
import com.vmware.vc.HostPciDevice;
import com.vmware.vc.HostSriovConfig;
import com.vmware.vc.HostSriovInfo;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceConfigSpecOperation;
import com.vmware.vc.VirtualEthernetCardNetworkBackingInfo;
import com.vmware.vc.VirtualMachineConfigOption;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePciPassthroughInfo;
import com.vmware.vc.VirtualPCIPassthroughDeviceBackingInfo;
import com.vmware.vc.VirtualSriovEthernetCard;
import com.vmware.vc.VirtualSriovEthernetCardSriovBackingInfo;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.EnvironmentBrowser;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.VMSpecManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.PciPassthruSystem;

/**
 * This class represents the subsystem for LAG configuration operations.It
 * encompasses all possible states and transitions in any scenario (positive/
 * negative/security) with respect to LAG feature
 */

public class SriovTestFramework
{

   private List<Step>                             stepList         = null;
   private DataFactory                            xmlFactory       = null;
   private final ManagedObjectReference           vdsMor           = null;
   private ManagedObjectReference                 dcMor            = null;
   private ManagedObjectReference                 hostMor          = null;
   private ManagedObjectReference                 nwSystemMor      = null;
   private Folder                                 folder           = null;
   private HostSystem                             hs               = null;
   private NetworkSystem                          ns               = null;
   private ConnectAnchor                          anchor           = null;
   private short                                  deviceid;
   private String                                 id               = null;
   private Short                                  vendorid         = null;
   private final String                           systemId         = null;
   private VirtualMachine                         vm               = null;
   private String                                 deviceName       = null;
   private PciPassthruSystem                      pcisys           = null;
   private List<String>                           pciIds           = null;
   private ManagedObjectReference                 pciMor           = null;
   private HostConfigManager                      hsmgr            = null;
   private VirtualMachinePciPassthroughInfo       pci[]            = null;
   private HostSriovConfig                        hostSriovCfg     = null;
   private VirtualPCIPassthroughDeviceBackingInfo invalidPFBacking = null;
   private ManagedObjectReference                 aVmMor           = null;
   boolean                                        vmCreated;
   private VDSTestFramework                       vdsTestFramework = null;
   protected static final Logger                  log              = LoggerFactory
                                                                         .getLogger(TestBase.class);

   /*
    * Constructor which is used to instantiate attributes' variables
    */
   public SriovTestFramework(ConnectAnchor connectAnchor, String xmlFilePath)
         throws Exception
   {
      anchor = connectAnchor;
      folder = new Folder(connectAnchor);
      dcMor = folder.getDataCenter();
      xmlFactory = new DataFactory(xmlFilePath);
      stepList = new ArrayList<Step>();
      hs = new HostSystem(connectAnchor);
      ns = new NetworkSystem(connectAnchor);
      vm = new VirtualMachine(connectAnchor);
      pcisys = new PciPassthruSystem(connectAnchor);
      pciIds = new ArrayList<String>();
      // Get one host which is used to do the below testing and get network
      // system MOR
      hostMor = hs.getConnectedHost(null);
      assertNotNull(hostMor, "There is no connected host");
      log.info("Using the host " + this.hs.getHostName(this.hostMor));
      hsmgr = hs.getHostConfigManager(hostMor);
      pciMor = hsmgr.getPciPassthruSystem();
      nwSystemMor = ns.getNetworkSystem(this.hostMor);
      Assert.assertNotNull(nwSystemMor, "Network System MOR is null!");
      vmCreated = false;
      vdsTestFramework = new VDSTestFramework(connectAnchor, xmlFilePath);
   }

   /**
    * This method initializes the data pertaining to the step as mentioned in
    * the data file.
    * 
    * @param stepName
    * 
    * @throws Exception
    */
   public void init(String stepName) throws Exception
   {
      Step step = getStep(stepName);
      if (step != null) {
         List<String> data = step.getData();
         if (data != null) {
            List<Object> objIdList = this.xmlFactory.getData(data);
            if (objIdList != null) {
               initData(objIdList);
            }
         }
      }
   }

   /**
    * This method performs the basic test setup needed for the test
    * 
    * @throws Exception
    */
   public void testSetup() throws Exception
   {
      List<Object> objIdList = this.xmlFactory.getData(getStep("testSetup")
            .getData());
      initData(objIdList);
   }

   /**
    * This method initializes the data for input parameters like selection sets
    * and runtime.
    * 
    * @param objIdList
    * 
    * @throws Exception
    */
   public void initData(List<Object> objIdList) throws Exception
   {

      for (Object object : objIdList) {
         if (object instanceof HostSriovConfig) {
            hostSriovCfg = (HostSriovConfig) object;
         }
         if (object instanceof VirtualPCIPassthroughDeviceBackingInfo) {
            invalidPFBacking = (VirtualPCIPassthroughDeviceBackingInfo) object;
         }
      }
      // More data type .....
   }

   /**
    * Method to execute a list of steps provided
    * 
    * @param stepList
    * 
    * @throws Exception
    */
   public void execute(List<Step> stepList) throws Exception
   {
      for (Step step : stepList) {
         Class currClass = Class.forName(step.getTestFrameworkName());
         Method method = currClass.getDeclaredMethod(step.getName());
         if (currClass.getName().equals(VDSTestFramework.class.getName())) {
            this.vdsTestFramework.addStep(step);
            method.invoke(this.vdsTestFramework);
         } else if (currClass.getName().equals(this.getClass().getName())) {
            addStep(step);
            method.invoke(this);
         }
      }
   }

   /**
    * This method adds a step to the list of steps
    * 
    * @param step
    */
   public void addStep(Step step)
   {
      this.stepList.add(step);
   }

   /**
    * This performs the most common cleanup operation of destroying all the
    * created vdses
    * 
    * @throws Exception
    */
   public void testCleanup() throws Exception
   {
      // remove the VM created
      if (vmCreated != false) {
         if (vm.getVMState(aVmMor).toString().matches("POWERED_ON")) {
            assertTrue(vm.powerOffVM(aVmMor), MessageConstants.VM_POWEROFF_FAIL);
         }
         vm.destroy(this.aVmMor);
      }
   }

   /**
    * This method sets the list of steps
    * 
    * @param stepList
    */
   public void setStepsList(List<Step> stepList)
   {
      this.stepList = stepList;
   }

   /**
    * This method gets the step associated with the step name. If the step is
    * not executed, return the step and change executed to true.
    * 
    * @param name
    * 
    * @return Step
    */
   public Step getStep(String name)
   {
      for (Step step : stepList) {
         if (step.getName().equals(name)) {
            if (!step.getExecuted()) {
               step.setExecuted(true);
               return step;
            }
         }
      }
      return null;
   }

   /**
    * Get all SRIOV physical nics.
    * 
    * @return Step
    * 
    * @throws Exception
    */
   public String[] getAllSriovNics() throws Exception
   {
      HostSriovInfo tmp;
      List<String> ids = new ArrayList<String>();
      // get SRIOV pNIC and store its id
      Assert.assertNotNull(pcisys, "pcisys is null!");
      Assert.assertNotNull(pciMor, "pciMor is null!");
      Object[] info = pcisys.getPCIPassthruInfo(pciMor);
      for (Object d : info) {
         if (d instanceof HostSriovInfo) {
            tmp = (HostSriovInfo) d;
            if (tmp.isPassthruCapable() == true) {
               ids.add(tmp.getId());
            }
         }
      }
      return ids.toArray(new String[ids.size()]);
   }

   /**
    * Get one SRIOV physical nic, and use it in testing.
    * 
    * @throws Exception
    */
   public void getOneSriovPnic() throws Exception
   {
      String[] sriovIds = this.getAllSriovNics();
      // Make sure there must have a SRIOV cards.
      Assert.assertTrue(sriovIds.length > 0,
            "There is no SRIOV cards on tested host!");
      this.id = sriovIds[0];
      // get vendorid, deviceid and device name
      HostPciDevice[] d = hs.getPciDeviceInfo(hostMor);
      for (HostPciDevice device : d) {
         if (device.getId().matches(this.id)) {
            log.info("SRIOV deviceid = " + device.getDeviceId());
            deviceid = device.getDeviceId();
            log.info("SRIOV id = " + device.getId());
            id = device.getId();
            log.info("SRIOV vendorid = " + device.getVendorId());
            vendorid = device.getVendorId();
            log.info("SRIOV device name = " + device.getDeviceName());
            deviceName = device.getDeviceName();
         }
      }
      Assert.assertTrue(this.deviceid != 0, "deviceid is 0!");
      Assert.assertNotNull(this.vendorid, "vendorid is empty");
      Assert.assertNotNull(this.deviceName, "deviceName is empty");
      // get systemid
      EnvironmentBrowser ieb = new EnvironmentBrowser(this.anchor);
      ConfigTarget confTarget = ieb.queryConfigTarget(hs
            .getHostEnvironment(hostMor), hostMor);
      if (confTarget != null) {
         pci = com.vmware.vcqa.util.TestUtil.vectorToArray(confTarget
               .getPciPassthrough(),
               com.vmware.vc.VirtualMachinePciPassthroughInfo.class);
      }
      // check version
      final ManagedObjectReference eb = hs.getHostEnvironment(hostMor);
      final VirtualMachineConfigOption configOption = ieb.queryConfigOption(eb,
            null, hostMor);
      String hwVersion = configOption.getVersion();
      log.info("version is " + hwVersion);

   }

   /**
    * Reboot ESX host
    * 
    * @throws Exception
    */
   public void rebootHost() throws Exception
   {
      Assert.assertNotNull(hostMor, "hostMor is null!");
      hs.rebootHost(hostMor, this.anchor.getPort(), true, null, null);
   }

   /**
    * Update SRIOV configuration
    * 
    * @throws Exception
    */
   public void updateSriovCfg() throws Exception
   {
      boolean result = false;
      init("updateSriovCfg");
      Assert.assertNotNull(hostSriovCfg, "hostMor is null!");
      hostSriovCfg.setId(this.id);
      result = pcisys.updatePassthruConfig(pciMor,
            new HostSriovConfig[] { hostSriovCfg }, hostSriovCfg
                  .isSriovEnabled());
      Assert.assertTrue(result, "Update SRIOV config failed!");
   }

   /**
    * Check SRIOV configuration after reboot.
    * 
    * @throws Exception
    */
   public void checkSriovCfg() throws Exception
   {
      Object[] info = pcisys.getPCIPassthruInfo(pciMor);
      HostSriovInfo tmp, currentCfg = null;
      for (Object d : info) {
         if (d instanceof HostSriovInfo) {
            tmp = (HostSriovInfo) d;
            String s = tmp.getId();
            if (s.matches(this.id)) {
               currentCfg = tmp;
            }
         }
      }
      Assert.assertNotNull(currentCfg,
            "Can not find SRIOV info of testing pNIC");
      Assert.assertTrue(
            currentCfg.getNumVirtualFunctionRequested() == hostSriovCfg
                  .getNumVirtualFunction(), "VF number is not equal!");
      Assert.assertTrue(currentCfg.isSriovEnabled() == hostSriovCfg
            .isSriovEnabled(), "SRIOV enanbled mismatch");
      log.info("SRIOV configuration checked successfully");
   }

   /**
    * Get one VM from a host member of DVS and set its sched.mem.min as memsize.
    * 
    * @throws Exception
    */
   public void setupVMMemory() throws Exception
   {
      Vector<ManagedObjectReference> hostVms;
      VirtualMachineConfigSpec vmCfg;
      hostVms = hs.getAllVirtualMachine(this.hostMor);
      // if there is no VM on host, create a new one.
      if (hostVms == null) {
         hostVms = DVSUtil.createVms(anchor, hostMor, 1, 1);
         vmCreated = true;
      }
      Assert.assertNotEmpty(hostVms, MessageConstants.VM_GET_FAIL);
      aVmMor = hostVms.get(0);
      String state = vm.getVMState(aVmMor).toString();
      log.info("Got '{}' VM's in host {}", hostVms.size(), hostMor);
      log.info("the VM state is " + state);
      // poweroff first
      if (vm.getVMState(aVmMor).toString().matches("poweredOn")) {
         assertTrue(vm.powerOffVM(aVmMor), MessageConstants.VM_POWEROFF_FAIL);
      }
      // For SRIOV vm, sched.mem.min must be equal to memsize
      vmCfg = new VirtualMachineConfigSpec();
      vmCfg.setMemoryReservationLockedToMax(true);
      vmCfg.setVersion("vmx-10");
      assertTrue(vm.reconfigVM(aVmMor, vmCfg), "Failed to reconfig VM");
      log.info("set sched.mem.min = memsize successfully.");
   }

   /**
    * Add a SRIOV VF on a VM.
    * 
    * @throws Exception
    */
   public void addOneVFOnVM(VirtualPCIPassthroughDeviceBackingInfo pfbacking)
         throws Exception
   {
      VirtualMachineConfigSpec vmConfigSpec = new VirtualMachineConfigSpec();
      VMSpecManager vmSpecManager = new VMSpecManager(this.anchor, hs
            .getPoolMor(hostMor), this.hostMor);

      List<VirtualDeviceConfigSpec> vdConfigSpec = new ArrayList<VirtualDeviceConfigSpec>();
      VirtualDeviceConfigSpec ethernetCardSpec = vmSpecManager
            .createEthCardSpec(vdConfigSpec, VirtualSriovEthernetCard.class,
                  null, null);
      ((VirtualSriovEthernetCard) ethernetCardSpec.getDevice())
            .setAllowGuestOSMtuChange(true);
      VirtualSriovEthernetCardSriovBackingInfo sriovBacking = new VirtualSriovEthernetCardSriovBackingInfo();
      sriovBacking.setPhysicalFunctionBacking(pfbacking);
      ((VirtualSriovEthernetCard) ethernetCardSpec.getDevice())
            .setSriovBacking(sriovBacking);
      ((VirtualSriovEthernetCard) ethernetCardSpec.getDevice())
            .setAddressType("Generated");
      vdConfigSpec.add(ethernetCardSpec);
      vmConfigSpec.getDeviceChange().clear();
      vmConfigSpec.getDeviceChange().addAll(
            com.vmware.vcqa.util.TestUtil.arrayToVector(vdConfigSpec
                  .toArray(new VirtualDeviceConfigSpec[vdConfigSpec.size()])));
      vmConfigSpec.setVersion("vmx-10");
      // Set the network backing info
      VirtualEthernetCardNetworkBackingInfo b = new VirtualEthernetCardNetworkBackingInfo();
      b.setDeviceName("VM Network");
      ((VirtualSriovEthernetCard) ethernetCardSpec.getDevice()).setBacking(b);
      Assert.assertTrue(vm.reconfigVM(aVmMor, vmConfigSpec),
            "Failed to reconfig VM (add SRIOV vNIC)!");
   }

   /**
    * Add a SRIOV VF on a VM.
    * 
    * @throws Exception
    */
   public void addVFOnVM() throws Exception
   {
      VirtualPCIPassthroughDeviceBackingInfo pfbacking = new VirtualPCIPassthroughDeviceBackingInfo();

      pfbacking.setDeviceId(String.valueOf(deviceid));
      pfbacking.setId(id);
      pfbacking.setVendorId(vendorid);
      // pfbacking.setSystemId(systemId);
      pfbacking.setSystemId("BYPASS");
      pfbacking.setDeviceName(deviceName);

      // power off first
      if (vm.getVMState(aVmMor).toString().matches("POWERED_ON")) {
         assertTrue(vm.powerOffVM(aVmMor), MessageConstants.VM_POWEROFF_FAIL);
      }
      this.addOneVFOnVM(pfbacking);
      Assert.assertTrue(vm.powerOnVM(this.aVmMor, this.hostMor, false),
            "Failed to power on VM!");
      log.info("Added a new SRIOV vnic, and power it on successfully.");
   }

   /**
    * Add a SRIOV VF on a VM.
    * 
    * @throws Exception
    */
   public void addVFOnPoweredonVM() throws Exception
   {
      VirtualPCIPassthroughDeviceBackingInfo pfbacking = new VirtualPCIPassthroughDeviceBackingInfo();

      pfbacking.setDeviceId(String.valueOf(deviceid));
      pfbacking.setId(id);
      pfbacking.setVendorId(vendorid);
      // pfbacking.setSystemId(systemId);
      pfbacking.setSystemId("BYPASS");
      pfbacking.setDeviceName(deviceName);
      if (!vm.getVMState(aVmMor).toString().matches("POWERED_ON")) {
         Assert.assertTrue(vm.powerOnVM(this.aVmMor, this.hostMor, false),
               "Failed to power on VM!");
      }
      this.addOneVFOnVM(pfbacking);
      log
            .error("config SRIOV setting on powered-on VM should throw exception!");
   }

   /**
    * Remove the SRIOV vNIC from VM
    * 
    * @throws Exception
    */
   public void removeVFOnVM() throws Exception
   {
      VirtualMachineConfigSpec vmConfigSpec = new VirtualMachineConfigSpec();
      VMSpecManager vmSpecManager = new VMSpecManager(this.anchor, hs
            .getPoolMor(hostMor), this.hostMor);
      VirtualMachineConfigSpec original = vm.getVMConfigSpec(aVmMor);
      List<VirtualDeviceConfigSpec> existedCfg = original.getDeviceChange();
      List<VirtualDeviceConfigSpec> vdConfigSpec = new ArrayList<VirtualDeviceConfigSpec>();
      for (VirtualDeviceConfigSpec d : existedCfg) {
         VirtualDevice vd = d.getDevice();
         if (vd instanceof VirtualSriovEthernetCard) {
            vdConfigSpec.add(d);
            d.setOperation(VirtualDeviceConfigSpecOperation.REMOVE);
         }
      }
      vmConfigSpec.getDeviceChange().clear();
      vmConfigSpec.getDeviceChange().addAll(
            com.vmware.vcqa.util.TestUtil.arrayToVector(vdConfigSpec
                  .toArray(new VirtualDeviceConfigSpec[vdConfigSpec.size()])));
      if (vm.getVMState(aVmMor).toString().matches("POWERED_ON")) {
         assertTrue(vm.powerOffVM(aVmMor), MessageConstants.VM_POWEROFF_FAIL);
      }
      Assert.assertTrue(vm.reconfigVM(aVmMor, vmConfigSpec),
            "Failed to reconfig VM (remove SRIOV vNIC)!");
      Assert.assertTrue(vm.powerOnVM(this.aVmMor, this.hostMor, false),
            "Failed to power on VM!");
      log.info("removed an existed SRIOV vnic, and power it on successfully.");
   }

   /**
    * Add a invalid SRIOV VF on a VM.
    * 
    * @throws Exception
    */
   public void addInvalidVFOnVM() throws Exception
   {
      init("addInvalidVFOnVM");
      Assert.assertNotNull(invalidPFBacking, "Backing info is null!");
      // poweroff first
      if (vm.getVMState(aVmMor).toString().matches("POWERED_ON")) {
         assertTrue(vm.powerOffVM(aVmMor), MessageConstants.VM_POWEROFF_FAIL);
      }
      this.addOneVFOnVM(invalidPFBacking);
      // Poweron again
      Assert.assertTrue(vm.powerOnVM(this.aVmMor, this.hostMor, false),
            "Failed to power on VM!");
      log.error("config a invalid SRIOV setting should throw exception!");
   }
}

/* ************************************************************************
 * Copyright 2014 VMware, Inc. All rights reserved. -- VMware Confidential
 * ************************************************************************
 */
package com.vmware.vcqa.vim.dvs.testframework;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.configuration.HierarchicalConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.BoolPolicy;
import com.vmware.vc.DatastoreSummary;
import com.vmware.vc.Description;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DvsVmVnicResourcePoolConfigSpec;
import com.vmware.vc.HostConfigSummary;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostPortGroupSpec;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualSwitch;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.TaskInfo;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceBackingInfo;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceConfigSpecOperation;
import com.vmware.vc.VirtualDeviceConnectInfo;
import com.vmware.vc.VirtualDeviceDeviceBackingInfo;
import com.vmware.vc.VirtualDisk;
import com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo;
import com.vmware.vc.VirtualEthernetCardNetworkBackingInfo;
import com.vmware.vc.VirtualMachineCloneSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vc.VirtualMachineRelocateSpecDiskLocator;
import com.vmware.vc.VirtualMachineRuntimeInfo;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.LogUtil;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestDataHandler;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.Task;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.provisioning.DataFileConstants;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;
import com.vmware.vcqa.vim.xvcprovisioning.XvcProvisioningHelper;

/**
 * This class represents the subsystem for executing all types of vmotion
 * operations.It encompasses all possible states and transitions in any
 * scenario (positive/negative) with respect to vmotion
 *
 * @author ssaidapetpach
 */
public class XVmotionTestFramework
{
   private VDSTestFramework vdsTestFramework = null;
   private VDSTestFramework srcVdsTestFramework;
   private VDSTestFramework destVdsTestFramework;
   private ConnectAnchor connectAnchor = null;
   private ConnectAnchor srcConnectAnchor;
   private ConnectAnchor destConnectAnchor;
   private DistributedVirtualSwitch vds = null;
   private DistributedVirtualSwitch srcVds = null;
   private DistributedVirtualSwitch destVds = null;
   private Folder folder = null;
   private Folder srcFolder = null;
   private Folder destFolder = null;
   private HostSystem host = null;
   private HostSystem srcHost = null;
   private HostSystem destHost = null;
   private Datacenter dc = null;
   private Datacenter srcDc = null;
   private Datacenter destDc = null;
   private VirtualMachine virtualMachine = null;
   private VirtualMachine srcVirtualMachine = null;
   private VirtualMachine destVirtualMachine = null;
   private DistributedVirtualPortgroup vdsPortgroup = null;
   private DistributedVirtualPortgroup srcVdsPortgroup = null;
   private DistributedVirtualPortgroup destVdsPortgroup = null;
   private ProvisioningOpsStorageHelper storageHelper = null;
   private ProvisioningOpsStorageHelper srcStorageHelper;
   private ProvisioningOpsStorageHelper destStorageHelper;

   private ManagedObjectReference srcHostMor = null;
   private ManagedObjectReference destHostMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference clonedVmMor = null;
   private ManagedObjectReference srcDcMor;
   private ManagedObjectReference destDcMor = null;
   private ManagedObjectReference srcVdsMor = null;
   private ManagedObjectReference destVdsMor = null;
   private ManagedObjectReference dsMor = null;
   private ManagedObjectReference destDsMor = null;

   private DataFactory xmlFactory = null;
   private ArrayList<DvsVmVnicResourcePoolConfigSpec> vmVnicResPoolList = null;
   private List<Step> stepList = null;
   private CustomMap customMap = null;
   private static final Logger log = LoggerFactory
      .getLogger(NetIocTestFramework.class);
   private HostPortGroupSpec hostPortGroupSpec = null;
   private VirtualMachineRelocateSpec virtualMachineRelocateSpec = null;
   private VirtualMachineCloneSpec cloneSpec;
   private List<VirtualDeviceConfigSpec> ethernetCardListDeviceChange = null;
   private Map<String, String> ethMap = null;
   private HashMap<String, VirtualDeviceBackingInfo> ethBackInfoDestMap;
   private Boolean ifCrossDatastore = false;
   private String[] destKey = null;
   private String destIp = null;
   private String destDcName = null;
   private String vssPgName = TestConstants.VSSPGNAME;
   private String crossVc = null;
   private Boolean migrate = false;
   private VirtualDeviceBackingInfo destBackInfo = null;
   private String filePath = null;
   private String vmName = null;
   private SessionManager sessionManager;
   private ManagedObjectReference sessionMgrMor;
   private XvcProvisioningHelper xvcProvisioningHelper = null;
   private Boolean destVc = false;
   private Boolean onSameHost = false;
   private VirtualMachineRuntimeInfo vmRuntimeInfo = null;
   private Integer nicsNumberOfEachDvs;
   private Boolean specialCleanup = false;

   /**
    * Constructor
    *
    * @param connectAnchor
    * @param xmlFilePath
    * @throws Exception
    */
   public XVmotionTestFramework(ConnectAnchor connectAnchor, String xmlFilePath)
      throws Exception
      {
      this.srcFolder = new Folder(connectAnchor);
      this.srcVds = new DistributedVirtualSwitch(connectAnchor);
      this.srcHost = new HostSystem(connectAnchor);
      this.srcVirtualMachine = new VirtualMachine(connectAnchor);
      this.srcDc = new Datacenter(connectAnchor);
      this.srcDcMor = srcFolder.getDataCenter();
      this.xmlFactory = new DataFactory(xmlFilePath);
      this.stepList = new ArrayList<Step>();
      this.srcVdsTestFramework = new VDSTestFramework(connectAnchor, xmlFilePath);
      this.filePath = xmlFilePath;
      this.srcStorageHelper = new ProvisioningOpsStorageHelper(connectAnchor);
      this.srcVdsPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      this.srcConnectAnchor = connectAnchor;
      this.destConnectAnchor = connectAnchor;
      this.initCurrentConnectAnchor();
   }


   /**
    * Method to init current connectAnchor in case destVc and srcVc.
    *
    * @throws Exception
    */
   public void initCurrentConnectAnchor() throws Exception
   {
      destVc = false;
      this.init("initCurrentConnectAnchor");
      if (destVc) {
         this.connectAnchor = this.destConnectAnchor;
         this.folder = this.destFolder;
         this.vds = this.destVds;
         this.host =this.destHost;
         this.virtualMachine = this.destVirtualMachine;
         this.dc = this.destDc;
         this.vdsTestFramework = this.destVdsTestFramework;
         this.storageHelper = this.destStorageHelper;
         this.vdsPortgroup = this.destVdsPortgroup;
      } else {
         this.connectAnchor = this.srcConnectAnchor;
         this.folder = this.srcFolder;
         this.vds = this.srcVds;
         this.host =this.srcHost;
         this.virtualMachine = this.srcVirtualMachine;
         this.dc = this.srcDc;
         this.vdsTestFramework = this.srcVdsTestFramework;
         this.storageHelper = this.srcStorageHelper;
         this.vdsPortgroup = this.srcVdsPortgroup;
      }
   }


   /**
    * Method to execute a list of steps provided
    *
    * @param stepList
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
    * Method to initialize all the inventory components like
    * source host, destination host, vm etc.
    *
    * @throws Exception
    */
   public void initializeInventory() throws Exception
   {
      /*
       * Find the virtual machine to be used for migration / cloning
       * operations. This should have a valid guest os installed.
       */
      this.init("initializeInventory");
      this.crossVc = this.getValueFromObjectIdMap("crossvc");
      List<ManagedObjectReference> vmMorList = this.srcVirtualMachine.getAllVM();
      assertTrue((vmMorList != null && vmMorList.size() >= 1),
         "Found at least one vm in the inventory", "Failed to find a vm in "
            + "the inventory");
      this.vmMor = vmMorList.get(0);
      this.vmName = this.srcVirtualMachine.getName(this.vmMor);
      /*
       * Get the corresponding datastore on which this vm resides.This will be
       * the source datastore.
       */
      this.dsMor = this.srcStorageHelper.getVMConfigDatastore(this.vmMor);
      /*
       * Store the ethernet card network map for the virtual machine.
       */
      this.ethMap =
         NetworkUtil.getEthernetCardNetworkMap(this.vmMor, this.srcConnectAnchor);
      /*
       * Initialize the dest datacenter and dest datastore.
       */
      this.destDcMor = this.srcDcMor;
      this.destDsMor = this.dsMor;
      /*
       * Get the corresponding host on which this vm resides.This will be the
       * source host.
       */
      this.srcHostMor = this.srcVirtualMachine.getHost(this.vmMor);
      if (this.crossVc != null) {
         this.initializeSecondVC();
         this.destHostMor = this.destHost.getAllHost().elementAt(0);
      } else if (this.onSameHost) {
         this.destHostMor = this.srcHostMor;
      } else {
         /*
          * Pick any other host in the inventory that is not the
          * source host. This will be the destination host.
          */
         List<ManagedObjectReference> hostMorList =
            this.srcHost.getAllConnectedHosts(false);
         for (ManagedObjectReference mor : hostMorList) {
            if (!(this.srcHost.getHostName(mor).equals(this.srcHost
               .getHostName(this.srcHostMor)))) {
               this.destHostMor = mor;
               break;
            }
         }
      }
   }


   /**
    * Method to init the second vc destConnectAnchor
    *
    * @throws Exception
    */
   private void initializeSecondVC() throws Exception
   {
      this.destConnectAnchor =
         new ConnectAnchor(this.destIp, TestConstants.SSL_PORT);
      this.sessionManager = new SessionManager(this.destConnectAnchor);
      this.sessionMgrMor = this.sessionManager.getSessionManager();
      this.sessionManager.login(this.sessionMgrMor,
         TestConstants.SERVER_LINUX_USERNAME,
         TestConstants.SERVER_LINUX_PASSWORD, null);
      this.destFolder = new Folder(this.destConnectAnchor);
      this.destVds = new DistributedVirtualSwitch(this.destConnectAnchor);
      this.destHost = new HostSystem(this.destConnectAnchor);
      this.destVirtualMachine = new VirtualMachine(this.destConnectAnchor);
      this.destDc = new Datacenter(this.destConnectAnchor);
      this.destDcMor = this.destFolder.getDataCenter();
      this.destStorageHelper =
         new ProvisioningOpsStorageHelper(this.destConnectAnchor);
      this.destVdsPortgroup =
         new DistributedVirtualPortgroup(this.destConnectAnchor);
      this.destVdsTestFramework =
         new VDSTestFramework(this.destConnectAnchor, this.filePath);
   }


   /**
    * Method to add the source and destination hosts to the source and
    * destination vdses respectively.
    *
    * @throws Exception
    */
   public void addHostsToVds() throws Exception
   {
      this.init("addHostsToVds");
      /*
       * Get the list of vdses created
       */
      Map<String, ManagedObjectReference> vdsObjectIdMorMap =
         this.vdsTestFramework.getObjectIdVdsMorMap();
      /*
       * Based on the hostVdsMap, add the corresponding hosts to the vdses
       */
      if (this.customMap != null) {
         Map<String, List<String>> hostVdsPnicListMap =
            this.customMap.getObjectListIdMap();
         assertNotNull(hostVdsPnicListMap, "Found valid dvses to add the hosts",
            "Failed to find valid dvses to add the hosts");
         /*
          * Iterate through the keys in the map
          */
         for (String key : hostVdsPnicListMap.keySet()) {
            /*
             * Get the list of vdses
             */
            List<String> vdsspecList = hostVdsPnicListMap.get(key);
            ManagedObjectReference hostMor = null;
            if (DataFileConstants.HOST_TYPE_SRC.equals(key)) {
               hostMor = this.srcHostMor;
               this.srcVdsMor = vdsObjectIdMorMap.get(vdsspecList.get(0));
            } else {
               /*
                * Deal with condition the key is "dest"
                */
               hostMor = this.destHostMor;
               this.destVdsMor = vdsObjectIdMorMap.get(vdsspecList.get(0));
            }
            List<ManagedObjectReference> dvsMorList =
               new ArrayList<ManagedObjectReference>();
            for (String s : vdsspecList) {
               ManagedObjectReference dvsMor = vdsObjectIdMorMap.get(s);
               if (dvsMor == null) {
                  continue;
               }
               dvsMorList.add(dvsMor);
            }
            String hostName = null;
            hostName = this.host.getHostName(hostMor);
            if (nicsNumberOfEachDvs != null && nicsNumberOfEachDvs == 0) {
               assertTrue(DVSUtil.addPnicsAndHostToDVS(connectAnchor, hostMor,
                  dvsMorList, nicsNumberOfEachDvs),
                  "Successfully added the host " + hostName + " to the vdses",
                  "Failed to add the host " + hostName + " to the vdses");
               nicsNumberOfEachDvs = null;
            } else {
               assertTrue(DVSUtil.addFreePnicAndHostToDVS(this.connectAnchor,
                  hostMor, dvsMorList), "Successfully added free pnic on "
                  + hostName + " to the vdses", "Failed to add free pnic on "
                  + hostName + " to the vdses");
            }
         }
      }
   }


   /**
    * This method reconfigures virtual machine's vnics to vds Standalone ports
    * or vds portgroup key.
    */
   public void reconfigureVMVnic() throws Exception
   {
      this.init("reconfigureVMVnic");
      ManagedObjectReference pgMor = null;
      ManagedObjectReference vdsMor = this.getMor(TestConstants.VDS);
      pgMor = this.getMor(TestConstants.VDSPG);
      /*
       * Reconfigure the virtual machine to connect to dvports
       */
      Map<String, Map<String, Boolean>> ethernetCardMap =
         new HashMap<String, Map<String, Boolean>>();
      int i = 0;
      for (String dev : this.ethMap.keySet()) {
         Map<String, Boolean> portBoolMap = new HashMap<String, Boolean>();
         if (pgMor != null) {
            portBoolMap.put(this.destKey[0], true);
         } else {
            portBoolMap.put(this.destKey[i], false);
            i++;
         }
         ethernetCardMap.put(dev, portBoolMap);
      }
      /*
       * Reconfigure the virtual machine to connect to the configured port.
       */
      DVSUtil.reconfigureVMConnectToVdsPort(this.vmMor, this.connectAnchor,
         ethernetCardMap, this.vds.getConfig(vdsMor).getUuid());
   }


   /**
    * This method will get the mor created by vdstestframework, ether a vds mor
    * or a vds portgroup mor.
    *
    * @param key
    */
   private ManagedObjectReference getMor(String key)
   {
      ManagedObjectReference mor = null;
      String objId = this.getValueFromObjectIdMap(key);
      if (objId != null) {
         if (TestConstants.VDS.equals(key)) {
            mor = this.vdsTestFramework.getVdsMor(objId);
         } else if (TestConstants.VDSPG.equals(key)) {
            mor = this.vdsTestFramework.getVdsPortgroupMor(objId);
         }
      }
      return mor;
   }


   /**
    * This method configure relocateSpec with invalid value: vds uuid/vds port/
    * vds portgroup key
    *
    * @throws Exception
    */
   public void configInvalidValue() throws Exception
   {
      init("configInvalidValue");
      VirtualDevice vd = null;
      VirtualEthernetCardDistributedVirtualPortBackingInfo tmpBackingInfo = null;
      /*
       * The invalidType includ invalid host name, vss name, vds uuid, port, portgroup key and so on.
       */
      String invalidType = this.getValueFromObjectIdMap("invalidType");
      if (TestConstants.INVALID_HOST_NAME.equals(invalidType)) {
         this.virtualMachineRelocateSpec.setHost(this.srcHostMor);
      }  else if (TestConstants.VSS.equals(invalidType)) {
          for (VirtualDeviceConfigSpec spec : this.ethernetCardListDeviceChange) {
             vd = spec.getDevice();
             VirtualEthernetCardNetworkBackingInfo info =
                (VirtualEthernetCardNetworkBackingInfo) vd.getBacking();
             info.setDeviceName(TestConstants.VSWITCH_NAME);
             vd.setBacking(info);
          }
      } else {
         for (VirtualDeviceConfigSpec spec : this.ethernetCardListDeviceChange) {
            vd = spec.getDevice();
            tmpBackingInfo =
               (VirtualEthernetCardDistributedVirtualPortBackingInfo) vd
                  .getBacking();
            if (TestConstants.VDS.equals(invalidType)) {
               tmpBackingInfo.getPort().setSwitchUuid(invalidType);
            } else if (TestConstants.VDSPORT.equals(invalidType)){
               tmpBackingInfo.getPort().setPortKey(invalidType);
            } else if (TestConstants.VM_VIRTUALDEVICE.equals(invalidType)) {
               Description desc = new Description();
               desc.setLabel("This is an ethernet device description");
               desc.setSummary("This is an ethernet device description");
               vd.setDeviceInfo(desc);
            } else {
               /**
                * Deal with condition invalidType is 'vdspg'.
                */
               tmpBackingInfo.getPort().setPortgroupKey(invalidType);
            }
            vd.setBacking(tmpBackingInfo);
         }
      }
   }

   /**
    * This method create conflict port for the dest dvs
    *
    * @throws Exception
    */
   public void createConflictPort() throws Exception
   {
      DistributedVirtualSwitchPortConnection portConnection = new
         DistributedVirtualSwitchPortConnection();
      portConnection.setPortKey(this.destKey[0]);
      portConnection.setSwitchUuid(this.vds.getConfig(this.destVdsMor).getUuid());
      DVSUtil.addVnic(this.connectAnchor, this.destHostMor, portConnection);
      this.specialCleanup = true;
   }


   /**
    * This method generates the device change for the vm vnics to the
    * destination network
    *
    * @param deviceChangeType is the type of virtual device: vdspg, vdsport, vss
    * @param dcMor is the datacenter mor
    * @throws Exception
    */
   private void generateDeviceChange(String deviceChangeType, ManagedObjectReference dcMor) throws Exception
   {
      this.ethBackInfoDestMap = new HashMap<String, VirtualDeviceBackingInfo>();
      String label = null;
      int i = 0;
      String key = null;
      VirtualDevice vd = new VirtualDevice();
      this.ethernetCardListDeviceChange =
         DVSUtil.getAllVirtualEthernetCardDevices(this.vmMor, this.srcConnectAnchor);
      assertNotNull(this.ethernetCardListDeviceChange,
         "Successfully found ethernet cards on " + "the vm",
         "Failed to find ethernet cards on the vm");
      if (TestConstants.VDSPORT.equals(deviceChangeType)
         || TestConstants.VDSPG.equals(deviceChangeType)) {
         ManagedObjectReference vdsMor = null;
         if (this.destVdsMor != null) {
            vdsMor = this.destVdsMor;
         } else {
            vdsMor =
               this.folder.getDistributedVirtualSwitch(
                  this.folder.getNetworkFolder(dcMor), TestConstants.DEST_VDS);
         }
         for (VirtualDeviceConfigSpec spec : this.ethernetCardListDeviceChange) {
            vd = spec.getDevice();
            label = vd.getDeviceInfo().getLabel();
            if (vd.getBacking() instanceof VirtualDeviceBackingInfo) {
               VirtualDeviceConnectInfo connectInfo = vd.getConnectable();
               LogUtil.printDetailedObject(connectInfo, ":");
               DistributedVirtualSwitchPortConnection portConn =
                  new DistributedVirtualSwitchPortConnection();
               this.destBackInfo =
                  new VirtualEthernetCardDistributedVirtualPortBackingInfo();
               if (TestConstants.VDSPORT.equals(deviceChangeType)) {
                  key = this.destKey[i];
                  portConn.setPortKey(key);
               } else {
                  key = this.destKey[0];
                  portConn.setPortgroupKey(key);
               }
               portConn.setSwitchUuid(this.vds.getConfig(vdsMor).getUuid());
               ((VirtualEthernetCardDistributedVirtualPortBackingInfo) this.destBackInfo)
                  .setPort(portConn);
               this.ethBackInfoDestMap.put(label, this.destBackInfo);
               vd.setBacking(this.destBackInfo);
               spec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
               i++;
            }
         }
      } else if (TestConstants.NO.equals(deviceChangeType)) {
         for (VirtualDeviceConfigSpec spec : this.ethernetCardListDeviceChange) {
            vd = spec.getDevice();
            this.destBackInfo = vd.getBacking();
            this.ethBackInfoDestMap.put(label, this.destBackInfo);
         }
      }else {
         /*
          * Deal with condition the deviceChangeType is "vss"
          */
         for (VirtualDeviceConfigSpec spec : this.ethernetCardListDeviceChange) {
            vd = spec.getDevice();
            if (vd.getBacking() instanceof VirtualDeviceBackingInfo) {
               this.destBackInfo = new VirtualEthernetCardNetworkBackingInfo();
               ((VirtualDeviceDeviceBackingInfo) this.destBackInfo)
                  .setDeviceName(this.vssPgName);
               this.ethBackInfoDestMap.put(label, this.destBackInfo);
               vd.setBacking(this.destBackInfo);
               spec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
               i++;
            }
         }
      }
      assertNotNull(this.destBackInfo,
         "DestBackInfo generated by method generateDeviceChange is not null",
         "DestBackInfo generated by method generateDeviceChange is null");
      log.info("Sucessfully configured the destBackInfo for the vm");
   }


   /**
    * This method add a network device for vm.
    *
    * @throws Exception
    */
   public void addDeviceForVM() throws Exception
   {
      VirtualMachineConfigSpec newVMConfigSpec=
         DVSUtil.buildDefaultSpec(this.connectAnchor, this.destHostMor,
                              TestConstants.VM_VIRTUALDEVICE_ETHERNET_E1000E);
     VirtualDeviceConfigSpec newSpec = (VirtualDeviceConfigSpec)TestUtil.
         deepCopyObject(newVMConfigSpec.getDeviceChange().get(2));
     newSpec.setOperation(VirtualDeviceConfigSpecOperation.ADD);
     this.ethernetCardListDeviceChange.add(newSpec);
   }


   /**
    * This method verifies the backing on which the vm is connected to.
    *
    * @throws Exception
    */
   public void verifyVMBackingInfo() throws Exception
   {
      init("verifyBacking");
      String invalidType = this.getValueFromObjectIdMap("invalidType");
      String actualPortKey = null;
      String destPortKey = null;
      String actualPGKey = null;
      String destPGKey = null;
      this.ethernetCardListDeviceChange =
         DVSUtil.getAllVirtualEthernetCardDevices(this.vmMor,
            this.connectAnchor);
      VirtualDevice vd = null;
      for (VirtualDeviceConfigSpec spec : this.ethernetCardListDeviceChange) {
         String label = spec.getDevice().getDeviceInfo().getLabel();
         this.destBackInfo = this.ethBackInfoDestMap.get(label);
         if (this.destBackInfo != null) {
            vd = spec.getDevice();
            if (vd.getBacking() instanceof VirtualEthernetCardDistributedVirtualPortBackingInfo) {
               VirtualEthernetCardDistributedVirtualPortBackingInfo backInfo =
                  (VirtualEthernetCardDistributedVirtualPortBackingInfo) vd
                     .getBacking();
               VirtualEthernetCardDistributedVirtualPortBackingInfo tmpBackInfo =
                  (VirtualEthernetCardDistributedVirtualPortBackingInfo) this.destBackInfo;
               actualPGKey = backInfo.getPort().getPortgroupKey();
               actualPortKey = backInfo.getPort().getPortKey();
               destPortKey = tmpBackInfo.getPort().getPortKey();
               destPGKey = tmpBackInfo.getPort().getPortgroupKey();
               if (!TestConstants.VDS.equals(invalidType)) {
                  assertTrue(
                     backInfo.getPort().getSwitchUuid()
                        .equals(tmpBackInfo.getPort().getSwitchUuid()),
                     "The vm is connected to the destination vds: "
                        + tmpBackInfo.getPort().getSwitchUuid(),
                     "The vm is not connected to the destination vds: "
                        + tmpBackInfo.getPort().getSwitchUuid());
               } else {
                  assertTrue(
                     TestConstants.VDS.equals(backInfo.getPort().getSwitchUuid()),
                     "The vm is not connected to any vds.",
                     "The vm is connected to some destination vds which is "
                        + "invalid.");
               }
               if (destPortKey != null) {
                  if (actualPortKey != null ) {
                     assertTrue(destPortKey.equals(actualPortKey),
                        "The vm is connected to the destination portKey: "
                           + destPortKey,
                        "The vm is not connected to the destination portKey: "
                           + destPortKey);
                  } else if (TestConstants.VDSPORT.equals(invalidType)) {
                     log.info("The vm is not connected to any dvport key.");
                  } else {
                     log.error("The vm is not connected to destination dvport: "
                        + destPortKey);
                  }
               } else if (destPGKey != null) {
                  assertTrue(destPGKey.equals(actualPGKey),
                     "The vm is connected to the destination portgroupKey: "
                        + destPGKey,
                     "The vm is not connected to the destination portgroupKey: "
                        + destPGKey);
               } else {
                  log.error("There is no any data in tmpBackInfo.");
               }
            } else if (vd.getBacking() instanceof VirtualEthernetCardNetworkBackingInfo) {
               VirtualEthernetCardNetworkBackingInfo backInfo =
                  (VirtualEthernetCardNetworkBackingInfo) vd.getBacking();
               VirtualEthernetCardNetworkBackingInfo tmpBackInfo =
                  (VirtualEthernetCardNetworkBackingInfo) this.destBackInfo;
               assertTrue(
                  backInfo.getDeviceName().equals(tmpBackInfo.getDeviceName()),
                  "The vm is connected to the destination vswitch  portgroup",
                  "The vm is not connected to the destination vswitch portgroup");
            }
         }
      }
   }


   /**
    * This method generates the VmRelocateSpec.
    *
    * @throws Exception
    */
   public void generateVmRelocateSpec() throws Exception
   {
      this.init("generateVmRelocateSpec");
      String deviceChangeType = this.getValueFromObjectIdMap("deviceChangeType");
      ManagedObjectReference hostMor = null;
      ManagedObjectReference dcMor = null;
      if (this.migrate) {
         log.info("Configuring VM re-migration/re-cloning relocate spec");
         hostMor = this.srcHostMor;
         dcMor = this.srcDcMor;
         this.destVdsMor = this.srcVdsMor;
         this.srcConnectAnchor = this.destConnectAnchor;
         this.destDsMor = this.dsMor;
      } else {
         log.info("Configuring VM migration/cloning relocate spec");
         hostMor = this.destHostMor;
         dcMor = this.destDcMor;
         this.generateDestDatastore(hostMor, ifCrossDatastore);
      }
      this.generateDeviceChange(deviceChangeType, dcMor);
      this.virtualMachineRelocateSpec = new VirtualMachineRelocateSpec();
      this.virtualMachineRelocateSpec
         .setDeviceChange(this.ethernetCardListDeviceChange);
      this.virtualMachineRelocateSpec.setFolder(this.folder.getVMFolder(dcMor));
      this.virtualMachineRelocateSpec.setHost(hostMor);
      this.virtualMachineRelocateSpec.setPool(host.getResourcePool(hostMor).get(0));
      this.virtualMachineRelocateSpec.setDatastore(this.destDsMor);
      log.info("Successfully configed vm relocate spec");
   }


   /**
    * This method config the datastore of vmRelocateSpecDiskLocator.
    * If dest datastore is configured, then the vmdk and vmx file will both be
    * shifted to the dest datastroe; else, only vmx file will be shifted to the
    * dest datastore.
    *
    * @throws Exception
    */
   public void generateDiskLocator() throws Exception
   {
      init("generateDiskLocator");
      String locatorDS = this.getValueFromObjectIdMap("locatorDS");
      VirtualMachineRelocateSpecDiskLocator vmRelocateSpecDiskLocator = new
         VirtualMachineRelocateSpecDiskLocator();
      List<VirtualDisk> vDiskList = this.srcVirtualMachine.getVMDisks(this.vmMor);
      VirtualDisk disk = vDiskList.get(0);
      int vdiskKey = disk.getKey();
      vmRelocateSpecDiskLocator.setDiskId(vdiskKey);
      /**
       * If locatorDS is "dest", then this.destDsMor is the same datastore with
       * source datastore and the vmdk file will not be shifted.
       * Else, this.destDsMor is a different with source datastore, and the vmdk
       * file will be shifted to the new datastore.
       */
      if (!DataFileConstants.HOST_TYPE_DEST.equals(locatorDS)) {
         this.generateDestDatastore(this.destHostMor, false);
      }
      vmRelocateSpecDiskLocator.setDatastore(this.destDsMor);
      virtualMachineRelocateSpec.setDisk(Arrays.asList(vmRelocateSpecDiskLocator));
   }


   /**
    * This method set vm power status: on/off/suspended.
    *
    * @throws Exception
    */
   public void setVMPowerState() throws Exception
   {
      init("setVMPowerState");
      VirtualMachinePowerState vmPowerState = null;
      Boolean hasSnapshot = false;
      if (this.vmRuntimeInfo != null) {
         vmPowerState = this.vmRuntimeInfo.getPowerState();
         hasSnapshot = this.vmRuntimeInfo.isSnapshotInBackground();
      }
      if (vmPowerState != null) {
         assertTrue(
            this.srcVirtualMachine.setVMState(this.vmMor, vmPowerState, false),
            "Successfully configured the vm to expected state: " + vmPowerState,
            "Failed to configure the vm to expected state: " + vmPowerState);
      } else {
         assertTrue(this.virtualMachine.setVMState(this.vmMor,
            VirtualMachinePowerState.POWERED_ON, true),
            "Successfully powered on the vm", "Failed to powered on the vm");
      }
      if (hasSnapshot != null && hasSnapshot) {
         ManagedObjectReference snapShotMor =
            this.virtualMachine.createSnapshot(this.vmMor,
               TestConstants.PERF_VM_SNAPSHOT,
               TestConstants.VM_FILEINFOTYPE_SNAPSHOT, false, false);
         assertNotNull(snapShotMor, "Successfully created a vm snapshot",
            "Cannot create the vm snapshot");
         this.specialCleanup = true;
      }
      this.vmRuntimeInfo = null;
   }


   /**
    * This method generates the VMCloneSpec.
    *
    * @throws Exception
    */
   public void generateVmCloneSpec() throws Exception
   {
      this.init("generateVmCloneSpec");
      this.generateVmRelocateSpec();
      this.cloneSpec = new VirtualMachineCloneSpec();
      this.cloneSpec.setLocation(this.virtualMachineRelocateSpec);
      Boolean isSetPowerOn = true;
      if ((this.vmRuntimeInfo != null)
         && (VirtualMachinePowerState.POWERED_OFF.equals(this.vmRuntimeInfo
            .getPowerState()))) {
         isSetPowerOn = false;
      }
      this.cloneSpec.setPowerOn(isSetPowerOn);
   }


   /**
    * This method will generate the dest datastore according to datastore type.
    * If the vmotion cross datastore then the type is VMFS, else is NFS.
    *
    * @throws Exception
    */
   private void generateDestDatastore(ManagedObjectReference hostMor,
      Boolean ifCrossDatastore) throws Exception
   {
      List<ManagedObjectReference> hostDataStoreList = null;
      hostDataStoreList =
         this.storageHelper.getHostDatastores(hostMor, null, null);
      assertNotNull(hostDataStoreList,
         "Successfully get the host datastore list",
         "The host has no writeable datastore");
      String dsName = this.srcFolder.getName(this.dsMor);
      String destDSName = null;
      if (ifCrossDatastore) {
         for (ManagedObjectReference hostDataStore : hostDataStoreList) {
            destDSName = this.folder.getName(hostDataStore);
            if (!dsName.equals(destDSName)) {
               this.destDsMor = hostDataStore;
               break;
            }
         }
      } else {
         /**
          * Deal with condition the ifCrossDatastore is false
          */
         this.destDsMor = hostDataStoreList.get(0);
         for (ManagedObjectReference hostDataStore : hostDataStoreList) {
            destDSName = this.folder.getName(hostDataStore);
            if (dsName.equals(destDSName)) {
               this.destDsMor = hostDataStore;
               break;
            }
         }
      }
      log.info("Src datastore is: " + dsName + ", dest datastore is: "
         + destDSName);
   }


   /**
    * This method relocates a virtual machine after generating the relocate spec.
    * When crossVC, before migration, connectAnchor equals dest connectAnchor.
    * When migrating back, connectAnchor equals src connectAnchor and
    * srcConnectAnchor equals dest connectAnchor.
    *
    * @throws Exception
    */
   public void relocate() throws Exception
   {
      if (this.crossVc != null) {
         this.xvcProvisioningHelper =
            new XvcProvisioningHelper(this.srcConnectAnchor, this.connectAnchor);
         this.virtualMachineRelocateSpec.setService(this.xvcProvisioningHelper
            .getServiceLocator(TestConstants.SERVER_LINUX_USERNAME,
               TestConstants.SERVER_LINUX_PASSWORD));
         try {
            this.relocateVMWithSpecifyConnectAnchor(this.vmMor,
               this.virtualMachineRelocateSpec, this.srcConnectAnchor);
         } catch (Exception e) {
            this.initCurrentConnectAnchor();
            throw e;
         }
      } else {
         /**
          * Deal with condition not crossVc
          */
         assertTrue(this.virtualMachine.relocateVM(this.vmMor,
            this.virtualMachineRelocateSpec,
            VirtualMachineMovePriority.DEFAULT_PRIORITY),
            "Successfully relocated the vm with the destination "
               + "network backing", "Failed to relocate the vm with the "
               + "destination network backing");
      }
      this.migrate = true;
      this.vmMor = this.virtualMachine.getVM(this.vmName);
   }


   /**
    * When cross vc, the default connectAnchor is the destConnectAnchor before
    * calling this method, so this method will relocates a virtual machine with
    * configured connectAnchor.
    *
    * @param vmMor {@link VirtualMachine} Mor object that is to be relocated
    * @param relocateSpec is the {@link VirtualMachineRelocateSpec} object
    * @param srcConnectAnchor Reference to the Source VC connectAnchor object
    *
    * @throws Exception
    */
   private void relocateVMWithSpecifyConnectAnchor(
      ManagedObjectReference vmMor, VirtualMachineRelocateSpec relocateSpec,
      ConnectAnchor srcConnectAnchor) throws Exception
   {
      VirtualMachine virtualMachine = new VirtualMachine(srcConnectAnchor);
      ManagedObjectReference taskMor = virtualMachine.asyncRelocateVM(
          vmMor,
          relocateSpec,
          VirtualMachineMovePriority.DEFAULT_PRIORITY);
      Task mTasks = new Task(srcConnectAnchor);
      boolean taskSuccess = mTasks.monitorTask(taskMor);
      TaskInfo taskInfo = mTasks.getTaskInfo(taskMor);
      if (!taskSuccess) {
         log.warn("Relocate Task failed");
         throw new com.vmware.vc.MethodFaultFaultMsg("", taskInfo.getError()
            .getFault());
      }
  }


   /**
    * This method clones a virtual machine after generating the clone spec.
    * When getting properties for last step generateVMCloneSpec() it needs
    * this.destConnectAnchor. So current this.connectAnchor is destConnectAnchor
    * So it usees this.srcConnectAnchor and this.connectAnchor to new
    * XvcProvisioningHelper
    *
    * @throws Exception
    */
   public void cloneVM() throws Exception
   {
      if (this.crossVc != null) {
         this.xvcProvisioningHelper =
            new XvcProvisioningHelper(this.srcConnectAnchor, this.connectAnchor);
         this.virtualMachineRelocateSpec.setService(this.xvcProvisioningHelper
            .getServiceLocator(TestConstants.SERVER_LINUX_USERNAME,
               TestConstants.SERVER_LINUX_PASSWORD));
       }
      ManagedObjectReference taskMor =
         this.srcVirtualMachine.asyncCloneVM(this.vmMor, this.cloneSpec
            .getLocation().getFolder(), TestConstants.CLONE, this.cloneSpec);
      Task mTasks = new Task(this.srcConnectAnchor);
      boolean taskSuccess = mTasks.monitorTask(taskMor);
      TaskInfo taskInfo = mTasks.getTaskInfo(taskMor);
      if (taskSuccess) {
         this.clonedVmMor = (ManagedObjectReference) taskInfo.getResult();
      } else {
        throw new com.vmware.vc.MethodFaultFaultMsg(taskInfo.getError()
           .getLocalizedMessage(), taskInfo.getError().getFault());
      }
      this.restoreVMNetwork();
      if (this.vmRuntimeInfo == null) {
         this.vmRuntimeInfo = new VirtualMachineRuntimeInfo();
      }
      this.vmRuntimeInfo.setPowerState(VirtualMachinePowerState.POWERED_OFF);
      this.setVMPowerState();
      this.migrate = true;
      this.vmMor = this.clonedVmMor;
      assertNotNull(this.clonedVmMor, "The cloned vm is: " + this.clonedVmMor,
         "The cloned vm is null.");
   }


   /**
    * This method checks the network connectivity of the virtual machine
    * once it has been migrated to the destination host
    *
    * @throws Exception
    */
   public void verifyNetworkConnectivity() throws Exception
   {
      /*
       * Check the network connectivity of the virtual machine
       * after migration
       */
      String vmIp = this.virtualMachine.getIPAddress(this.vmMor);
      assertNotNull(vmIp, "The vm ip is: " + vmIp,
         "The vm didn't get an valid IP.");
      assertTrue(DVSUtil.checkNetworkConnectivity(
         this.host.getIPAddress(this.destHostMor),
         vmIp, null),
         "VM is accessible on the network on the destination host",
         "VM is not accessible on the network on the destination host");
   }


   /**
    * This method reconfigures a vm's vnics to connect to its original networks.
    *
    * @throws Exception
    */
   public void restoreVMNetwork() throws Exception
   {
      if (this.migrate == true) {
         NetworkUtil.reconfigureVMConnectToPortgroup(this.vmMor,
            this.connectAnchor, this.ethMap);
      } else {
         NetworkUtil.reconfigureVMConnectToPortgroup(this.vmMor,
            this.srcConnectAnchor, this.ethMap);
      }
   }


   /**
    * This method get the destination vds port keys
    *
    * @throws Exception
    */
   public void generateDestVdsPortKeys() throws Exception
   {
      this.init("generateDestVdsPortKeys");
      List<String> portKeys = null;
      ManagedObjectReference vdsMor = this.getMor(TestConstants.VDS);
      portKeys =
         DVSUtil.getFreePortKeys(vdsMor, this.ethMap.size(), this.connectAnchor);
      /*
       * Convert the list data structure into array
       */
      this.destKey = portKeys.toArray(new String[portKeys.size()]);
   }


   /**
    * This method get the destination vds port keys
    *
    * @throws Exception
    */
   public void generateDestPortgroupKey() throws Exception
   {
      this.init("generateDestPortgroupKey");
      ManagedObjectReference pgMor = this.getMor(TestConstants.VDSPG);
      assertNotNull(pgMor, "Successfully get the dest pgMor: " + pgMor,
         "The destination portgroup is null");
      this.destKey = new String[] {this.vdsPortgroup.getKey(pgMor)};
   }


   /**
    * This method get value from objectIdMap
    *
    * @param key is the key in the map
    */
   private String getValueFromObjectIdMap(String key)
   {
      String value = null;
      if (this.customMap != null) {
         Map<String, String> tmpMap = this.customMap.getObjectIdMap();
         assertNotNull(tmpMap.values(), "Found valid value from customMap",
            "Failed to find valid value from customMap");
         value = tmpMap.get(key);
         log.info("Successfully get value by key " + key + " " + value);
      }
      return value;
   }


   /**
    * This method will remove the destination host from dc
    *
    * @throws Exception
    */
   public void removeHostFromDc() throws Exception
   {
      this.destIp = this.host.getIPAddress(this.destHostMor);
      this.host.destroy(this.destHostMor);
      log.info("Successful removed the host from datacenter");
   }


   /**
    * This method will add the destination host to destination dc
    *
    * @throws Exception
    */
   public void addHostToDestinationDc() throws Exception
   {
      this.init("addHostToDestinationDc");
      this.createDcInVc();
      Assert.assertNotNull(this.destIp, "The host will be added is: "
         + this.destIp, "Host ip is null");
      if (this.destDcMor != null) {
         this.destHostMor =
            this.host.addStandaloneHost(this.dc.getHostFolder(this.destDcMor),
               this.host.createHostConnectSpec(this.destIp, true), null, true);
      }
      log.info("Successfully added the dest host to dc " + this.destDcName);
   }


   /**
    * This method create vss with no pnic
    * @throws Exception
    */
   public void createVssWithNoPnic() throws Exception
   {
      NetworkSystem nSystem = new NetworkSystem(connectAnchor);
      nSystem.addNetworking(this.destHostMor, TestConstants.VSWITCH_NAME,
         TestConstants.VSWITCH_NAME, false, false);
      this.specialCleanup = true;
   }


   /**
    * If the destination datacenter doesn't esxist.
    * The method will create dest datacenter in folder.
    *
    * @throws Exception
    */
   private void createDcInVc() throws Exception
   {
      this.destDcMor = this.folder.getDataCenter(this.destDcName);
      if (this.destDcMor == null) {
         this.folder.createDatacenter(this.folder.getRootFolder(),
            this.destDcName);
         this.destDcMor = this.folder.getDataCenter(this.destDcName);
      }
   }


   /**
    * If the destination datacenter doesn't esxist.
    * The method will create dest datacenter in folder.
    *
    * @throws Exception
    */
   public void deleteDc() throws Exception
   {
      this.init("deleteDc");
      this.destDcMor = folder.getDataCenter(this.destDcName);
      this.folder.destroy(this.destDcMor);
      log.info("Successfully deleted the destination datacenter "
         + this.destDcName);
   }


   /**
    * This method will call VDSTestFramework's method testCleanup
    *
    * @throws Exception
    */
   public void testCleanup() throws Exception
   {
      if (this.clonedVmMor != null) {
         if (this.virtualMachine.setVMState(
            this.clonedVmMor,
            VirtualMachinePowerState.POWERED_OFF,
            false)) {
            this.virtualMachine.destroy(this.clonedVmMor);
            this.vmMor = null;
        }
      }
      /*
       * Cleanup the added vmknic, vss and vm snapshot
       */
      if (this.specialCleanup) {
         if (this.vmMor != null && this.virtualMachine.getSnapshotInfo(this.vmMor) != null) {
            assertTrue(this.virtualMachine.removeAllSnapshots(this.vmMor),
               "Successfully removed all snapshots",
               "Failed to remove all snapshots");
         } else if (this.destHostMor != null) {
            NetworkSystem ns = new NetworkSystem(this.connectAnchor);
            ManagedObjectReference nsMor = ns.getNetworkSystem(destHostMor);
            HostNetworkInfo hostNetworkInfo = ns.getNetworkInfo(nsMor);
            List<HostVirtualNic> vnicList = hostNetworkInfo.getVnic();
            List<HostVirtualSwitch> vssList = hostNetworkInfo.getVswitch();
            for(HostVirtualNic vnic : vnicList){
                if(TestConstants.VMK1.equals(vnic.getDevice())){
                    ns.removeVirtualNic(nsMor, vnic.getDevice());
                    break;
                }
            }
            for (HostVirtualSwitch hostVirtualSwitch : vssList) {
               if (TestConstants.VSWITCH_NAME.equals(hostVirtualSwitch.getName())) {
                  ns.removeVirtualSwitch(nsMor, TestConstants.VSWITCH_NAME);
               }
            }
         }
      }
      this.srcVdsTestFramework.testCleanup();
      /**
       * If this case is cross vc, then the dest vc should call testCleanup()
       */
      if (this.crossVc != null) {
         this.destVdsTestFramework.testCleanup();
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
    * This method initializes the data pertaining to the step as mentioned in
    * the data file.
    *
    * @param stepName
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
    * This method gets the step associated with the step name. If the step is
    * not executed, return the step and change executed to true.
    *
    * @param name
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
    * This method initializes the data for input parameters
    *
    * @param objIdList
    * @throws Exception
    */
   public void initData(List<Object> objIdList) throws Exception
   {
      this.vmVnicResPoolList = new ArrayList<DvsVmVnicResourcePoolConfigSpec>();
      for (Object object : objIdList) {
         if (object instanceof DvsVmVnicResourcePoolConfigSpec) {
            this.vmVnicResPoolList.add((DvsVmVnicResourcePoolConfigSpec) object);
         } else if (object instanceof CustomMap) {
            this.customMap = (CustomMap) object;
         } else if (object instanceof HostPortGroupSpec) {
            this.hostPortGroupSpec = (HostPortGroupSpec) object;
            this.vssPgName = this.hostPortGroupSpec.getName();
         } else if (object instanceof String) {
            this.destDcName = (String) object;
         } else if (object instanceof VirtualMachineRelocateSpec) {
            this.virtualMachineRelocateSpec = (VirtualMachineRelocateSpec) object;
         } else if (object instanceof VirtualEthernetCardNetworkBackingInfo) {
            this.vssPgName =
               ((VirtualEthernetCardNetworkBackingInfo) object).getDeviceName();
         } else if (object instanceof DatastoreSummary) {
            this.ifCrossDatastore = ((DatastoreSummary) object).isAccessible();
         } else if (object instanceof HostConfigSummary) {
            if ((((HostConfigSummary) object).getName()).equals("vc-02")) {
               this.destIp =
                  (String) ((HierarchicalConfiguration) TestDataHandler
                     .getSingleton().getData()).getProperty("ip2.value");
            } else {
               this.onSameHost = true;
            }
         } else if (object instanceof BoolPolicy) {
            this.destVc = ((BoolPolicy) object).isValue();
         } else if (object instanceof VirtualMachineRuntimeInfo) {
            this.vmRuntimeInfo =((VirtualMachineRuntimeInfo) object);
         } else if(object instanceof Integer){
            nicsNumberOfEachDvs = (Integer)object;
        }
      }
   }
}

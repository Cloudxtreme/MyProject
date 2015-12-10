package com.vmware.vcqa.vim.dvs.testframework;

import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostDnsConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkConfigNetStackSpec;
import com.vmware.vc.HostPortGroupSpec;
import com.vmware.vc.HostRuntimeInfo;
import com.vmware.vc.HostRuntimeInfoNetStackInstanceRuntimeInfo;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * This class represents the subsystem for netstack configuration operations.It
 * encompasses all possible states and transitions in any scenario (positive/
 * negative/security) with respect to netstack feature
 */

public class NetStackTestFramework
{

   private List<Step>                     stepList         = null;
   private DataFactory                    xmlFactory       = null;
   private HostNetworkConfig              hostnetworkcfg   = null;
   private ManagedObjectReference         vdsMor           = null;
   private ManagedObjectReference         dcMor            = null;
   private ManagedObjectReference         hostMor          = null;
   private ManagedObjectReference         nwSystemMor      = null;
   private Folder                         folder           = null;
   private HostSystem                     hs               = null;
   private NetworkSystem                  ns               = null;
   private ConnectAnchor                  anchor           = null;
   private VMwareDVSConfigSpec            dvsConfigSpec    = null;
   private DistributedVirtualSwitchHelper vdshelper        = null;
   private String                         vNic;
   private String                         vssName          = null;
   HostVirtualNicSpec                     vNicSpec         = null;
   protected static final Logger          log              = LoggerFactory
                                                                 .getLogger(TestBase.class);
   private final int                      vnicsNum         = 3;
   private int                            vnicIndex;
   private final String                   vNics[];
   private VDSTestFramework               vdsTestFramework = null;

   /*
    * Constructor which is used to instantiate attributes' variables
    */
   public NetStackTestFramework(ConnectAnchor connectAnchor, String xmlFilePath)
         throws Exception
   {
      anchor = connectAnchor;
      folder = new Folder(connectAnchor);
      dcMor = folder.getDataCenter();
      xmlFactory = new DataFactory(xmlFilePath);
      stepList = new ArrayList<Step>();
      hs = new HostSystem(connectAnchor);
      ns = new NetworkSystem(connectAnchor);
      vdshelper = new DistributedVirtualSwitchHelper(connectAnchor);
      vdsTestFramework = new VDSTestFramework(connectAnchor, xmlFilePath);
      // Get one host which is used to do the below testing and get network
      // system MOR
      hostMor = hs.getConnectedHost(null);
      vNics = new String[vnicsNum];
      vnicIndex = 1;
      Assert.assertNotNull(hostMor, "There is no host in VC!");
      log.info("Using the host " + this.hs.getHostName(this.hostMor));
      nwSystemMor = ns.getNetworkSystem(this.hostMor);
      Assert.assertNotNull(nwSystemMor, "Network System MOR is null!");
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
         if (object instanceof HostNetworkConfig) {
            hostnetworkcfg = (HostNetworkConfig) object;
         }
         if (object instanceof String) {
            vssName = (String) object;
         }
         if (object instanceof VMwareDVSConfigSpec) {
            dvsConfigSpec = (VMwareDVSConfigSpec) object;
         }
      }
      // More data type .....
   }

   /**
    * This performs the most common cleanup operation of destroying all the
    * created vdses
    * 
    * @throws Exception
    */
   public void testCleanup() throws Exception
   {
      if (this.vdsMor != null) {
         assertTrue(this.vdshelper.destroy(vdsMor), "Successfully "
               + "destroyed the vds", "Failed to destroy the vds");
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
    * Restore the VMs to previous network Configuration.
    * 
    * @throws Exception
    */
   public void cleanupVMs()
   {
      boolean result = true;

      Assert.assertTrue(result, "Failed to reset VM's vNIC to default network");
   }

   /**
    * Update netstack configuration.
    * 
    * @throws Exception
    */
   public void updateNetStackCfg() throws Exception
   {
      boolean result;
      init("updateNetStackCfg");
      Assert.assertNotNull(hostnetworkcfg, "Host network config spec is null!");
      // Only TestConstants.CHANGEMODE_MODIFY can be used in here, the other
      // option is invalid.
      List<HostNetworkConfigNetStackSpec> tmp = hostnetworkcfg
            .getNetStackSpec();
      HostDnsConfig m = tmp.get(0).getNetStackInstance().getDnsConfig();
      if (m != null && m.isDhcp() == true) {
         // get a vmknic for dhcp setting.
         m.setVirtualNicDevice(vNic);
      }
      result = ns.updateNetworkConfig(nwSystemMor, hostnetworkcfg,
            TestConstants.CHANGEMODE_MODIFY);
      Assert.assertTrue(result, "Update network config failed!!");
   }

   /**
    * Add a vmknic on dedicated host for VDS testing
    * 
    * @throws Exception
    */
   public void addVirtualNicOnVDS() throws Exception
   {
      boolean result;
      List<String> portKeys = null;
      String dvSwitchUuid;
      DistributedVirtualSwitchPortConnection portConnection = null;
      portConnection = new DistributedVirtualSwitchPortConnection();
      // add a standalone port for vmknic
      portKeys = vdshelper.addStandaloneDVPorts(this.vdsMor, 1);
      assertNotEmpty(portKeys, "Failed to add the standalone DVPort.");
      log.info("Got portkeys: " + portKeys);
      // add a new vmknic on VDS
      dvSwitchUuid = vdshelper.getConfig(vdsMor).getUuid();
      portConnection.setSwitchUuid(dvSwitchUuid);
      portConnection.setPortKey(portKeys.get(0));
      vNicSpec = ns.createVNicSpecification();
      vNicSpec.setDistributedVirtualPort(portConnection);
      vNicSpec.getIp().setIpAddress("100.100.1." + vnicIndex);
      vNicSpec.setPortgroup(null);
      // Set netstack key
      if (hostnetworkcfg != null) {
         List<HostNetworkConfigNetStackSpec> tmp = hostnetworkcfg
               .getNetStackSpec();
         String netstackKey = tmp.get(0).getNetStackInstance().getKey();
         vNicSpec.setNetStackInstanceKey(netstackKey);
      } else {
         vNicSpec.setNetStackInstanceKey("defaultTcpipStack");
      }
      vNic = ns.addVirtualNic(nwSystemMor, "", vNicSpec);
      Assert.assertNotNull(vNic, "Add vmknic failed!");
      log.info("vmknic added successfully.");
   }

   /**
    * Add vmknics on dedicated host for VDS testing
    * 
    * @throws Exception
    */
   public void addVirtualNicsOnVDS() throws Exception
   {
      for (int j = 0; j < vnicsNum; j++) {
         addVirtualNicOnVDS();
         vnicIndex++;
         vNics[j] = this.vNic;
      }
   }

   /**
    * Remove a vmknic on dedicated host
    * 
    * @throws Exception
    */
   public void removeVirtualNic() throws Exception
   {
      Assert.assertNotNull(vNic, "There is no vnic id to remove!");
      boolean result = ns.removeVirtualNic(nwSystemMor, vNic);
      Assert.assertTrue(result, "Failed to remvoe vmknic!");
      log.info("vmknic removed successfully.");
   }

   /**
    * Remove vmknics on dedicated host
    * 
    * @throws Exception
    */
   public void removeVirtualNics() throws Exception
   {
      for (int j = 0; j < vnicsNum; j++) {
         if (vNics[j] != null) {
            boolean result = ns.removeVirtualNic(nwSystemMor, vNics[j]);
            Assert.assertTrue(result, "Failed to remvoe vmknic!");
            log.info("vmknic removed successfully.");
         }
      }
   }

   /**
    * update a vmknic to a user-defined netstack
    * 
    * @throws Exception
    */
   public void updateVirtualNicOnVDS() throws Exception
   {
      Assert.assertNotNull(vNic, "There is no vnic id to remove.!");
      Assert.assertNotNull(vNicSpec, "vmknic spec is null!");
      Assert.assertNotNull(hostnetworkcfg, "hostnetworkcfg is null!");
      List<HostNetworkConfigNetStackSpec> tmp = hostnetworkcfg
            .getNetStackSpec();
      String netstackKey = tmp.get(0).getNetStackInstance().getKey();
      vNicSpec.setNetStackInstanceKey(netstackKey);
      boolean result = ns.updateVirtualNic(nwSystemMor, vNic, vNicSpec);
      Assert.assertTrue(result, "Failed to update vmknic!");
      log.info("vmknic updated successfully.");
   }

   /**
    * update a vmknic to a invalid user-defined netstack
    * 
    * @throws Exception
    */
   public void addVNCOnInvalidNetstack() throws Exception
   {
      init("addVNCOnInvalidNetstack");
      addVirtualNicOnVDS();
   }

   /**
    * Add a vmknic on dedicated host for VSS testing
    * 
    * @throws Exception
    */
   public void addVirtualNicOnVSS() throws Exception
   {
      Assert.assertNotNull(vssName, "VSS name is null!");
      boolean result;
      String pgName = this.vssName + "_vmkpg";
      // Create a PG for vmknic used
      HostPortGroupSpec hostPgSpec = null;
      hostPgSpec = ns.createPortGroupSpec(pgName);
      hostPgSpec.setVswitchName(vssName);
      result = ns.addPortGroup(nwSystemMor, hostPgSpec);
      Assert.assertTrue(result, "Failed to add PG on VSS!");
      log.info("PG added successfully.");
      // get user-defined key
      Assert.assertNotNull(hostnetworkcfg, "hostnetworkcfg is null!");
      List<HostNetworkConfigNetStackSpec> tmp = hostnetworkcfg
            .getNetStackSpec();
      String netstackKey = tmp.get(0).getNetStackInstance().getKey();
      // Add new vmknic
      vNicSpec = ns.createVNicSpecification();
      vNicSpec.setNetStackInstanceKey(netstackKey);
      vNic = ns.addVirtualNic(nwSystemMor, pgName, vNicSpec);
      Assert.assertNotNull(vNic, "Add vmknic failed!");
      log.info("vmknic added successfully on VSS.");
   }

   /**
    * Add a vmknic on dedicated host for VSS testing
    * 
    * @throws Exception
    */
   public void addVirtualNicOnVSSWithDhcp() throws Exception
   {
      Assert.assertNotNull(vssName, "VSS name is null!");
      boolean result;
      String pgName = this.vssName + "_vmkpg";
      // Create a PG for vmknic used
      HostPortGroupSpec hostPgSpec = null;
      hostPgSpec = ns.createPortGroupSpec(pgName);
      hostPgSpec.setVswitchName(vssName);
      result = ns.addPortGroup(nwSystemMor, hostPgSpec);
      Assert.assertTrue(result, "Failed to add PG on VSS!");
      log.info("PG added successfully.");
      // get user-defined key
      Assert.assertNotNull(hostnetworkcfg, "hostnetworkcfg is null!");
      List<HostNetworkConfigNetStackSpec> tmp = hostnetworkcfg
            .getNetStackSpec();
      String netstackKey = tmp.get(0).getNetStackInstance().getKey();
      // Add new vmknic
      vNicSpec = ns.createVNicSpecification();
      vNicSpec.getIp().setDhcp(true);
      vNicSpec.setNetStackInstanceKey(netstackKey);
      vNic = ns.addVirtualNic(nwSystemMor, pgName, vNicSpec);
      Assert.assertNotNull(vNic, "Add vmknic failed!");
      log.info("vmknic added successfully on VSS.");
   }

   /**
    * This method creates new VDS and add a host into it
    * 
    * @throws Exception
    */
   public void createVdsWithHost() throws Exception
   {
      init("createVdsWithHost");
      if (dvsConfigSpec != null) {
         vdsMor = folder.createDistributedVirtualSwitch(folder
               .getNetworkFolder(dcMor), dvsConfigSpec);
         assertNotNull(vdsMor, "Failed to create a virtual distributed "
               + "switch");
      }
      DVSConfigSpec cfg = new DVSConfigSpec();
      List<ManagedObjectReference> hosts = new ArrayList<ManagedObjectReference>();
      hostMor = hs.getConnectedHost(null);
      assertNotNull(hostMor, "There is no connected host");
      hosts.add(hostMor);
      cfg = DVSUtil.addHostsToDVSConfigSpec(cfg, hosts);
      cfg.setConfigVersion(vdshelper.getConfig(vdsMor).getConfigVersion());
      cfg.setName(vdshelper.getConfig(vdsMor).getName());
      Assert.assertTrue(vdshelper.reconfigure(vdsMor, cfg),
            "Failed to add host into dvs!");
      log.info("host has been added into VDS.");
   }

   /**
    * This method creates new VSS on a host
    * 
    * @throws Exception
    */
   public void createVSS() throws Exception
   {
      init("createVSS");
      boolean result = ns.addVirtualSwitch(nwSystemMor, vssName, null);
      Assert.assertTrue(result, "failed to add a virtual switch!");
      log.info("New VSS has been created.");
   }

   /**
    * This method remove existed VSS from a host
    * 
    * @throws Exception
    */
   public void removeVSS() throws Exception
   {
      Assert.assertNotNull(vssName, "VSS name is null!");
      boolean result = ns.removeVirtualSwitch(nwSystemMor, vssName);
      Assert.assertTrue(result, "failed to remove a virtual switch!");
      log.info("VSS has been removed.");
   }

   /**
    * Check default netstack existed after booting
    * 
    * @throws Exception
    */
   public void checkDefaultNetStack() throws Exception
   {
      boolean found = false;
      HostNetworkConfig hcfg = ns.getNetworkConfig(nwSystemMor);
      List<HostNetworkConfigNetStackSpec> tmp = hcfg.getNetStackSpec();
      for (HostNetworkConfigNetStackSpec t : tmp) {
         String key = t.getNetStackInstance().getKey();
         if (key.matches("defaultTcpipStack")) {
            found = true;
            break;
         }
      }
      Assert.assertTrue(found, "Default netstack instance doesn't exist!");
      log.info("Default network stack is ready");
   }

   /**
    * Check netstck config in host runtime info
    * 
    * @throws Exception
    */
   public void checkRuntimeInfo() throws Exception
   {
      boolean found = false;
      for (int i = 0; i < 20; i++) {
         log.info("Try " + i + " time");
         Thread.sleep(10000);
         HostRuntimeInfo info = this.hs.getHostRuntime(this.hostMor);
         List<HostRuntimeInfoNetStackInstanceRuntimeInfo> netstcks = info
               .getNetworkRuntimeInfo().getNetStackInstanceRuntimeInfo();
         for (HostRuntimeInfoNetStackInstanceRuntimeInfo t : netstcks) {
            String netstackKey = t.getNetStackInstanceKey();
            // check netstack keys
            if (vNicSpec.getNetStackInstanceKey().equals(netstackKey)) {
               log.info("Found netstack key :" + netstackKey);
               // check vmknic keys
               List<String> vmks = t.getVmknicKeys();
               for (String k : vmks) {
                  if (k.equals(this.vNic)) {
                     found = true;
                     log.info("Found vmknic key :" + k);
                     break;
                  }
               }
            }
         }
         if (found == true) {
            break;
         }
      }
      // not found
      Assert.assertTrue(found, "Didn't find the new added vmknic info!!");
   }
}

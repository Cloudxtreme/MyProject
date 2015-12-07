/* ************************************************************************
*
* Copyright 2012 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa.vim.dvs.testframework;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.BoolPolicy;
import com.vmware.vc.DVPortConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.DvsFilterConfig;
import com.vmware.vc.DvsFilterPolicy;
import com.vmware.vc.DvsTrafficFilterConfigSpec;
import com.vmware.vc.IntPolicy;
import com.vmware.vc.DVPortgroupConfigInfo;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DVSFeatureCapability;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * This class represents the subsystem for traffic filter configuration
 * operations.It encompasses all possible states and transitions in any scenario
 * (positive/negative/security) with respect to the feature
 */
public class TrafficFilterTestFramework
{
   private HostSystem hs = null;
   private DistributedVirtualSwitch vds = null;
   private DistributedVirtualPortgroup vdsPortgroup = null;
   private ConnectAnchor connectAnchor = null;
   private List<Step> stepList = null;
   private DataFactory xmlFactory = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private ManagedObjectReference vdsMor = null;
   private ManagedObjectReference vdsPgMor = null;
   private DistributedVirtualSwitchHelper vdsHelper = null;
   private DistributedVirtualSwitchManager dvsManager = null;
   private static final Logger log = LoggerFactory
         .getLogger(TrafficFilterTestFramework.class);
   private String vdsVersion = DVSTestConstants.VDS_VERSION_55;
   private DvsFilterPolicy dvsFilterPolicy = null;
   private DVPortgroupConfigSpec dvPortGroupConfigSpec = null;
   private VirtualMachine vm = null;
   private Folder folder = null;
   private List<ManagedObjectReference> hostMors = null;
   private NetworkSystem ns = null;
   private Vector<ManagedObjectReference> vmMors = null;
   private ArrayList<String> dvpgPorts = null;
   private VDSTestFramework vdsTestFramework = null;


   /**
    * Constructor
    *
    * @param connectAnchor
    * @param xmlFilePath
    *
    * @throws Exception
    */
   public TrafficFilterTestFramework(ConnectAnchor connectAnchor,
         String xmlFilePath)
      throws Exception
   {
      this.connectAnchor = connectAnchor;
      this.vds = new DistributedVirtualSwitch(connectAnchor);
      this.vdsPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      this.vdsHelper = new DistributedVirtualSwitchHelper(connectAnchor);
      this.xmlFactory = new DataFactory(xmlFilePath);
      this.stepList = new ArrayList<Step>();
      this.dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      this.hs = new HostSystem(connectAnchor);
      this.vm =  new VirtualMachine(connectAnchor);
      this.folder = new Folder(connectAnchor);
      this.ns = new NetworkSystem(connectAnchor);
      this.vdsTestFramework = new VDSTestFramework(connectAnchor, xmlFilePath);
   }

   /**
    * Method to execute a list of steps provided
    *
    * @param stepList
    *
    * @throws Exception
    */
     public void execute(List<Step> stepList)
          throws Exception {
        for(Step step : stepList) {
           Class currClass = Class.forName(step.getTestFrameworkName());
           Method method = currClass.getDeclaredMethod(step.getName());
           if(currClass.getName().equals(
              VDSTestFramework.class.getName())) {
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
    * This method initializes the data pertaining to the step as mentioned in
    * the data file.
    *
    * @param stepName
    *
    * @throws Exception
    */
   public void init(String stepName)
      throws Exception
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
    * This method initializes the data for input parameters like selection sets
    * and runtime.
    *
    * @param objIdList
    *
    * @throws Exception
    */
   public void initData(List<Object> objIdList)
      throws Exception
   {
      for (Object object : objIdList) {
         if (object instanceof String) {
            this.vdsVersion = (String) object;
         }
         if (object instanceof DvsFilterPolicy) {
            this.dvsFilterPolicy = (DvsFilterPolicy) object;
         }
         if (object instanceof DVSConfigSpec) {
            this.dvsConfigSpec = (DVSConfigSpec) object;
         }
         if (object instanceof DVPortgroupConfigSpec) {
            this.dvPortGroupConfigSpec = (DVPortgroupConfigSpec) object;
         }
      }
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
    * This method retrieves MOR of vds created by vdsTestFramework.
    *
    * @throws Exception
    */
   public void getDvsMor() throws Exception
   {
	init("getDvsMor");
	Map<String, ManagedObjectReference> m = vdsTestFramework
		.getObjectIdVdsMorMap();
	Set set = m.entrySet();
	Iterator i = set.iterator();
	Map.Entry<String, ManagedObjectReference> me =
		(Map.Entry<String, ManagedObjectReference>) i.next();
	this.vdsMor = me.getValue();
	assertNotNull(vdsMor, "Failed to get vdsMor from vds testframework!");
   }

   /**
    * This method performs the basic test setup needed for the test
    *
    * @throws Exception
    */
   public void testSetup()
      throws Exception
   {
      List<Object> objIdList =
            this.xmlFactory.getData(getStep("testSetup").getData());
      initData(objIdList);
      createVdsEx();
   }

   /**
    * This performs the most common cleanup operation of destroying all the
    * created vdses
    *
    * @throws Exception
    */
   public void testCleanup()
      throws Exception
   {
      if (this.vmMors != null && this.vmMors.size() > 0) {
         for (ManagedObjectReference vmMor : vmMors) {
            if (this.vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF,
                  false)) {
               Thread.sleep(10000);
               this.vm.destroy(vmMor);
            }
         }
      }
      if (this.vdsMor != null) {
         assertTrue(this.vdsHelper.destroy(vdsMor), "Successfully "
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
    * This method creates the vds with specified version.
    *
    * @throws Exception
    */
   public void createVdsEx()
      throws Exception
   {
      DistributedVirtualSwitchProductSpec productSpec =
            DVSUtil.getProductSpec(connectAnchor, this.vdsVersion);
      DVSCreateSpec dvsCreateSpec =
            DVSUtil.createDVSCreateSpec(
                  DVSUtil.createDefaultDVSConfigSpec(null), productSpec, null);
      dvsCreateSpec.setConfigSpec(this.dvsConfigSpec);
      this.vdsMor =
            DVSUtil.createDVSFromCreateSpec(connectAnchor, dvsCreateSpec);
      assertNotNull(this.vdsMor, "Failed to create a virtual distributed "
            + "switch");

      /* Get all hosts, check free pnics and add them into the vds */
      this.hostMors = this.hs.getAllHost();
      assertTrue((hostMors != null && hostMors.size() > 0),
            "Can't find usable hosts.");
      for (ManagedObjectReference hostMor : hostMors) {
         String[] pnicIds = this.ns.getPNicIds(hostMor);
         assertTrue((pnicIds != null && pnicIds.length > 0),
               "There are no free pnics on the host.");
         assertTrue(DVSUtil.addFreePnicAndHostToDVS(this.connectAnchor,
               hostMor, Arrays.asList(this.vdsMor)),
               "Successfully added a host with free pnic to vds",
               "Failed to add a host with free pnic to vds");
      }
   }

   /**
    * This method adds a port group to the dvs.
    *
    * @throws Exception
    */
   public void addPortgroup()
      throws Exception
   {
      init("addPortgroup");
      List<ManagedObjectReference> pgMorList = null;
      DVPortgroupConfigSpec[] dvPortGroupConfigSpecs =
            new DVPortgroupConfigSpec[1];
      dvPortGroupConfigSpecs[0] = this.dvPortGroupConfigSpec;
      pgMorList = vds.addPortGroups(this.vdsMor, dvPortGroupConfigSpecs);
      this.vdsPgMor = pgMorList.get(0);
   }

   /**
    * This method create VMs.
    *
    * @throws Exception
    */
   public void createVms()
      throws Exception
   {
      if (this.hostMors != null && this.hostMors.size() > 0) {
         Vector<ManagedObjectReference> tmpVmMors = null;
         for (ManagedObjectReference hostMor : hostMors) {
            tmpVmMors = DVSUtil.createVms(this.connectAnchor, hostMor, 1, 0);
            if (this.vmMors == null) {
               this.vmMors = new Vector<ManagedObjectReference>();
            }
            this.vmMors.addAll(tmpVmMors);
            assertTrue(this.vm.setVMState(tmpVmMors.get(0),
                  VirtualMachinePowerState.POWERED_ON, false),
                  MessageConstants.VM_POWERON_FAIL);

            String vmversion = hs.getCfgOption(hostMor).getVersion();
            log.info("Vm version is:" + vmversion);
         }
      }
   }

   /**
    * This method configures vms to connect to DistributedVirtualSwitchPortConnection.
    * @param portConnection
    *
    * @throws Exception
    */
   public void reconfigVms(Vector<DistributedVirtualSwitchPortConnection> portConnection)
      throws Exception
   {
      if (this.vmMors != null && this.vmMors.size() > 0) {
         int portConnCount =
               (this.vmMors.size() < portConnection.size()) ? this.vmMors
                     .size() : portConnection.size();

         for (int i = 0; i < portConnCount; i++) {
            ManagedObjectReference vmMor = this.vmMors.get(i);
            Vector<DistributedVirtualSwitchPortConnection> tmpPortConn =
                  new Vector<DistributedVirtualSwitchPortConnection>();
            tmpPortConn.add(portConnection.get(i));
            VirtualMachineConfigSpec[] vmConfigSpec =
                  DVSUtil.getVMConfigSpecForDVSPort(vmMor, this.connectAnchor,
                        TestUtil.vectorToArray(tmpPortConn));
            assertTrue((vmConfigSpec != null && vmConfigSpec.length == 2
                  && vmConfigSpec[0] != null && vmConfigSpec[1] != null),
                  "Successfully obtained the original and the updated virtual"
                        + " machine config spec",
                  "Can not reconfigure the virtual machine to use the "
                        + "DV port");
            assertTrue(
                  this.vm.reconfigVM(vmMor, vmConfigSpec[0]),
                  "Succeeded to reconfigure the virtual machine to use portconn",
                  "Failed to  reconfigured the virtual machine to use portconnn");
         }
      }
   }

   /**
    *
    * This Method verifies Networkfiltersupported
    * For vds 5.1.0 and vds 6.0.0
    *
    * @throws Exception
    */
   public void verifyNetworkFilterSupported()
      throws Exception
   {
	init("verifyNetworkFilterSupported");
	boolean isSupported = false;
	ManagedObjectReference dvsManagerMor = dvsManager.getDvSwitchManager();
	DVSFeatureCapability featureCapability = this.dvsManager
		.queryDvsFeatureCapability(dvsManagerMor,
			DVSUtil.getProductSpec(connectAnchor, this.vdsVersion));
	boolean networkFilterSupported = featureCapability
		.isNetworkFilterSupported();
	if (this.vdsVersion.equalsIgnoreCase(DVSTestConstants.VDS_VERSION_55)) {
	    isSupported = true;
	}

	assertTrue((isSupported == networkFilterSupported),
		"Failted to erify networkFilterSupported.");
   }

   /**
    * This method will verify DvsFilterPolicy for DVS.
    * @throws Exception
    */
   public void verifyDvsFilterPolicyOnDVS()
      throws Exception
   {
      init("verifyDvsFilterPolicyOnDVS");
      boolean result = false;
      VMwareDVSConfigInfo currentCfgInfo =
            this.vdsHelper.getConfig(this.vdsMor);
      DvsFilterPolicy currDvsFilterPolicy =
            currentCfgInfo.getDefaultPortConfig().getFilterPolicy();
      Vector<String> props =
            TestUtil.getIgnorePropertyList(this.dvsFilterPolicy, false);
      result =
            TestUtil.compareObject(currDvsFilterPolicy,
                  this.dvsFilterPolicy, props);
      assertTrue(result, "verifyDvsFilterPolicyOnDVS failed.");
   }

   /**
    * This method is a wrapper to call function reconfigureFilterPolicy.
    * @throws Exception
    */
   public void reconfigureFilterPolicyWrapper()
      throws Exception
   {
      init("reconfigureDvsFilterPolicyWrapper");
      boolean result = false;
      result =
            this.vdsHelper.reconfigureFilterPolicy(this.vdsMor,
                  this.dvsFilterPolicy);
      assertTrue(result, "reconfigureDvsFilterPolicyWrapper failed.");
   }

   /**
    * This method will verify DvsFilterPolicy for dv port group.
    * @throws Exception
    */
   public void verifyDvsFilterPolicyOnDvpg()
      throws Exception
   {
      init("verifyDvsFilterPolicyOnDvpg");
      boolean result = false;

      DvsFilterPolicy tmp = new DvsFilterPolicy ();
      DVPortgroupConfigInfo currentDvpgCfgInfo =
            this.vdsPortgroup.getConfigInfo(this.vdsPgMor);
      assertNotNull(currentDvpgCfgInfo,
            "vdsPortGroup.getConfigInfo returned null.");
      DvsFilterPolicy currDvsFilterPolicy =
            currentDvpgCfgInfo.getDefaultPortConfig().getFilterPolicy();
      Vector<String> props =
            TestUtil.getIgnorePropertyList(this.dvsFilterPolicy, false);
      result =
            TestUtil.compareObject(currDvsFilterPolicy,
                  this.dvsFilterPolicy, props);

      assertTrue(result, "verifyDvsFilterPolicyOnDvpg failed.");
   }

   /**
    * This method is a wrapper to call function reconfigureFilterPolicyToDVPG.
    * @throws Exception
    */
   public void reconfigureFilterPolicyToDvpgWrapper()
      throws Exception
   {
      init("reconfigureFilterPolicyToDvpgWrapper");

      /*
       * If there are VMs created previously, we will reconfigure the VMs to
       * connect to this dvport group before we reconfigure traffic filter for
       * this dvport group.
       */
      if (this.vmMors != null && this.vmMors.size() > 0) {
         String dvSwitchUuid = this.vds.getConfig(this.vdsMor).getUuid();
         String portgroupKey = this.vdsPortgroup.getKey(this.vdsPgMor);
         Vector<DistributedVirtualSwitchPortConnection> portconns =
               new Vector<DistributedVirtualSwitchPortConnection>();

         for (ManagedObjectReference vmMor : this.vmMors) {
            DistributedVirtualSwitchPortConnection dvsPortConnection =
                  DVSUtil.buildDistributedVirtualSwitchPortConnection(
                        dvSwitchUuid, null, portgroupKey);
            portconns.add(dvsPortConnection);
         }
         reconfigVms(portconns);
      }

      boolean result = false;
      result =
            this.vdsPortgroup.reconfigureFilterPolicyToDVPG(this.vdsPgMor,
                  this.dvsFilterPolicy);
      assertTrue(result, "reconfigureFilterPolicyToDvpgWrapper failed.");
   }

   /**
    * This method is a wrapper to call function reconfigureFilterPolicyToPort.
    * @param portKey
    * @throws Exception
    */
   public void reconfigureFilterPolicyToPortWrapper(String portKey)
      throws Exception
   {
      init("reconfigureFilterPolicyToPortWrapper");
      boolean result = false;
      result =
            this.vdsHelper.reconfigureFilterPolicyToPort(this.vdsMor,
                  this.dvsFilterPolicy, portKey);
      assertTrue(result, "reconfigureFilterPolicyToPortWrapper failed.");
   }

   /**
    * This method is to fetch a standalone port and do filter policy
    * configuration on it.
    * @throws Exception
    */
   public void reconfigeFilterPolicyToStandalonePort()
      throws Exception
   {
      init("reconfigeFilterPolicyToStandalonePort");
      int portCount = 1;
      if (this.vmMors != null && this.vmMors.size() > 0) {
         portCount = this.vmMors.size();
      }
      List<String> portKeys =
            this.vds.addStandaloneDVPorts(this.vdsMor, portCount);

      /*
       * If there are VMs created previously, we will reconfigure the VMs to
       * connect to these standalone dv ports before we reconfigure traffic filter
       * for these standalone dv ports.
       */
      if (this.vmMors != null && this.vmMors.size() > 0) {
         String dvSwitchUuid = this.vds.getConfig(this.vdsMor).getUuid();
         Vector<DistributedVirtualSwitchPortConnection> portconns =
               new Vector<DistributedVirtualSwitchPortConnection>();

         for (int i = 0; i < this.vmMors.size(); i++) {
            DistributedVirtualSwitchPortConnection dvsPortConnection =
                  DVSUtil.buildDistributedVirtualSwitchPortConnection(
                        dvSwitchUuid, portKeys.get(i), null);
            portconns.add(dvsPortConnection);
         }
         reconfigVms(portconns);
      }

      for (String portKey : portKeys) {
	  reconfigureFilterPolicyToPortWrapper(portKey);
      }
   }

   public void enableTrafficFilterOverrideAllowed()
      throws Exception
   {
      this.vdsPortgroup.setTrafficFilterOverrideAllowed(this.vdsPgMor, true);
   }

   /**
    * This method is to fetch a dvpg port and do filer policy
    * configuration on it.
    * @throws Exception
    */
   public void reconfigureFilterPolicyToDvpgPort()
      throws Exception
   {
      init("reconfigureFilterPolicyToDvpgPort");
      List<DistributedVirtualPort> dvPorts =
            this.vdsPortgroup.getPorts(vdsPgMor);
      assertTrue((dvPorts != null && dvPorts.size() > 0),
            "Can't get avaiable dvport group ports.");
      int portCount = 1;
      if (this.vmMors != null && this.vmMors.size() > 0) {
         portCount =
               (this.vmMors.size() < dvPorts.size()) ? this.vmMors.size()
                     : dvPorts.size();
      }
      ArrayList<String> portKeys = new ArrayList<String>();
      for (int i = 0; i < portCount; i++) {
         DistributedVirtualPort dvPort = dvPorts.get(i);
         String portKey = dvPort.getKey();
         portKeys.add(portKey);
      }
      /* Save ports for later use, such as fetchPortDb. */
      if (!portKeys.isEmpty()) {
         dvpgPorts = portKeys;
      }

      /*
       * If there are VMs created previously, we will reconfigure the VMs to
       * connect to these dvports of the dvport group before we reconfigure
       * traffic filter for these ports of the dvport group.
       */
      if (this.vmMors != null && this.vmMors.size() > 0) {
         String dvSwitchUuid = this.vds.getConfig(this.vdsMor).getUuid();
         String portgroupKey = this.vdsPortgroup.getKey(this.vdsPgMor);
         Vector<DistributedVirtualSwitchPortConnection> portconns =
               new Vector<DistributedVirtualSwitchPortConnection>();

         for (int i = 0; i < portCount; i++) {
            DistributedVirtualSwitchPortConnection dvsPortConnection =
                  DVSUtil.buildDistributedVirtualSwitchPortConnection(
                        dvSwitchUuid, portKeys.get(i), portgroupKey);
            portconns.add(dvsPortConnection);
         }
         reconfigVms(portconns);
      }

      for (String portKey : portKeys) {
	  reconfigureFilterPolicyToPortWrapper(portKey);
      }
   }

   /**
    * This method is to deploy traffic flter policy directly.
    * @throws Exception
    */
   public void simpleDvpgPortReconfigure()
      throws Exception
   {
      init("simpleDvpgPortReconfigure");
      for (String portKey : dvpgPorts) {
	  reconfigureFilterPolicyToPortWrapper(portKey);
      }
   }

   public void setNullToFilterPolicy()
   {
       this.dvsFilterPolicy = null;
   }

   public void setEmptyToFilterPolicy()
   {
       this.dvsFilterPolicy = new DvsFilterPolicy();
   }

   /**
    * This method is to assign a key for an existing network traffic filter configuration.
    *
    * @throws Exception
    */
   public void assignKeyForNetworkTrafficFilterConfigSpec()
      throws Exception
   {
	init("assignKeyForNetworkTrafficFilterConfigSpec");
	final VMwareDVSConfigInfo currentCfgInfo = this.vdsHelper
		.getConfig(this.vdsMor);
	assertNotNull(currentCfgInfo, "Returned VMwareDVSConfigInfo is null");
	DvsFilterPolicy currDvsFilterPolicy = currentCfgInfo
		.getDefaultPortConfig().getFilterPolicy();
	assertNotNull(currDvsFilterPolicy,
		"Returned currDvsFilterPolicy is null");
	String key = currDvsFilterPolicy.getFilterConfig().get(0).getKey();
	DvsFilterConfig dvsFilterConfig = this.dvsFilterPolicy
		.getFilterConfig().get(0);
	assertTrue(dvsFilterConfig instanceof DvsTrafficFilterConfigSpec,
		"An object of DvsTrafficFilterConfigSpec is expected");
	DvsTrafficFilterConfigSpec dvsFilterConfigSpec = (DvsTrafficFilterConfigSpec) dvsFilterConfig;
	dvsFilterConfigSpec.setKey(key);
   }

   /**
    * This method is to query the size of NetworkTrafficFilterConfig list.
    *
    * @throws Exception
    */
   public int queryArraySizeForNetworkTrafficFilterList()
      throws Exception
   {
	final VMwareDVSConfigInfo currentCfgInfo = this.vdsHelper
		.getConfig(this.vdsMor);
	assertNotNull(currentCfgInfo, "Returned VMwareDVSConfigInfo is null");
	DvsFilterPolicy currDvsFilterPolicy = currentCfgInfo
		.getDefaultPortConfig().getFilterPolicy();
	assertNotNull(currDvsFilterPolicy, "Returned DvsFilterPolicy is null");
	int arraySize = 0;
	if (currDvsFilterPolicy.getFilterConfig() != null) {
	    arraySize = currDvsFilterPolicy.getFilterConfig().size();
	}

	return arraySize;
   }

   /**
    * This method is to check if NetworkTrafficFilterConfig list is null or empty.
    *
    * @throws Exception
    */
   public void verifyRemoveResultForNetworkTrafficFilter()
      throws Exception
   {
      init("verifyRemoveResultForNetworkTrafficFilter");
      assertTrue((queryArraySizeForNetworkTrafficFilterList() == 0),
               "Size of NetworkTrafficFilterConfig list is not equal to 0");
   }

   /**
    * This method is to check if NetworkTrafficFilterConfig list is null or empty.
    *
    * @throws Exception
    */
   public void verifyNullResultForNetworkTrafficFilter()
      throws Exception
   {
      init("verifyNullResultForNetworkTrafficFilter");
      assertTrue((queryArraySizeForNetworkTrafficFilterList() == 1),
               "Size of NetworkTrafficFilterConfig list is not equal to 1");
   }
}

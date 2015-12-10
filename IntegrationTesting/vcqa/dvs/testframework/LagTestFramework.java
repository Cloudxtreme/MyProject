package com.vmware.vcqa.vim.dvs.testframework;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.PrivilegeConstants.NETWORK_CONFIG;
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
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VMwareDvsLacpGroupConfig;
import com.vmware.vc.VMwareDvsLacpGroupSpec;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VMwareUplinkLacpPolicy;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vc.vpxd.ConfigSpecOperation;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * This class represents the subsystem for LAG configuration operations.It
 * encompasses all possible states and transitions in any scenario (positive/
 * negative/security) with respect to LAG feature
 */

public class LagTestFramework
{

   private List<Step>                                            stepList           = null;
   private DataFactory                                           xmlFactory         = null;
   private VMwareDVSConfigSpec                                   dvsConfigSpec      = null;
   private DVSCreateSpec                                         dvsCreateSpec      = null;
   private VMwareDvsLacpGroupSpec[]                              lagConfigSpecArray = null;
   private ManagedObjectReference                                vdsMor             = null;
   private ManagedObjectReference                                dcMor              = null;
   private ManagedObjectReference                                dvpgMor            = null;
   private ManagedObjectReference                                hostMor            = null;
   private Folder                                                folder             = null;
   private DistributedVirtualSwitchHelper                        vdshelper          = null;
   private DVPortgroupConfigSpec                                 dvpgSpec           = null;
   private HostSystem                                            hs                 = null;
   private NetworkSystem                                         ns                 = null;
   private String[]                                              uplinkPortNames    = null;
   private DistributedVirtualPortgroup                           dvpgHelper         = null;
   private VirtualMachine                                        vm                 = null;
   private final int                                             uplinkNumber       = 6;
   private String                                                loginuser          = null;
   private String                                                loginpass          = null;
   private ConnectAnchor                                         anchor             = null;
   private AuthorizationHelper                                   authHelper         = null;
   private final String                                          testUser           = GENERIC_USER;
   private final Map<ManagedObjectReference, VirtualMachineConfigSpec> vms;
   protected static final Logger                                 log                = LoggerFactory
   .getLogger(TestBase.class);

   private VDSTestFramework                                      vdsTestFramework   = null;
   private VMwareUplinkLacpPolicy                                vmwareUplinkLacpPolicy = null;

   /*
    * Constructor which is used to instantiate attributes' variables
    */
   public LagTestFramework(ConnectAnchor connectAnchor, String xmlFilePath)
   throws Exception
   {
      anchor = connectAnchor;
      folder = new Folder(connectAnchor);
      vdshelper = new DistributedVirtualSwitchHelper(connectAnchor);
      dcMor = folder.getDataCenter();
      xmlFactory = new DataFactory(xmlFilePath);
      stepList = new ArrayList<Step>();
      hs = new HostSystem(connectAnchor);
      ns = new NetworkSystem(connectAnchor);
      dvpgHelper = new DistributedVirtualPortgroup(connectAnchor);
      vm = new VirtualMachine(connectAnchor);
      vms = new HashMap<ManagedObjectReference, VirtualMachineConfigSpec>();
      // set uplink port name
      uplinkPortNames = new String[uplinkNumber];
      for (int i = 0; i < uplinkNumber; i++) {
         uplinkPortNames[i] = "uplink" + i;
      }
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
      // createVds();
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
      List<VMwareDvsLacpGroupSpec> lagConfigSpecList = new ArrayList<VMwareDvsLacpGroupSpec>();
      for (Object object : objIdList) {
         if (object instanceof VMwareDVSConfigSpec) {
            dvsConfigSpec = (VMwareDVSConfigSpec) object;
         }
         if (object instanceof VMwareDvsLacpGroupSpec) {
            lagConfigSpecList.add((VMwareDvsLacpGroupSpec) object);
         }
         if (object instanceof DVPortgroupConfigSpec) {
            dvpgSpec = (DVPortgroupConfigSpec) object;
         }
         if (object instanceof DVSCreateSpec) {
            dvsCreateSpec = (DVSCreateSpec) object;
         }
         if (object instanceof VMwareUplinkLacpPolicy) {
             this.vmwareUplinkLacpPolicy = (VMwareUplinkLacpPolicy) object;
         }
      }
      if (lagConfigSpecList.size() >= 1) {
         this.lagConfigSpecArray = lagConfigSpecList
         .toArray(new VMwareDvsLacpGroupSpec[lagConfigSpecList.size()]);
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
    * This method sets login user and passwd
    * 
    * @param stepList
    */
   public void setUserPassed(String user, String passwd)
   {
      this.loginuser = user;
      this.loginpass = passwd;
   }

   /**
    * This method login with user "genericuser"
    * 
    * @param stepList
    */
   public void loginWithGenericuser()
   {
      boolean result;
      authHelper = new AuthorizationHelper(anchor, "LagSecurity",
            this.loginuser, this.loginpass);
      try {
         authHelper
         .setPermissions(this.vdsMor, NETWORK_CONFIG, testUser, false);
         result = authHelper.performSecurityTestsSetup(testUser);
         Assert.assertTrue(result, "Failed to login with genericuser");
      } catch (Exception e) {
         e.printStackTrace();
      }
   }

   /**
    * This method login with user "root"
    * 
    * @param stepList
    */
   public void loginWithRoot()
   {
      boolean result;
      Assert.assertNotNull(authHelper, "authHelper is null");
      try {
         result = authHelper.performSecurityTestsCleanup();
         Assert.assertTrue(result, "Failed to login with root");
      } catch (Exception e) {
         // TODO Auto-generated catch block
         e.printStackTrace();
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
    * This method creates new VDS
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
      Map.Entry<String, ManagedObjectReference> me = (Map.Entry<String, ManagedObjectReference>) i
      .next();
      this.vdsMor = me.getValue();
      Assert.assertNotNull(vdsMor,
      "Failed to get vdsMor from vds testframework!");
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
    * This method set lag version as multipleLag on DVS
    * 
    * @throws Exception
    */
   public void setMultipleLagOnDVS() throws Exception
   {
      Assert.assertNotNull(vdsMor, "vdsMor is null!!");
      VMwareDVSConfigSpec cfg = new VMwareDVSConfigSpec();
      cfg.setConfigVersion(vdshelper.getConfig(vdsMor).getConfigVersion());
      cfg.setName(vdshelper.getConfig(vdsMor).getName());
      cfg.setLacpApiVersion("multipleLag");
      Assert.assertTrue(vdshelper.reconfigure(vdsMor, cfg),
      "Failed to add host into dvs!");
   }

   /**
    * This method set lag version as singleLag on DVS
    * 
    * @throws Exception
    */
   public void setSingleLagOnDVS() throws Exception
   {
      Assert.assertNotNull(vdsMor, "vdsMor is null!!");
      VMwareDVSConfigSpec cfg = new VMwareDVSConfigSpec();
      cfg.setConfigVersion(vdshelper.getConfig(vdsMor).getConfigVersion());
      cfg.setName(vdshelper.getConfig(vdsMor).getName());
      cfg.setLacpApiVersion("singleLag");
      Assert.assertTrue(vdshelper.reconfigure(vdsMor, cfg),
      "Failed to add host into dvs!");
   }

   /**
    * This method will upgrade VDS to 6.0.0 version
    * 
    * @throws Exception
    */
   public void upgradeVdsTo6() throws Exception
   {
      assertNotNull(vdsMor, "Failed to find a VDS MOR!");
      this.vdshelper.performProductSpecOperation(vdsMor,
            DVSTestConstants.OPERATION_UPGRADE, DVSUtil.getProductSpec(
                  this.anchor, DVSTestConstants.VDS_VERSION_60));
   }

   /**
    * This method creates the DVPG on the VDS
    * 
    * @throws Exception
    */
   public void addDvpg() throws Exception
   {
      init("addDvpg");
      assertNotNull(vdsMor, "Failed to find a VDS MOR");
      if (dvpgSpec != null) {
         List<ManagedObjectReference> l = vdshelper.addPortGroups(vdsMor,
               new DVPortgroupConfigSpec[] { dvpgSpec });
         dvpgMor = l.get(0);
         assertNotNull(dvpgMor, "Failed to get DVPG MOR");
      }
   }

   /**
    * This method add two uplinks into LAG group.
    * 
    * @throws Exception
    */
   public void addUplinksToLag() throws Exception
   {
      final Map<ManagedObjectReference, String> pNics;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
      Vector<DistributedVirtualSwitchHostMemberConfigSpec> backingList = new Vector<DistributedVirtualSwitchHostMemberConfigSpec>();
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
      log.info("host has been added into VDS");
      // get free pnic and add into dvs
      cfg = new DVSConfigSpec();
      hostMember.setOperation(TestConstants.CONFIG_SPEC_EDIT);
      hostMember.setHost(hostMor);
      final String[] freePnics = ns.getPNicIds(hostMor, false);
      Assert.assertTrue(freePnics.length >= 2, "No free nics found in host.");
      pNics = new HashMap<ManagedObjectReference, String>();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
      pnicSpec.setPnicDevice(freePnics[0]);
      List<VMwareDvsLacpGroupConfig> m = vdshelper.getConfig(this.vdsMor)
      .getLacpGroupConfig();
      List<String> lagkey = m.get(0).getUplinkPortKey();
      pnicSpec.setUplinkPortKey(lagkey.get(0));
      pnicBacking.getPnicSpec().clear();
      pnicBacking
      .getPnicSpec()
      .addAll(
            com.vmware.vcqa.util.TestUtil
            .arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
      hostMember.setBacking(pnicBacking);
      backingList.add(hostMember);
      cfg.getHost().clear();
      cfg.getHost().addAll(
            com.vmware.vcqa.util.TestUtil.arrayToVector(TestUtil
                  .vectorToArray(backingList)));
      cfg.setConfigVersion(vdshelper.getConfig(vdsMor).getConfigVersion());
      cfg.setName(vdshelper.getConfig(vdsMor).getName());
      Assert.assertTrue(vdshelper.reconfigure(vdsMor, cfg),
      "Failed to add uplinks into lag!");
   }

   /**
    * This method add one pNIC into LAG group, then move to another lag.
    * 
    * @throws Exception
    */
   public void moveUplinkBetweenLags() throws Exception
   {
      Assert.assertNotNull(hostMor, "hostMor is null");
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
      Vector<DistributedVirtualSwitchHostMemberConfigSpec> backingList = new Vector<DistributedVirtualSwitchHostMemberConfigSpec>();
      final Map<ManagedObjectReference, String> pNics;
      // get free pnic and add into dvs
      DVSConfigSpec cfg = new DVSConfigSpec();
      hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
      hostMember.setHost(hostMor);
      final String[] freePnics = ns.getPNicIds(hostMor, false);
      Assert.assertTrue(freePnics.length >= 1, "No free nics found in host.");
      pNics = new HashMap<ManagedObjectReference, String>();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking1 = new DistributedVirtualSwitchHostMemberPnicBacking();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking2 = new DistributedVirtualSwitchHostMemberPnicBacking();
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec1 = new DistributedVirtualSwitchHostMemberPnicSpec();
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec2 = new DistributedVirtualSwitchHostMemberPnicSpec();
      pnicSpec1.setPnicDevice(freePnics[0]);
      pnicSpec2.setPnicDevice(freePnics[0]);
      List<VMwareDvsLacpGroupConfig> m = vdshelper.getConfig(this.vdsMor)
      .getLacpGroupConfig();
      // Assume there are tow lags
      List<String> lagkey1 = m.get(0).getUplinkPortKey();
      List<String> lagkey2 = m.get(1).getUplinkPortKey();
      // Add the pnic into the first lag group
      pnicSpec1.setUplinkPortKey(lagkey1.get(0));
      pnicSpec2.setUplinkPortKey(lagkey2.get(0));
      pnicBacking1.getPnicSpec().clear();
      pnicBacking1
      .getPnicSpec()
      .addAll(
            com.vmware.vcqa.util.TestUtil
            .arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec1 }));
      pnicBacking2.getPnicSpec().clear();
      pnicBacking2
      .getPnicSpec()
      .addAll(
            com.vmware.vcqa.util.TestUtil
            .arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec2 }));
      hostMember.setBacking(pnicBacking1);
      hostMember.setBacking(pnicBacking2);
      hostMember.setOperation("edit");
      backingList.add(hostMember);
      cfg.getHost().clear();
      cfg.getHost().addAll(
            com.vmware.vcqa.util.TestUtil.arrayToVector(TestUtil
                  .vectorToArray(backingList)));
      cfg.setConfigVersion(vdshelper.getConfig(vdsMor).getConfigVersion());
      cfg.setName(vdshelper.getConfig(vdsMor).getName());
      Assert.assertTrue(vdshelper.reconfigure(vdsMor, cfg),
      "Failed to add uplinks into lag!");
   }

   /**
    * This method will remove one port from LAG group, expect exception thrown.
    * 
    * @throws Exception
    */
   public void removePortFromLag() throws Exception
   {

      List<VMwareDvsLacpGroupConfig> m = vdshelper.getConfig(this.vdsMor)
      .getLacpGroupConfig();
      List<String> lagkey = m.get(0).getUplinkPortKey();
      DVPortConfigSpec[] portConfigSpecs = new DVPortConfigSpec[1];
      portConfigSpecs[0] = new DVPortConfigSpec();
      portConfigSpecs[0].setConfigVersion(vdshelper.getConfig(vdsMor)
            .getConfigVersion());
      portConfigSpecs[0].setOperation("remove");
      portConfigSpecs[0].setKey(lagkey.get(0));
      vdshelper.reconfigurePort(vdsMor, portConfigSpecs);
   }

   /**
    * ; This method will remove uplinks from LAG group.
    * 
    * @throws Exception
    */
   public void removeHostFromLag() throws Exception
   {
      boolean result;
      assertTrue(this.vdsMor != null, "Found one dvsMor ..",
      "Failed to find a dvsMor!2 ");
      assertTrue(this.hostMor != null, "Found one hostMor ..",
      "Failed to find a hostMor!2 ");
      result = DVSUtil.removeHostFromDVS(anchor, hostMor, this.vdsMor);
      Assert.assertTrue(result, "Failed to remove a host from VDS!");
   }

   /**
    * This method add two uplinks into specified uplink portgroup.
    * 
    * @throws Exception
    */
   public void addUplinks() throws Exception
   {
      final Map<ManagedObjectReference, String> pNics;
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      uplinkPolicyInst.getUplinkPortName().clear();
      uplinkPolicyInst.getUplinkPortName().addAll(
            com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
      hostMor = hs.getConnectedHost(null);
      // get free pnic and add into dvs
      assertNotNull(hostMor, "There is no connected host");
      final String[] freePnics = ns.getPNicIds(hostMor, false);
      Assert.assertTrue(freePnics.length >= 2, "No free nics found in host.");
      pNics = new HashMap<ManagedObjectReference, String>();
      pNics.put(hostMor, freePnics[0]);
      pNics.put(hostMor, freePnics[1]);
      DVSConfigSpec cfg = DVSUtil
      .addHostsToDVSConfigSpecWithPnic(null, pNics, null);
      cfg.setConfigVersion(vdshelper.getConfig(vdsMor).getConfigVersion());
      cfg.setName(vdshelper.getConfig(vdsMor).getName());
      cfg.setUplinkPortPolicy(uplinkPolicyInst);
      Assert.assertTrue(vdshelper.reconfigure(vdsMor, cfg),
      "Failed to add uplinks into dvs!");
   }

   /**
    * This method set DVPG's ActiveUplink and StandbyUplink
    * 
    * @throws Exception
    */
   public void setDvpgUplink() throws Exception
   {
      VMwareDVSPortSetting portSetting = new VMwareDVSPortSetting();
      VMwareUplinkPortOrderPolicy portOrderPolicy = new VMwareUplinkPortOrderPolicy();
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = new VmwareUplinkPortTeamingPolicy();
      DVPortgroupConfigSpec dvpgcfg = new DVPortgroupConfigSpec();
      portOrderPolicy.getActiveUplinkPort().clear();
      portOrderPolicy.getActiveUplinkPort().addAll(
            com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] {
                  uplinkPortNames[0], uplinkPortNames[2] }));
      portOrderPolicy.getStandbyUplinkPort().clear();
      portOrderPolicy.getStandbyUplinkPort().addAll(
            com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] {
                  uplinkPortNames[1], uplinkPortNames[3] }));
      uplinkTeamingPolicy.setUplinkPortOrder(portOrderPolicy);
      // only support ip hash method
      uplinkTeamingPolicy.setPolicy(DVSUtil.getStringPolicy(false,
      "loadbalance_ip"));
      portSetting.setUplinkTeamingPolicy(uplinkTeamingPolicy);
      dvpgcfg.setDefaultPortConfig(portSetting);
      dvpgcfg.setConfigVersion(dvpgHelper.getConfigInfo(dvpgMor)
            .getConfigVersion());
      Assert.assertTrue(dvpgHelper.reconfigure(dvpgMor, dvpgcfg),
      "Failed to change active&standby uplinks for DVPG");

   }

   /**
    * This method set DVPG's ActiveUplink and StandbyUplink as LAG group
    * 
    * @throws Exception
    */
   public void setDvpgLag() throws Exception
   {
      List<VMwareDvsLacpGroupConfig> m = vdshelper.getConfig(this.vdsMor)
      .getLacpGroupConfig();
      String lagname = m.get(0).getName();
      VMwareDVSPortSetting portSetting = new VMwareDVSPortSetting();
      VMwareUplinkPortOrderPolicy portOrderPolicy = new VMwareUplinkPortOrderPolicy();
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = new VmwareUplinkPortTeamingPolicy();
      DVPortgroupConfigSpec dvpgcfg = new DVPortgroupConfigSpec();
      portOrderPolicy.getActiveUplinkPort().clear();
      portOrderPolicy.getActiveUplinkPort().addAll(
            com.vmware.vcqa.util.TestUtil
            .arrayToVector(new String[] { lagname }));
      uplinkTeamingPolicy.setUplinkPortOrder(portOrderPolicy);
      // only support ip hash method
      uplinkTeamingPolicy.setPolicy(DVSUtil.getStringPolicy(false,
      "loadbalance_ip"));
      portSetting.setUplinkTeamingPolicy(uplinkTeamingPolicy);
      dvpgcfg.setDefaultPortConfig(portSetting);
      dvpgcfg.setConfigVersion(dvpgHelper.getConfigInfo(dvpgMor)
            .getConfigVersion());
      Assert.assertTrue(dvpgHelper.reconfigure(dvpgMor, dvpgcfg),
      "Failed to change active&standby uplinks for DVPG");

   }

   /**
    * This method will remove lag group from DVPG
    * 
    * @throws Exception
    */
   public void unsetDvpgLag() throws Exception
   {

      VMwareDVSPortSetting portSetting = new VMwareDVSPortSetting();
      VMwareUplinkPortOrderPolicy portOrderPolicy = new VMwareUplinkPortOrderPolicy();
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = new VmwareUplinkPortTeamingPolicy();
      DVPortgroupConfigSpec dvpgcfg = new DVPortgroupConfigSpec();
      portOrderPolicy.getActiveUplinkPort().clear();
      uplinkTeamingPolicy.setUplinkPortOrder(portOrderPolicy);
      portSetting.setUplinkTeamingPolicy(uplinkTeamingPolicy);
      dvpgcfg.setDefaultPortConfig(portSetting);
      dvpgcfg.setConfigVersion(dvpgHelper.getConfigInfo(dvpgMor)
            .getConfigVersion());
      Assert.assertTrue(dvpgHelper.reconfigure(dvpgMor, dvpgcfg),
      "Failed to remove lag from active uplinks for DVPG");

   }

   public void addActiveActiveLag() throws Exception
   {
        addMoreLagToDVPG("active&active");
   }

   public void addActiveStandbyLag() throws Exception
   {
        addMoreLagToDVPG("active&standby");
   }

   public void addStandbyStandbyLag() throws Exception
   {
        addMoreLagToDVPG("standby&standby");
   }

   public void addLagAndUplink() throws Exception
   {
        addMoreLagToDVPG("lag&uplink");
   }

   /**
    * This method adds host to the vds.
    *
    * @throws Exception
    */
   public void addHostsToVds() throws Exception
   {
       /* Get all hosts, check free pnics and add them into the vds */
       List<ManagedObjectReference> hostMors = this.hs.getAllHost();
       assertTrue((hostMors != null && hostMors.size() > 0),
             "Can't find usable hosts.");
       for (ManagedObjectReference hostMor : hostMors) {
          String[] pnicIds = this.ns.getPNicIds(hostMor);
          assertTrue((pnicIds != null && pnicIds.length > 0),
                "There are no free pnics on the host.");
          assertTrue(DVSUtil.addFreePnicAndHostToDVS(this.anchor,
                hostMor, Arrays.asList(this.vdsMor)),
                "Successfully added a host with free pnic to vds",
                "Failed to add a host with free pnic to vds");
       }
   }

  /**
   * This method will try to add more lag group in a DVPG as ActiveUplink or StandbyUplink.
   *
   * @throws Exception
   */
   public void addMoreLagToDVPG(String flag) throws Exception
   {
        Assert.assertNotNull(flag, "flag can't be null");
        List<VMwareDvsLacpGroupConfig> m = vdshelper.getConfig(this.vdsMor)
                .getLacpGroupConfig();
        Assert.assertNotNull(m.get(0), "No lacp group config was found.");
        Assert.assertNotNull(m.get(1),
                "No a second lacp group config was found.");
        String lagname0 = m.get(0).getName();
        String lagname1 = m.get(1).getName();
        VMwareDVSPortSetting portSetting = new VMwareDVSPortSetting();
        VMwareUplinkPortOrderPolicy portOrderPolicy = new VMwareUplinkPortOrderPolicy();
        VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = new VmwareUplinkPortTeamingPolicy();
        DVPortgroupConfigSpec dvpgcfg = new DVPortgroupConfigSpec();
        if (flag.equals("active&active")) {
            portOrderPolicy.getActiveUplinkPort().clear();
            portOrderPolicy.getActiveUplinkPort().addAll(
                    com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] {
                            lagname0, lagname1 }));
        } else if (flag.equals("active&standby")) {
            portOrderPolicy.getActiveUplinkPort().add(lagname0);
            portOrderPolicy.getStandbyUplinkPort().add(lagname1);
        } else if (flag.equals("standby&standby")) {
            portOrderPolicy.getStandbyUplinkPort().clear();
            portOrderPolicy.getStandbyUplinkPort().addAll(
                    com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] {
                            lagname0, lagname1 }));
        } else if (flag.equals("lag&uplink")) {
            portOrderPolicy.getActiveUplinkPort().add(lagname0);
            portOrderPolicy.getStandbyUplinkPort().add("uplink1");
        } else {
            Assert.assertTrue(false, "Invalid value of flag: " + flag);
        }
        uplinkTeamingPolicy.setUplinkPortOrder(portOrderPolicy);
        // only support ip hash method
        uplinkTeamingPolicy.setPolicy(DVSUtil.getStringPolicy(false,
                "loadbalance_ip"));
        portSetting.setUplinkTeamingPolicy(uplinkTeamingPolicy);
        dvpgcfg.setDefaultPortConfig(portSetting);
        dvpgcfg.setConfigVersion(dvpgHelper.getConfigInfo(dvpgMor)
                .getConfigVersion());
        Assert.assertTrue(dvpgHelper.reconfigure(dvpgMor, dvpgcfg),
                "Failed to change active&standby uplinks for DVPG");
    }

   /**
    * This method enable/disable lag configuration
    * 
    * @throws Exception
    */
   public void updateLagOnDvs() throws Exception
   {
      boolean result = false;
      init("updateLagOnDvs");
      assertTrue(this.vdsMor != null, "Found one dvsMor ..",
      "Failed to find a dvsMor! ");
      // if the operation is "edit" or "delete", find the correct key according
      // lag name.
      List<VMwareDvsLacpGroupConfig> m = vdshelper.getConfig(this.vdsMor)
      .getLacpGroupConfig();
      VMwareDvsLacpGroupConfig[] lagcfgArray = m
      .toArray(new VMwareDvsLacpGroupConfig[m.size()]);
      for (VMwareDvsLacpGroupSpec i : lagConfigSpecArray) {
         if (i.getOperation().equals(ConfigSpecOperation.EDIT.value())
               || i.getOperation().equals(ConfigSpecOperation.REMOVE.value())) {
            for (VMwareDvsLacpGroupConfig j : lagcfgArray) {
               if (j.getName().equals(i.getLacpGroupConfig().getName())) {
                  i.getLacpGroupConfig().setKey(j.getKey());
                  // i.getLacpGroupConfig().setMode(j.getMode());
                  break;
               }
            }
         }
      }
      result = vdshelper.updateLacpConfig(vdsMor, lagConfigSpecArray);
      assertTrue(result, "Update lag config sucessful..",
      "Failed to udpate Lag config!");
   }

   /**
    * Get one VM from a host member of DVS and connect its vNIC to the DVPorts
    * of VDS, if there is no VM existed in host, create a new one with 2 vNICs.
    * 
    * @throws Exception
    */
   public void setupVMs() throws Exception
   {
      DistributedVirtualSwitchHostMember[] hostMember;
      ManagedObjectReference dvsHostMor;
      Vector<ManagedObjectReference> hostVms;
      ManagedObjectReference aVmMor;
      hostMember = com.vmware.vcqa.util.TestUtil.vectorToArray(this.vdshelper
            .getConfig(vdsMor).getHost(),
            com.vmware.vc.DistributedVirtualSwitchHostMember.class);
      assertNotEmpty(hostMember, "No hosts connected to DVS");
      dvsHostMor = hostMember[0].getConfig().getHost();
      hostVms = hs.getAllVirtualMachine(dvsHostMor);
      // if there is no VM on host, create a new one.
      if (hostVms == null) {
         hostVms = DVSUtil.createVms(anchor, dvsHostMor, 1, 0);
      }
      Assert.assertNotEmpty(hostVms, MessageConstants.VM_GET_FAIL);
      aVmMor = hostVms.get(0);
      log.info("Got '{}' VM's in host {}", hostVms.size(), hostMor);
      assertTrue(vm.powerOnVMs(hostVms, false),
            MessageConstants.VM_POWERON_FAIL);
      final String pgKey = dvpgHelper.getKey(dvpgMor);
      final DistributedVirtualSwitchPortConnection[] conns;
      final VirtualMachineConfigSpec[] vmCfgs;
      DistributedVirtualSwitchPortCriteria criteria;
      criteria = this.vdshelper.getPortCriteria(null, null, null,
            new String[] { pgKey }, null, true);
      final List<String> ports = this.vdshelper.fetchPortKeys(this.vdsMor,
            criteria);
      log.info("Ports: {}", ports);
      conns = new DistributedVirtualSwitchPortConnection[1];
      conns[0] = new DistributedVirtualSwitchPortConnection();
      conns[0].setPortKey(ports.get(0));
      conns[0].setPortgroupKey(pgKey);
      conns[0].setSwitchUuid(this.vdshelper.getConfig(vdsMor).getUuid());
      log.debug("Created {} DVPort Connections.", conns.length);
      vmCfgs = DVSUtil.getVMConfigSpecForDVSPort(aVmMor, anchor, conns);
      assertNotEmpty(vmCfgs, "Failed to get Recfg spec for VM " + aVmMor);
      log.debug("Reconfiguring the VM to connect to DVS...");
      // PR 958831
      //vmCfgs[0].getDeviceChange().get(0).getDevice().setConnectable(null);
      assertTrue(vm.reconfigVM(aVmMor, vmCfgs[0]), "Failed to reconfig VM");
      log.debug("Reconfigured VM '{}' to use DVS.", aVmMor);
      vms.put(aVmMor, vmCfgs[1]);
   }

   /**
    * Restore the VMs to previous network Configuration.
    * 
    * @throws Exception
    */
   public void cleanupVMs()
   {
      boolean result = true;
      for (int i = 0; i < vms.size(); i++) {
         final Iterator<ManagedObjectReference> specs = vms.keySet().iterator();
         while (specs.hasNext()) {
            try {
               final ManagedObjectReference aVmMor = specs.next();
               log.info("Restoring '{}' to original Cfg.", aVmMor);
               // PR 958831
               VirtualMachineConfigSpec t = vms.get(aVmMor);
               t.getDeviceChange().get(0).getDevice().setConnectable(null);
               result &= vm.reconfigVM(aVmMor, t);
            } catch (final Exception e) {
               log.error("Failed to restore VM to original Cfg", e);
               result = false;
            }
         }
      }
      Assert.assertTrue(result, "Failed to reset VM's vNIC to default network");
   }

   /**
    * Set override uplink port group ipfix attribute
    * 
    * @throws Exception
    */
   public void setUplinkIpfixOverrideAllowed()
   {
      ManagedObjectReference pgtmp;
      VMwareDVSPortgroupPolicy policy;
      DVPortgroupConfigSpec dvpgSpecTmp;
      Assert.assertNotNull(vdsMor, "vdsMor is null");
      try {
         List<ManagedObjectReference> pglist = this.vdshelper
         .getUplinkPortgroups(vdsMor);
         Iterator<ManagedObjectReference> i = pglist.iterator();
         while (i.hasNext()) {
            pgtmp = i.next();
            policy = new VMwareDVSPortgroupPolicy();
            policy.setIpfixOverrideAllowed(true);
            dvpgSpecTmp = new DVPortgroupConfigSpec();
            dvpgSpecTmp.setPolicy(policy);
            dvpgSpecTmp.setConfigVersion(dvpgHelper.getConfigInfo(dvpgMor)
                  .getConfigVersion());
            Assert.assertTrue(dvpgHelper.reconfigure(pgtmp, dvpgSpecTmp),
            "Enable uplink ipfix overfide failed!");
         }
      } catch (final Exception e) {
         log.error("Failed to get all the uplink port group");
      }
      log.info("Uplink port group ipfix override allowed");
   }

   /**
    * Set override uplink port group vlan range attribute
    * 
    * @throws Exception
    */
   public void setUplinkVlanOverrideAllowed()
   {
      ManagedObjectReference pgtmp;
      VMwareDVSPortgroupPolicy policy;
      DVPortgroupConfigSpec dvpgSpecTmp;
      Assert.assertNotNull(vdsMor, "vdsMor is null");
      try {
         List<ManagedObjectReference> pglist = this.vdshelper
         .getUplinkPortgroups(vdsMor);
         Iterator<ManagedObjectReference> i = pglist.iterator();
         while (i.hasNext()) {
            pgtmp = i.next();
            policy = new VMwareDVSPortgroupPolicy();
            policy.setVlanOverrideAllowed(true);
            dvpgSpecTmp = new DVPortgroupConfigSpec();
            dvpgSpecTmp.setPolicy(policy);
            dvpgSpecTmp.setConfigVersion(dvpgHelper.getConfigInfo(dvpgMor)
                  .getConfigVersion());
            Assert.assertTrue(dvpgHelper.reconfigure(pgtmp, dvpgSpecTmp),
            "Enable uplink vlan overfide failed!");
         }
      } catch (final Exception e) {
         log.error("Failed to get all the uplink port group");
      }
      log.info("Uplink port group vlan override allowed");
   }

   /**
    * This method change the existed lag group name
    * 
    * @throws Exception
    */
   public void changeLagGroupName() throws Exception
   {
      boolean result = false;
      int i = 0;
      assertTrue(this.vdsMor != null, "Found one dvsMor ..",
      "Failed to find a dvsMor! ");
      List<VMwareDvsLacpGroupConfig> m = vdshelper.getConfig(this.vdsMor)
      .getLacpGroupConfig();
      VMwareDvsLacpGroupSpec[] lagSpecTmp = new VMwareDvsLacpGroupSpec[m.size()];
      VMwareDvsLacpGroupConfig[] lagcfgArray = m
      .toArray(new VMwareDvsLacpGroupConfig[m.size()]);
      for (VMwareDvsLacpGroupConfig j : lagcfgArray) {
         lagSpecTmp[i] = new VMwareDvsLacpGroupSpec();
         lagSpecTmp[i].setOperation(ConfigSpecOperation.EDIT.value());
         lagSpecTmp[i].setLacpGroupConfig(j);
         j.setName("changedName");
         i++;
      }
      result = vdshelper.updateLacpConfig(vdsMor, lagSpecTmp);
      assertTrue(result, "Update lag config sucessful..",
      "Failed to udpate Lag config!");
   }

   /**
    * This method add maximum (64) lags on one vds.
    * 
    * @throws Exception
    */
   public void AddMaxLagOnVds() throws Exception
   {
      boolean result = false;
      final int maxLagNum = 65;
      init("AddMaxLagOnVds");
      assertTrue(this.vdsMor != null, "Found one dvsMor ..",
      "Failed to find a dvsMor! ");
      // if the operation is "edit" or "delete", find the correct key according
      // lag name.
      Assert.assertNotNull(lagConfigSpecArray[0], "lag config spec is null!");

      for (int i = 0; i < maxLagNum; i++) {
         lagConfigSpecArray[0].getLacpGroupConfig().setName("Neg001_" + i);
         result = vdshelper.updateLacpConfig(vdsMor, lagConfigSpecArray);
      }
      Assert.assertTrue(false, "",
      "Hit maximum lag number, but didn't get exception!");
   }

   /**
    * This method will configure single uplink lacp policy to vds.
    *
    * @throws Exception
    */
   public void reconfigureUplinkLacpPolicyToVds() throws Exception
   {
       init("reconfigureUplinkLacpPolicyToVds");
       Assert.assertNotNull(this.vdsMor, "vdsMor is null");
       Assert.assertNotNull(this.vdsMor.getType(), "vdsMor.getType() is null");
       Assert.assertNotNull(this.vmwareUplinkLacpPolicy, "vmwareUplinkLacpPolicy is null");
       log.info("start reconfiguring uplink lacp policy for VDS ");
       VMwareDVSPortSetting vmwareDVSPortSetting = new VMwareDVSPortSetting();
       vmwareDVSPortSetting.setLacpPolicy(this.vmwareUplinkLacpPolicy);
       VMwareDVSConfigSpec vmwareDVSConfigSpec = new VMwareDVSConfigSpec();
       VMwareDVSConfigInfo vmwareDVSConfigInfo = this.vdshelper.getConfig(this.vdsMor);
       Assert.assertNotNull(vmwareDVSConfigInfo, "returned vmwareDVSConfigInfo is null");
       vmwareDVSConfigSpec.setConfigVersion(vmwareDVSConfigInfo.getConfigVersion());
       vmwareDVSConfigSpec.setDefaultPortConfig(vmwareDVSPortSetting);
       this.vdshelper.reconfigure(this.vdsMor, vmwareDVSConfigSpec);
   }
}

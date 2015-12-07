package dvs.healthcheck;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.Vector;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DVSHealthCheckConfig;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NumericRange;
import com.vmware.vc.TaskInfo;
import com.vmware.vc.UserSession;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchTrunkVlanSpec;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.Task;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

public abstract class HealthCheckTestBase extends TestBase {
   protected static String VLANMTUENABLED = "vlanMtuEnabled";
   protected static String VLANMTUINTERVAL = "vlanMtuInterval";
   protected static String TEAMINGENABLED = "teamingEnabled";
   protected static String TEAMINGINTERVAL = "teamingInterval";
   protected static String VLANID = "vlanID";
   protected static boolean vlanMtuEnabled = false;
   protected static boolean hasVlanMtuEnabled = false;
   protected static int vlanMtuInterval = 1;
   protected static boolean teamingEnabled = false;
   protected static boolean hasTeamingEnabled = false;
   protected static int teamingInterval = 1;
   protected static int vlanID = -1;
   protected DistributedVirtualSwitch DVS = null;
   protected ManagedObjectReference dvsMor = null;
   protected DistributedVirtualSwitchProductSpec spec = null;
   protected VMwareDVSConfigSpec dvsCfg;// Used to create DVS.
   protected DVSConfigInfo dvsCfgInfo;// Holds the DVS info.
   protected ManagedObjectReference netFolderMor;
   protected Folder folder;
   protected HostSystem hs;
   protected NetworkSystem ns;
   protected DistributedVirtualSwitchHelper vmwareDvsHelper;
   protected DistributedVirtualPortgroup dvpg;
   protected String dvsName;
   protected boolean enabled = false;
   protected int interval = 1;

   public String getTestName() {
      return getTestId();
   }

   /**
    * Get the properties from data.
    */
   protected final void getProperties() {
      if (data.containsKey(VLANMTUENABLED)) {
         vlanMtuEnabled = data.getBoolean(VLANMTUENABLED);
         hasVlanMtuEnabled = true;
      }
      if (data.containsKey(VLANMTUINTERVAL)) {
         vlanMtuInterval = data.getInt(VLANMTUINTERVAL);
      }
      if (data.containsKey(TEAMINGENABLED)) {
         teamingEnabled = data.getBoolean(TEAMINGENABLED);
         hasTeamingEnabled = true;
      }
      if (data.containsKey(TEAMINGINTERVAL)) {
         teamingInterval = data.getInt(TEAMINGINTERVAL);
      }
      if (data.containsKey(VLANID)) {
         vlanID = data.getInt(VLANID);
      }
   }

   /**
    * Initialize the members.
    *
    * @throws Exception
    */
   protected void initialize() throws Exception {
      folder = new Folder(connectAnchor);
      hs = new HostSystem(connectAnchor);
      ns = new NetworkSystem(connectAnchor);
      vmwareDvsHelper = new DistributedVirtualSwitchHelper(connectAnchor);
      dvpg = new DistributedVirtualPortgroup(connectAnchor);
      dvsName = getTestName();
   }

   /**
    * Add host and physical nics into DVS config spec
    *
    * @param configSpec
    *           DVS Config Spec
    * @param Map
    *           pNicMap for dvs
    *
    * @return DVSConfigSpec
    *
    * @throws MethodFault
    *            , Exception
    *
    */
   public static DVSConfigSpec addHostsAndPnicsToDVSConfigSpec(
         DVSConfigSpec configSpec,
         final Map<ManagedObjectReference, String[]> pNicMap, String dvsName)
         throws Exception {
      if (pNicMap != null && pNicMap.size() > 0) {
         final Vector<DistributedVirtualSwitchHostMemberConfigSpec> backingList = new Vector<DistributedVirtualSwitchHostMemberConfigSpec>();
         if (configSpec == null) {
            configSpec = new DVSConfigSpec();
            configSpec.setConfigVersion("");
            configSpec.setName(dvsName = (dvsName != null) ? dvsName : TestUtil
                  .getShortTime());
            configSpec.setNumStandalonePorts(1);
         }
         final Set<ManagedObjectReference> hostSet = pNicMap.keySet();
         final Iterator<ManagedObjectReference> hostItr = hostSet.iterator();
         while (hostItr.hasNext()) {
            final ManagedObjectReference mor = (ManagedObjectReference) hostItr
                  .next();
            final String[] pnics = pNicMap.get(mor);
            final DistributedVirtualSwitchHostMemberConfigSpec hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
            hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
            hostMember.setHost(mor);

            List<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecList = new ArrayList<DistributedVirtualSwitchHostMemberPnicSpec>();
            for (int i = 0; i < pnics.length; i++) {
               DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
               pnicSpec.setPnicDevice(pnics[i]);
               pnicSpecList.add(pnicSpec);
            }
            final DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
            pnicBacking.getPnicSpec().clear();
            pnicBacking.getPnicSpec()
                  .addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(pnicSpecList
                        .toArray(new DistributedVirtualSwitchHostMemberPnicSpec[pnicSpecList
                              .size()])));
            hostMember.setBacking(pnicBacking);
            backingList.add(hostMember);
         }
         configSpec.getHost().clear();
         configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(TestUtil.vectorToArray(backingList)));
      } else {
         log.warn("pNicMap == NULL");
      }
      return configSpec;
   }

   /**
    * Create a new Distributed Virtual Switch in the folder specified.
    *
    * @param parentFolderMor
    *           Destination parent folder MOR object
    * @param dvsConfigSpec
    *           DVSConfigSpec
    *
    * @return ManagedObjectReference MOR of the DV Switch created.
    *
    * @throws MethodFault
    *            , Exception
    *
    * @see DistributedVirtualSwitch.validateDVSConfigSpec
    */
   public ManagedObjectReference createDistributedVirtualSwitchEx(
         final ManagedObjectReference parentFolderMor,
         final DVSConfigSpec dvsConfigSpec, String vDsVersion)
         throws Exception {
      String dvsName = null;
      ManagedObjectReference dvsMor = null;
      DVSCreateSpec dvsCreateSpec = null;
      if (dvsConfigSpec != null) {
         spec = DVSUtil.getProductSpec(connectAnchor, vDsVersion);
         dvsCreateSpec = DVSUtil.createDVSCreateSpec(DVSUtil
               .createDefaultDVSConfigSpec(null), spec, null);
         dvsCreateSpec.setConfigSpec(dvsConfigSpec);
         dvsName = dvsConfigSpec.getName();
      }
      log.info("Creating DVS with name '{}'", dvsName);
      boolean taskSuccess = false;
      final ManagedObjectReference taskMor;
      final Task mTasks = new Task(super.getConnectAnchor());
      taskMor = folder.asyncCreateDistributedVirtualSwitch(parentFolderMor,
            dvsCreateSpec);
      taskSuccess = mTasks.monitorTask(taskMor);
      final TaskInfo taskInfo = mTasks.getTaskInfo(taskMor);
      if (taskSuccess) {
         dvsMor = (ManagedObjectReference) taskInfo.getResult();
      } else {
         throw new com.vmware.vc.MethodFaultFaultMsg("",
                  taskInfo.getError().getFault());
      }
      if (dvsMor == null) {
         log.warn("Null returned for Distributed Virtual Switch" + " MOR");
      }
      return dvsMor;
   }

   /**
    * Create a DVS by adding a free NIC of the host.
    *
    * @param name
    *           Name of the DVS.
    * @param hostMor
    *           Host to be added to DVS with pNIC.
    * @return MOR of created DVS.
    * @throws Exception
    */
   public ManagedObjectReference createDVSWithNicsEx(final String name,
         String vDsVersion) throws Exception {
      final ManagedObjectReference newDvsMor;
      final Map<ManagedObjectReference, String[]> pNics;
      dvsCfg = new VMwareDVSConfigSpec();
      dvsCfg.setName(name);
      netFolderMor = folder.getNetworkFolder(folder.getDataCenter());
      pNics = new HashMap<ManagedObjectReference, String[]>();
      List<ManagedObjectReference> hostMors = hs.getAllHost();
      for (final ManagedObjectReference aHostMor : hostMors) {
         String[] freePnics = ns.getPNicIds(aHostMor, false);
         Assert.assertNotEmpty(freePnics, "No free nics found in host.");
         if (freePnics.length > 4)
            freePnics = Arrays.copyOfRange(freePnics, 0, 4);
         pNics.put(aHostMor, freePnics);
      }

      dvsCfg = (VMwareDVSConfigSpec) addHostsAndPnicsToDVSConfigSpec(dvsCfg,
            pNics, getTestId());
      newDvsMor = createDistributedVirtualSwitchEx(netFolderMor, dvsCfg,
            vDsVersion);
      assertNotNull(newDvsMor, "newDvsMor is NULL");
      dvsCfgInfo = vmwareDvsHelper.getConfig(newDvsMor);
      log.info("Created DVS {}", dvsCfgInfo.getName());
      return newDvsMor;
   }

   /**
    * Create a DVS by adding a free NIC of the host.
    *
    * @param name
    *           Name of the DVS.
    * @param hostMor
    *           Host to be added to DVS with pNIC.
    * @return MOR of created DVS.
    * @throws Exception
    */
   public ManagedObjectReference createDVSWithNics(final String name)
         throws Exception {
      final ManagedObjectReference newDvsMor;
      final Map<ManagedObjectReference, String[]> pNics;
      dvsCfg = new VMwareDVSConfigSpec();
      dvsCfg.setName(name);
      netFolderMor = folder.getNetworkFolder(folder.getDataCenter());
      pNics = new HashMap<ManagedObjectReference, String[]>();
      List<ManagedObjectReference> hostMors = hs.getAllHost();
      for (final ManagedObjectReference aHostMor : hostMors) {
         String[] freePnics = ns.getPNicIds(aHostMor, false);
         Assert.assertNotEmpty(freePnics, "No free nics found in host.");
         if (freePnics.length > 4)
            freePnics = Arrays.copyOfRange(freePnics, 0, 4);
         pNics.put(aHostMor, freePnics);
      }

      dvsCfg = (VMwareDVSConfigSpec) addHostsAndPnicsToDVSConfigSpec(dvsCfg,
            pNics, getTestId());
      newDvsMor = folder.createDistributedVirtualSwitch(netFolderMor, dvsCfg);
      assertNotNull(newDvsMor, "newDvsMor is NULL");
      dvsCfgInfo = vmwareDvsHelper.getConfig(newDvsMor);
      log.info("Created DVS {}", dvsCfgInfo.getName());
      return newDvsMor;
   }

   /**
    * Create the port groups and populate the MultiMaps for further use.<br>
    */
   protected void setupPortgroups(final ManagedObjectReference dvsMor)
         throws Exception {
      DistributedVirtualSwitchPortCriteria criteria;
      // need at least 2 port groups.
      final String[] pgTypes = { DVPORTGROUP_TYPE_EARLY_BINDING,
            DVPORTGROUP_TYPE_EARLY_BINDING };
      for (int i = 0; i < pgTypes.length; i++) {
         final String pgName = getTestId() + "-pg-" + i + "-" + pgTypes[i];
         log.debug("Adding DVPG: {} with '{}' ports", pgName, 8);
         final String pgKey = vmwareDvsHelper.addPortGroup(dvsMor, pgTypes[i],
               8, pgName);
         criteria = vmwareDvsHelper.getPortCriteria(null, null, null,
               new String[] { pgKey }, null, true);
         final List<String> ports = vmwareDvsHelper.fetchPortKeys(dvsMor,
               criteria);
         Assert.assertNotEmpty(ports, "No ports in PG: " + pgName);
         log.info("Added PG {} with ports {}", pgKey, ports);
      }
   }

   /**
    * This method verifies that the actual verify HealthCheckConfig retrieved is
    * equal to the expected healthCheckConfig on host
    *
    * @param connectAnchor
    * @param hostMor
    * @param vdsUuid
    * @param DVSHealthCheckConfig
    * @return true - if the actual HealthCheckConfig returned is equal to the
    *         expected value, false otherwise
    * @throws Exception
    */
   public static boolean verifyHealthCheckConfigOnHost(
         ConnectAnchor connectAnchor, ManagedObjectReference hostMor,
         String vdsUuid, DVSHealthCheckConfig[] expectedHealthCheckConfig)
         throws Exception {
      assertNotNull(connectAnchor, "The connect anchor is null");
      assertNotNull(hostMor, "The host Mor is null");
      HostSystem hostSystem = new HostSystem(connectAnchor);
      UserSession hostLoginSession = null;
      ConnectAnchor hostConnectAnchor = new ConnectAnchor(hostSystem
            .getHostName(hostMor), connectAnchor.getPort());
      SessionManager sessionManager = new SessionManager(hostConnectAnchor);
      ManagedObjectReference sessionMgrMor = sessionManager.getSessionManager();
      hostLoginSession = new SessionManager(hostConnectAnchor).login(
            sessionMgrMor, TestConstants.ESX_USERNAME,
            TestConstants.ESX_PASSWORD, null);
      Assert.assertNotNull(hostLoginSession, "Cannot login into the host");
      InternalHostDistributedVirtualSwitchManager hdvs = new InternalHostDistributedVirtualSwitchManager(
            hostConnectAnchor);
      InternalServiceInstance msi = new InternalServiceInstance(
            hostConnectAnchor);
      ManagedObjectReference hostDVSMgrMor = msi
            .getInternalServiceInstanceContent()
            .getHostDistributedVirtualSwitchManager();

      boolean verify = true;
      DVSHealthCheckConfig[] actualHealthCheckConfig = com.vmware.vcqa.util.TestUtil
            .vectorToArray(hdvs
                  .retrieveDVSConfigSpec(hostDVSMgrMor, vdsUuid).getHealthCheckConfig(), com.vmware.vc.DVSHealthCheckConfig.class);
      for (int i = 0; i < expectedHealthCheckConfig.length; i++) {
         for (int j = 0; j < actualHealthCheckConfig.length; j++) {
            if (expectedHealthCheckConfig[i].getClass().getName().equals(
                  actualHealthCheckConfig[j].getClass().getName())) {
               verify &= TestUtil.compareObject(actualHealthCheckConfig[j],
                     expectedHealthCheckConfig[i], null);
               if (verify == false) {
                  log.info("Verification failed for HealthCheckConfig on :" + hostSystem
                        .getHostName(hostMor));
                  break;
               }
            }
         }
      }

      return verify;
   }

   protected boolean
         configHealthCheck(DVSHealthCheckConfig[] healthCheckConfig)
               throws Exception {

      if (healthCheckConfig == null) {
         log.info("Null parameter is input for DVSHealthCheckConfig[] healthCheckConfig");
         return false;
      }
      vmwareDvsHelper.updateDVSHealthCheckConfig(dvsMor, healthCheckConfig);

      DVSHealthCheckConfig[] actualHealthCheckConfig = null;
      dvsCfgInfo = vmwareDvsHelper.getConfig(dvsMor);
      actualHealthCheckConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(dvsCfgInfo.getHealthCheckConfig(), com.vmware.vc.DVSHealthCheckConfig.class);
      if (actualHealthCheckConfig == null) {
         log.info("Retrieved HealthCheckConfig in vDS is null");
         return false;
      }

      for (int i = 0; i < healthCheckConfig.length; i++) {
            for (int j = 0; j < actualHealthCheckConfig.length; j++) {
                if (healthCheckConfig[i].getClass().getName().equals(
                      actualHealthCheckConfig[j].getClass().getName())) {
                    if (TestUtil.compareObject(actualHealthCheckConfig[j],
                        healthCheckConfig[i], null) == false) {
                        log.info("Retrieved HealthCheckConfig in vDS " +
                            " is not equal to that one configured before");
                        return false;
                    }
                }
            }
      }

      DistributedVirtualSwitchHostMember[] hostMembers = com.vmware.vcqa.util.TestUtil.vectorToArray(dvsCfgInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
      if (hostMembers != null && hostMembers.length > 0) {
         for (DistributedVirtualSwitchHostMember hostMember : hostMembers) {
            ManagedObjectReference hostMor = hostMember.getConfig().getHost();
            if (hostMor != null) {
               if (verifyHealthCheckConfigOnHost(connectAnchor, hostMor,
                     dvsCfgInfo.getUuid(), healthCheckConfig) == false) {
                  log.info("Verification failed for HealthCheckConfig on host");
                  return false;
               }
            } else {
               log.warn("hostMor is null on DistributedVirtualSwitchHostMember config. Skipping HealthCheckConfig verfication host");
            }
         }

      } else {
         log.warn("DistributedVirtualSwitchHostMember is null on VC. Skipping HealthCheckConfig verfication host");
      }

      return true;
   }

   protected int SetVlanforDvpg() throws Exception {

      int vlanid = 0;
      DistributedVirtualPortgroup iDVPortGroup = null;
      List<ManagedObjectReference> dvpgMors = null;
      ManagedObjectReference pgMor = null;

      iDVPortGroup = new DistributedVirtualPortgroup(connectAnchor);
      dvpgMors = vmwareDvsHelper.getPortgroup(dvsMor);
      if ((dvpgMors != null) && (dvpgMors.size() > 0)) {
         for (int i = 0; i < dvpgMors.size(); i++) {
            pgMor = dvpgMors.get(i);
            if (iDVPortGroup.isUplinkPortgroup(pgMor, dvsMor) == false) {
               break;
            }
         }
      }

      if (vlanID == -1) {
         // Pick up a random vlan id
         Random rand = new Random();
         vlanid = rand.nextInt(4095);
      }
      else {
         vlanid = vlanID;
      }

      VmwareDistributedVirtualSwitchTrunkVlanSpec vlanspec = null;
      NumericRange range = null;

      vlanspec = new VmwareDistributedVirtualSwitchTrunkVlanSpec();
      range = new NumericRange();
      range.setStart(vlanid);
      range.setEnd(vlanid);
      vlanspec.getVlanId().clear();
      vlanspec.getVlanId().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new NumericRange[] { range }));

      VMwareDVSPortSetting dvPortSetting = null;
      dvPortSetting = (VMwareDVSPortSetting) iDVPortGroup.getConfigInfo(pgMor)
            .getDefaultPortConfig();
      dvPortSetting.setVlan(vlanspec);

      DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
      dvPortgroupConfigSpec = iDVPortGroup.getConfigSpec(pgMor);
      dvPortgroupConfigSpec.setDefaultPortConfig(dvPortSetting);
      dvPortgroupConfigSpec.setConfigVersion(iDVPortGroup.getConfigInfo(pgMor)
            .getConfigVersion());
      iDVPortGroup.reconfigure(pgMor, dvPortgroupConfigSpec);

      return vlanid;
   }

   protected void SetTeamingPolicyforDvpg(String teamingPolicy)
         throws Exception {
      DistributedVirtualPortgroup iDVPortGroup = null;
      List<ManagedObjectReference> dvpgMors = null;
      ManagedObjectReference pgMor = null;

      iDVPortGroup = new DistributedVirtualPortgroup(connectAnchor);
      dvpgMors = vmwareDvsHelper.getPortgroup(dvsMor);
      if ((dvpgMors != null) && (dvpgMors.size() > 0)) {
         for (int i = 0; i < dvpgMors.size(); i++) {
            pgMor = dvpgMors.get(i);
            if (iDVPortGroup.isUplinkPortgroup(pgMor, dvsMor) == false) {
               break;
            }
         }
      }

      VMwareDVSPortSetting dvPortSetting = null;
      dvPortSetting = (VMwareDVSPortSetting) iDVPortGroup.getConfigInfo(pgMor)
            .getDefaultPortConfig();

      VmwareUplinkPortTeamingPolicy uplinkPolicy = null;
      uplinkPolicy = dvPortSetting.getUplinkTeamingPolicy();
      uplinkPolicy.setInherited(false);
      uplinkPolicy.setPolicy(DVSUtil.getStringPolicy(false, teamingPolicy));
      dvPortSetting.setUplinkTeamingPolicy(uplinkPolicy);

      DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
      dvPortgroupConfigSpec = iDVPortGroup.getConfigSpec(pgMor);
      assertNotNull(dvPortgroupConfigSpec, "dvPortgroupConfigSpec is null");
      dvPortgroupConfigSpec.setDefaultPortConfig(dvPortSetting);
      dvPortgroupConfigSpec.setConfigVersion(iDVPortGroup.getConfigInfo(pgMor)
            .getConfigVersion());
      iDVPortGroup.reconfigure(pgMor, dvPortgroupConfigSpec);
   }

   /**
    * Destroy given DVS.<br>
    *
    * @param mor
    *           MOR of the entity to be destroyed.
    * @return boolean true, if destroyed.
    */
   boolean destroy(final ManagedObjectReference mor) {
      boolean status = false;
      if (mor != null) {
         try {
            status = vmwareDvsHelper.destroy(mor);
         } catch (final Exception e) {
            log.error("Failed to destroy the DVS", e);
         }
      } else {
         log.info("Given MOR is null");
         status = true;
      }
      return status;
   }
}

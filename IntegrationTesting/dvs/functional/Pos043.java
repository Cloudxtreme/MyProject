/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostPortGroupSpec;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.UserSession;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * PR# 395300 : test case 4 <br>
 * 1. Create a DVS with 1 static, 1 dynamic, 1 ephemeral PGs (say 2 ports each)<br>
 * 2. Add 2 hosts to it<br>
 * 3. Create 3 vmknics and move one each to static, dynamic and ephemeral PG<br>
 * 4. Reconfigure host-vmknic and host-vswifnic to same PG again<br>
 * 5. Create one vmknic via hostd and connect it to ephemeral PG<br>
 */
public class Pos043 extends TestBase
{
   private SessionManager sessionManager = null;
   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Map allHosts = null;
   private ManagedObjectReference[] hostMors = null;
   private NetworkSystem iNetworkSystem = null;
   private String dvSwitchUuid = null;
   private UserSession loginSession = null;
   private Folder iFolder = null;
   private NetworkSystem ins = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference dvsMOR = null;
   private DVSConfigSpec configSpec = null;
   private ManagedObjectReference networkFolderMor = null;
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DistributedVirtualPortgroup idvpg = null;
   private ManagedObjectReference nsMor = null;
   private Map<String, DVPortgroupConfigSpec> hmPgConfig = new HashMap<String, DVPortgroupConfigSpec>();
   private HostPortGroupSpec hostPgSpec = null;
   private String vswitchId = null;
   private String pgName = null;
   private HostVirtualNicSpec hostVNicSpec = null;
   private String[] ips = { "100.100.100.100", "100.100.100.101",
            "100.100.100.102", "100.100.100.103", "100.100.100.104" };
   private Map<String, HostVirtualNicSpec> hmHostVirtualNicSpecs = new HashMap<String, HostVirtualNicSpec>();
   private Map<String, HostVirtualNicSpec> hmHostvNicSpecs = new HashMap<String, HostVirtualNicSpec>();
   private HostVirtualNicSpec vnicSpec = null;
   private HostVirtualNicSpec origVnicSpec = null;
   private String vNicdevice = null;
   private HostVirtualNicSpec origconsoleVnicSpec = null;
   private HostVirtualNicSpec consoleVnicSpec = null;
   private String consoleVnicdevice = null;
   private Map<String, DistributedVirtualSwitchPortConnection> hmDistributedVirtualSwitchPortConnection = new HashMap<String, DistributedVirtualSwitchPortConnection>();
   private String elPortgroupKey = null;
   private String lbPortgroupKey = null;
   private String ephPortgroupKey = null;
   private ManagedObjectReference lpg = null;
   private ManagedObjectReference epg = null;
   private ManagedObjectReference ephepg = null;
   private List<DistributedVirtualSwitchPortConnection> alPortConn = new ArrayList<DistributedVirtualSwitchPortConnection>();
   private ConnectAnchor hostConnectAnchor = null;
   private String hostName = null;
   private List<String> vnicList = new ArrayList<String>();

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription("PR# 395300  : test case 4\n"
               + " 1. Create a DVS with 1 static, "
               + "1 dynamic, 1 ephemeral PGs (say 2 ports each) "
               + " 2. Add 2 hosts to it\n"
               + " 3. Create 3 vmknics  and  move one each to  static, "
               + " dynamic and  ephemeral PG \n"
               + " 4. Reconfigure host-vmknic and host-vswifnic to same PG again \n"
               + " 5. Create one vmknic via hostd  and connect it to ephemeral PG");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      sessionManager = new SessionManager(connectAnchor);
      boolean status = false;
      Iterator it = null;
      String[] pnicIds = null;
      hostMors = new ManagedObjectReference[2];
      DistributedVirtualSwitchHostMemberPnicSpec hostPnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking hostPnicBacking = null;
      DistributedVirtualSwitchHostMemberConfigSpec[] hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec[2];
      String dvsName = getTestId();
      log.info("Test setup Begin:");
     
         loginSession = SessionManager.login(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         log.info("Login Successful : Login User = "
                  + loginSession.getUserName());
         iFolder = new Folder(connectAnchor);
         iDistributedVirtualSwitch = new DistributedVirtualSwitch(connectAnchor);
         ihs = new HostSystem(connectAnchor);
         ins = new NetworkSystem(connectAnchor);
         idvpg = new DistributedVirtualPortgroup(connectAnchor);
         dcMor = iFolder.getDataCenter();
         ihs = new HostSystem(connectAnchor);
         iNetworkSystem = new NetworkSystem(connectAnchor);
         allHosts = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
         if ((allHosts != null) && (allHosts.size() >= 2)) {
            it = allHosts.keySet().iterator();
            hostMors[0] = (ManagedObjectReference) it.next();
            hostName = ihs.getHostName(hostMors[0]);
            hostMors[1] = (ManagedObjectReference) it.next();
            log.info("Found a host with free pnics in the inventory");
            nsMor = ins.getNetworkSystem(hostMors[0]);
            if (nsMor != null) {
               pnicIds = ins.getPNicIds(hostMors[0]);
               if (pnicIds != null) {
                  status = true;
               } else {
                  log.error("There are no free pnics on the host");
               }
            } else {
               log.error("The network system MOR is null");
            }
         } else {
            log.error("Valid Host MOR not found");
            status = false;
         }
         if (status) {
            networkFolderMor = iFolder.getNetworkFolder(dcMor);
            if (networkFolderMor != null) {
               configSpec = new DVSConfigSpec();
               configSpec.setConfigVersion("");
               configSpec.setName(dvsName);
               configSpec.setNumStandalonePorts(1);
               String[] hostPhysicalNics = null;
               for (int i = 0; i < 2; i++) {
                  hostPhysicalNics = iNetworkSystem.getPNicIds(hostMors[i]);
                  if (hostPhysicalNics != null) {
                     hostConfigSpecElement[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
                     hostPnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     hostPnicSpec.setPnicDevice(hostPhysicalNics[0]);
                     hostPnicSpec.setUplinkPortKey(null);
                     hostPnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                     hostPnicBacking.getPnicSpec().clear();
                     hostPnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { hostPnicSpec }));
                     hostConfigSpecElement[i].setBacking(hostPnicBacking);
                     hostConfigSpecElement[i].setHost(hostMors[i]);
                     hostConfigSpecElement[i].setOperation(TestConstants.CONFIG_SPEC_ADD);
                     if (i == 1) {
                        hostConfigSpecElement[i].setMaxProxySwitchPorts(DVSTestConstants.DVS_DEFAULT_NUM_UPLINK_PORTS + 2);
                     }
                  } else {
                     status = false;
                     log.error("No free pnics found on the host.");
                  }
               }
               configSpec.getHost().clear();
               configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostConfigSpecElement));
            } else {
               status = false;
               log.error("Failed to create the network folder");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "PR# 395300  : test case 4\n"
               + " 1. Create a DVS with 1 static, "
               + "1 dynamic, 1 ephemeral PGs (say 2 ports each) "
               + " 2. Add 2 hosts to it\n"
               + " 3. Create 3 vmknics  and  move one each to  static, "
               + " dynamic and  ephemeral PG \n"
               + " 4. Reconfigure host-vmknic and host-vswifnic to same PG again \n"
               + " 5. Create one vmknic via hostd  and connect it to ephemeral PG")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      Vector<DistributedVirtualSwitchPortConnection> pcs = new Vector<DistributedVirtualSwitchPortConnection>();
      List<String> alvnics = new ArrayList<String>();
     
         if (configSpec != null) {
            /*
             * Get the host-vmknic and host-vswifnic
             */
            HostNetworkConfig nwCfg = ins.getNetworkConfig(nsMor);
            if (nwCfg != null && com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0] != null) {
               HostVirtualNicConfig vnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
               origVnicSpec = vnicConfig.getSpec();
               vnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origVnicSpec);
               vNicdevice = vnicConfig.getDevice();
               log.info("VnicDevice : " + vNicdevice);
               alvnics.add(vNicdevice);
               hmHostvNicSpecs.put(vNicdevice, vnicSpec);
               status = true;
            } else {
               log.error("Unable to find valid Vnic");
            }
            if (status && nwCfg != null && com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0) {
               HostVirtualNicConfig consoleVnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
               origconsoleVnicSpec = consoleVnicConfig.getSpec();
               consoleVnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origconsoleVnicSpec);
               consoleVnicdevice = consoleVnicConfig.getDevice();
               alvnics.add(consoleVnicdevice);
               log.info("consoleVnicDevice : " + consoleVnicdevice);
               hmHostvNicSpecs.put(consoleVnicdevice, consoleVnicSpec);
            }
            /*
             * Create vswitch here
             */
            vswitchId = getTestId() + "-vswitch";
            pgName = getTestId() + "-PG";
            if (ins.addVirtualSwitch(nsMor, vswitchId, null)) {
               log.info("Successfully added the Virtual Switch"
                        + vswitchId);
               hostVNicSpec = ins.createVNicSpecification();
               addVNIC(ips[0], getTestId() + "-pg1");
               addVNIC(ips[1], getTestId() + "-pg2");
               addVNIC(ips[2], getTestId() + "-pg3");
               status = true;
            } else {
               log.error("Unable to add the Vitual Switch");
            }
            if (status) {
               dvsMOR = iFolder.createDistributedVirtualSwitch(
                        networkFolderMor, configSpec);
               if (dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  if (iNetworkSystem.refresh(iNetworkSystem.getNetworkSystem(hostMors[0]))
                           && iNetworkSystem.refresh(iNetworkSystem.getNetworkSystem(hostMors[1]))) {
                     if (iDistributedVirtualSwitch.validateDVSConfigSpec(
                              dvsMOR, configSpec, null)) {
                        /*
                         * add pgs here
                         */
                        epg = addPG(
                                 dvsMOR,
                                 DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                        if (epg != null) {
                           elPortgroupKey = idvpg.getKey(epg);
                           if (elPortgroupKey != null) {
                              portConnection = iDistributedVirtualSwitch.getPortConnection(
                                       dvsMOR, null, false, null,
                                       elPortgroupKey);
                              pcs.add(portConnection);
                              hmDistributedVirtualSwitchPortConnection.put(
                                       DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING,
                                       portConnection);
                           }
                        }
                        lpg = addPG(dvsMOR,
                                 DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
                        if (lpg != null) {
                           lbPortgroupKey = idvpg.getKey(lpg);
                           if (lbPortgroupKey != null) {
                              portConnection = iDistributedVirtualSwitch.getPortConnection(
                                       dvsMOR, null, false, null,
                                       lbPortgroupKey);
                              pcs.add(portConnection);
                              hmDistributedVirtualSwitchPortConnection.put(
                                       DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING,
                                       portConnection);
                           }
                        }
                        ephepg = addPG(dvsMOR,
                                 DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL);
                        if (ephepg != null) {
                           ephPortgroupKey = idvpg.getKey(ephepg);
                           if (ephPortgroupKey != null) {
                              DVSConfigInfo info = iDistributedVirtualSwitch.getConfig(dvsMOR);
                              dvSwitchUuid = info.getUuid();
                              portConnection = new DistributedVirtualSwitchPortConnection();
                              portConnection.setSwitchUuid(dvSwitchUuid);
                              portConnection.setPortgroupKey(ephPortgroupKey);
                              pcs.add(portConnection);
                           }
                        }
                        /*
                         * Move each vmknic to static, dynamic and ephemeral PG.
                         */
                        Set keys = hmHostVirtualNicSpecs.keySet();
                        Iterator itVnic = keys.iterator();
                        int i = 0;
                        while (itVnic.hasNext()) {
                           String vmknic = (String) itVnic.next();
                           if (moveVmkNicToPG(pcs.get(i), vmknic)) {
                              log.info("Successfully moved vmknic : "
                                       + vmknic);
                              i++;
                           }
                        }
                        /*
                         * Reconfigure host-vmknic and host-vswifnic to same PG
                         * again
                         */
                        String port = iDistributedVirtualSwitch.getFreePortInPortgroup(
                                 dvsMOR, elPortgroupKey, null);
                        portConnection = new DistributedVirtualSwitchPortConnection();
                        portConnection.setSwitchUuid(dvSwitchUuid);
                        portConnection.setPortgroupKey(elPortgroupKey);
                        portConnection.setPortKey(port);
                        alPortConn.add(portConnection);
                        port = iDistributedVirtualSwitch.getFreePortInPortgroup(
                                 dvsMOR, lbPortgroupKey, null);
                        portConnection = new DistributedVirtualSwitchPortConnection();
                        portConnection.setSwitchUuid(dvSwitchUuid);
                        portConnection.setPortgroupKey(lbPortgroupKey);
                        portConnection.setPortKey(port);
                        alPortConn.add(portConnection);
                        i = 0;
                        for (String vnics : alvnics) {
                           if (moveHostVmkNicToPG(alPortConn.get(i), vnics)) {
                              log.info("Successfully moved vmknic : "
                                       + vnics);
                              i++;
                           }
                        }
                        /*
                         * Create one vmknic on host-client and connect it to
                         * ephemeral PG
                         */
                        ConnectAnchor hostConnectAnchor = new ConnectAnchor(
                                 hostName,
                                 data.getInt(TestConstants.TESTINPUT_PORT));
                        if (hostConnectAnchor != null) {
                           log.info("Successfully obtained the connect"
                                    + " anchor to the host");
                           HostSystem hostIhs = null;
                           NetworkSystem hostINetworkSystem = null;
                           ManagedObjectReference hostHostMor = null;
                           ManagedObjectReference hostNsMor = null;
                           UserSession newLoginSession = null;
                           AuthorizationManager newAuthentication = null;
                           ManagedObjectReference newAuthenticationMor = null;
                           newAuthentication = new AuthorizationManager(
                                    hostConnectAnchor);
                           sessionManager = new SessionManager(hostConnectAnchor);
                           newAuthenticationMor = sessionManager.getSessionManager();
                           if (newAuthenticationMor != null) {
                              newLoginSession = sessionManager.login(
                                       newAuthenticationMor,
                                       TestConstants.ESX_USERNAME,
                                       TestConstants.ESX_PASSWORD, null);
                              if (newLoginSession != null) {
                                 hostIhs = new HostSystem(connectAnchor);
                                 hostINetworkSystem = new NetworkSystem(
                                          connectAnchor);
                                 hostHostMor = hostIhs.getHost(hostName);
                                 hostNsMor = hostINetworkSystem.getNetworkSystem(hostHostMor);
                                 hostVNicSpec = hostINetworkSystem.createVNicSpecification();
                                 String vnic1 = addVNICFromHost(ips[3],
                                          hostINetworkSystem, hostNsMor);
                                 portConnection = new DistributedVirtualSwitchPortConnection();
                                 portConnection.setSwitchUuid(dvSwitchUuid);
                                 portConnection.setPortgroupKey(ephPortgroupKey);
                                 if (moveVmkNicToPG(portConnection, vnic1,
                                          ips[3], dvSwitchUuid,
                                          hostINetworkSystem, hostNsMor)) {
                                    log.info("Successfully moved vmknic : "
                                             + vnic1);
                                    status = true;
                                 }
                              } else {
                                 log.error("Can not login into the host "
                                          + hostName);
                              }
                           } else {
                              log.error("The session manager object is null");
                           }
                        } else {
                           status = false;
                           log.error("Can not obtain the connect "
                                    + "anchor to the host");
                        }
                     } else {
                        log.info("The config spec of the Distributed Virtual "
                                 + "Switch is not created as per specifications");
                     }
                  }
               } else {
                  log.error("Cannot create the distributed "
                           + "virtual switch with the config spec passed");
               }
            }
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (origconsoleVnicSpec != null) {
            if (ins.updateServiceConsoleVirtualNic(nsMor, consoleVnicdevice,
                     origconsoleVnicSpec)) {
               log.info("Successfully restored original console  VirtualNic "
                        + "config: " + consoleVnicdevice);
            } else {
               log.info("Unable to restore console VirtualNic "
                        + consoleVnicdevice);
               status &= false;
            }
         }
         if (origVnicSpec != null) {
            if (ins.updateVirtualNic(nsMor, vNicdevice, origVnicSpec)) {
               log.info("Successfully restored original VirtualNic "
                        + "config: " + vNicdevice);
               status &= true;
            } else {
               log.info("Unable to update VirtualNic " + vNicdevice);
               status &= false;
            }
         }
         /*
          * remove all newly created vnics here
          */
         if (vnicList != null && vnicList.size() > 0) {
            for (String vnic : vnicList) {
               if (ins.removeVirtualNic(nsMor, vnic)) {
                  log.info("Successfully removed  VirtualNic : " + vnic);
               }
            }
            ins.removeVirtualSwitch(nsMor, vswitchId, true);
         }
         if (dvsMOR != null) {
            status &= iDistributedVirtualSwitch.destroy(dvsMOR);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= SessionManager.logout(connectAnchor);
      }
      return status;
   }

   private boolean moveHostVmkNicToPG(DistributedVirtualSwitchPortConnection portConnection,
                                      String vmkNic)
      throws Exception
   {
      boolean status = false;
      DVSConfigInfo info = iDistributedVirtualSwitch.getConfig(dvsMOR);
      dvSwitchUuid = info.getUuid();
      hmHostvNicSpecs.get(vmkNic).setDistributedVirtualPort(portConnection);
      hmHostvNicSpecs.get(vmkNic).setPortgroup(null);
      if (vmkNic != null && vmkNic.startsWith("vswif")) {
         if (ins.updateServiceConsoleVirtualNic(nsMor, vmkNic,
                  hmHostvNicSpecs.get(vmkNic))) {
            log.info("Successfully updated ServiceConsoleVirtualNi "
                     + vmkNic);
            status = true;
         } else {
            log.error("Unable to update ServiceConsoleVirtualNiC "
                     + vmkNic);
            status = false;
         }
      } else {
         if (ins.updateVirtualNic(nsMor, vmkNic, hmHostvNicSpecs.get(vmkNic))) {
            log.info("Successfully updated VirtualNic " + vmkNic);
            status = true;
         } else {
            log.error("Unable to update VirtualNic " + vmkNic);
            status = false;
         }
      }
      return status;
   }

   private boolean moveVmkNicToPG(DistributedVirtualSwitchPortConnection portConnection,
                                  String vmkNic)
      throws Exception
   {
      boolean status = false;
      DVSConfigInfo info = iDistributedVirtualSwitch.getConfig(dvsMOR);
      dvSwitchUuid = info.getUuid();
      hmHostVirtualNicSpecs.get(vmkNic).setDistributedVirtualPort(
               portConnection);
      hmHostVirtualNicSpecs.get(vmkNic).setPortgroup(null);
      if (vmkNic != null && vmkNic.startsWith("vswif")) {
         if (ins.updateServiceConsoleVirtualNic(nsMor, vmkNic,
                  hmHostVirtualNicSpecs.get(vmkNic))) {
            log.info("Successfully updated ServiceConsoleVirtualNic "
                     + vmkNic);
            status = true;
         } else {
            log.error("Unable to update ServiceConsoleVirtualNic "
                     + vmkNic);
            status = false;
         }
      } else {
         if (ins.updateVirtualNic(nsMor, vmkNic,
                  hmHostVirtualNicSpecs.get(vmkNic))) {
            log.info("Successfully updated VirtualNic " + vmkNic);
            status = true;
         } else {
            log.error("Unable to update VirtualNic " + vmkNic);
            status = false;
         }
      }
      return status;
   }

   private boolean moveVmkNicToPG(DistributedVirtualSwitchPortConnection portConnection,
                                  String vmkNic,
                                  String ipAddress,
                                  String dvSwitchUuid,
                                  NetworkSystem ins,
                                  ManagedObjectReference nsMor)
      throws Exception
   {
      boolean status = false;
      hmHostVirtualNicSpecs.get(ipAddress).setDistributedVirtualPort(
               portConnection);
      hmHostVirtualNicSpecs.get(ipAddress).setPortgroup(null);
      if (vmkNic != null && vmkNic.startsWith("vswif")) {
         if (ins.updateServiceConsoleVirtualNic(nsMor, vmkNic,
                  hmHostVirtualNicSpecs.get(ipAddress))) {
            log.info("Successfully updated ServiceConsoleVirtualNic "
                     + vmkNic);
            status = true;
         } else {
            log.error("Unable to update ServiceConsoleVirtualNic "
                     + vmkNic);
            status = false;
         }
      } else {
         if (ins.updateVirtualNic(nsMor, vmkNic,
                  hmHostVirtualNicSpecs.get(ipAddress))) {
            log.info("Successfully updated VirtualNic " + vmkNic);
            status = true;
         } else {
            log.error("Unable to update VirtualNic " + vmkNic);
            status = false;
         }
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

   private String addVNIC(String ipaddress,
                          String pgName)
      throws Exception
   {
      String vNicId = null;
      HostVirtualNicSpec vnicSpec = null;
      hostPgSpec = ins.createPortGroupSpec(pgName);
      hostPgSpec.setVswitchName(vswitchId);
      if (ins.addPortGroup(nsMor, hostPgSpec)) {
         log.info("Successfully added the " + "VirtualSwitchPortGroup"
                  + pgName);
         vnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(hostVNicSpec);
         vnicSpec.getIp().setIpAddress(ipaddress);
         vNicId = ins.addVirtualNic(nsMor, pgName, vnicSpec);
         if (vNicId != null) {
            hmHostVirtualNicSpecs.put(vNicId, vnicSpec);
            log.info("Successfully added the Virtual NIC " + vNicId);
            vnicList.add(vNicId);
         } else {
            log.error("Unable to add the Virtual NIC");
         }
      } else {
         log.error("Unable to add the " + "VirtualSwitchPortGroup"
                  + this.pgName);
      }
      return vNicId;
   }

   private String addVNICFromHost(String ipaddress,
                                  NetworkSystem ins,
                                  ManagedObjectReference nsMor)
      throws Exception
   {
      String vNicId = null;
      HostVirtualNicSpec vnicSpec = null;
      String pgName = getTestId() + "-pgvnic";
      HostPortGroupSpec hostPgSpec = null;
      hostPgSpec = ins.createPortGroupSpec(pgName);
      hostPgSpec.setVswitchName(vswitchId);
      if (ins.addPortGroup(nsMor, hostPgSpec)) {
         log.info("Successfully added the " + "VirtualSwitchPortGroup"
                  + pgName);
         vnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(hostVNicSpec);
         vnicSpec.getIp().setIpAddress(ipaddress);
         vNicId = ins.addVirtualNic(nsMor, pgName, vnicSpec);
         if (vNicId != null) {
            hmHostVirtualNicSpecs.put(ipaddress, vnicSpec);
            log.info("Successfully added the Virtual NIC " + vNicId);
            vnicList.add(vNicId);
         } else {
            log.error("Unable to add the Virtual NIC");
         }
      } else {
         log.error("Unable to add the " + "VirtualSwitchPortGroup"
                  + this.pgName);
      }
      return vNicId;
   }

   /*
    * add pg here
    */
   private ManagedObjectReference addPG(ManagedObjectReference dvsMor,
                                        String type)
      throws Exception
   {
      ManagedObjectReference pgMor = null;
      DVPortgroupConfigSpec pgConfigSpec = new DVPortgroupConfigSpec();
      pgConfigSpec.setName(type);
      pgConfigSpec.setType(type);
      if (!type.equalsIgnoreCase(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL)) {
         pgConfigSpec.setNumPorts(2);
      }
      List<ManagedObjectReference> pgList = iDistributedVirtualSwitch.addPortGroups(
               dvsMor, new DVPortgroupConfigSpec[] { pgConfigSpec });
      if (pgList != null && pgList.size() == 1) {
         log.info("Successfully added the early binding "
                  + "portgroup to the DVS " + getTestId() + "-epg");
         pgMor = pgList.get(0);
         hmPgConfig.put(type, pgConfigSpec);
      }
      return pgMor;
   }

   private boolean reconfigurePG(ManagedObjectReference dvPG,
                                 String type)
      throws Exception
   {
      boolean result = false;
      DVSTrafficShapingPolicy outShapingPolicy = null;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      Map<String, Object> settingsMap = null;
      DVSTrafficShapingPolicy inShapingPolicy = null;
      VMwareDVSPortSetting portSetting = null;
      settingsMap = new HashMap<String, Object>();
      hmPgConfig.get(type).getScope().clear();
      hmPgConfig.get(type).getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { dcMor }));
      hmPgConfig.get(type).setPortNameFormat(
               DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
      inShapingPolicy = new DVSTrafficShapingPolicy();
      inShapingPolicy.setInherited(false);
      inShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
      inShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(false,
               new Long(10)));
      inShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false, new Long(50)));
      inShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(false, new Long(
               100)));
      settingsMap.put(DVSTestConstants.INSHAPING_POLICY_KEY, inShapingPolicy);
      outShapingPolicy = new DVSTrafficShapingPolicy();
      outShapingPolicy.setInherited(false);
      outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
      outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(false,
               new Long(10)));
      outShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false, new Long(50)));
      outShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(false, new Long(
               100)));
      settingsMap.put(DVSTestConstants.OUT_SHAPING_POLICY_KEY, outShapingPolicy);
      portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
      portgroupPolicy = new VMwareDVSPortgroupPolicy();
      portgroupPolicy.setBlockOverrideAllowed(false);
      portgroupPolicy.setShapingOverrideAllowed(false);
      portgroupPolicy.setVendorConfigOverrideAllowed(true);
      portgroupPolicy.setLivePortMovingAllowed(true);
      portgroupPolicy.setPortConfigResetAtDisconnect(true);
      portgroupPolicy.setVlanOverrideAllowed(true);
      portgroupPolicy.setUplinkTeamingOverrideAllowed(true);
      portgroupPolicy.setSecurityPolicyOverrideAllowed(false);
      hmPgConfig.get(type).setPolicy(portgroupPolicy);
      hmPgConfig.get(type).setDefaultPortConfig(portSetting);
      hmPgConfig.get(type).setConfigVersion(
               idvpg.getConfigInfo(dvPG).getConfigVersion());
      if (idvpg.reconfigure(dvPG, hmPgConfig.get(type))) {
         log.info("Successfully reconfigured the portgroup for " + type);
         result = true;
      } else {
         if (type.equalsIgnoreCase(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL)) {
            log.info("Successfully reconfigured the portgroup for "
                     + type);
            result = true;
         } else {
            result = false;
            log.error("Failed to reconfigure the portgroup for " + type);
         }
      }
      return result;
   }

}

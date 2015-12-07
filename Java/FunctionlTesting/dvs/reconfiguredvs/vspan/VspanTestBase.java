/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.dvs.InternalDVSHelper;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.MultiMap;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.dvs.VspanHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * <br>
 * Base class for all VSPAN session tests<br>
 * In each test there will be 64 combinations of source Tx and Rx ports which
 * will be tested by providing different data from XML.<br>
 * <br>
 * Initial validation:<br>
 * 1. Make sure that we have a host with at least 1 pNIC's free.<br>
 * 2. Host contains 2 powered on VM's (with 2 vNICs each).<br>
 * 3. A VMKnic in classic host to use it for wildcards.<br>
 * <br>
 * By default we create the following setup:<br>
 * 1. Create a DVS(5.0.0 and above) by adding the host using 1 free pNIC.<br>
 * 2. The DVS is reconfigured to add 2 port groups with 2 ports each.<br>
 * <br>
 * Implementation:<br>
 * There will be two MultiMap containing ports and portGroups in it, one for
 * Uplinks and another for added DVPortgroups. <br>
 * Ex: MultiMap[PG1:- p11,p12,... PG2:- p21,p22,...] <br>
 * In individual tests we use these MultiMap to get the DVPort and DVPortgroup
 * keys, also we use these when generating the combinations.<br>
 * <br>
 * VSPAN session tests typically need following setup:<br>
 * a. A host with a free pNIC so that DVS can use it.<br>
 * b. A VMKnic in classic host to use it for wildcards.<br>
 * c. 3 powered on VM's with 2 vNICs.<br>
 * <br>
 * Note: Properties in {@link #getProperties()} method will be set using data
 * from XML file.
 */
@SuppressWarnings("deprecation")
public abstract class VspanTestBase extends TestBase
{
   /** Pattern used to prefix zeros for generated keys. */
   private static final String PATTERN = "0000";
   /** Formatter used to format the generated keys. */
   private static final DecimalFormat FORMATTER = new DecimalFormat(PATTERN);
   protected ManagedObjectReference dvsMor;
   protected ManagedObjectReference netFolderMor;
   protected ManagedEntity me;
   protected Folder folder;
   protected HostSystem hs;
   protected NetworkSystem ns;
   protected VirtualMachine vm;
   protected DistributedVirtualSwitchHelper vmwareDvs;
   protected DistributedVirtualPortgroup dvpg;
   protected DVPortgroupConfigSpec dvPortgroupConfigSpec;
   protected final Map<ManagedObjectReference, VirtualMachineConfigSpec> vms;
   /**
    * Contains DVPortGroups and ports in the format<br>
    * portGroup-1= {port-1, port-2} <br>
    * portGroup-2= {port-1, port-2} <br>
    * This MultiMap will be populated on calling {@link #setupPortgroups()}<br>
    * => Keyset is a collection of DVPortgroups & values are a List of DVPorts.<br>
    */
   protected final MultiMap<String, String> portGroups;
   /** Contains only the uplink portGroup(s) and it's ports */
   protected final MultiMap<String, String> uplinkPortgroups;
   protected VMwareDVSConfigSpec dvsCfg;// Used to create DVS.
   private DVSConfigInfo dvsCfgInfo;// Holds the DVS info.
   protected VMwareDVSConfigSpec dvsReCfg;// Used for reconfiguring the DVS.
   protected VMwareDVSVspanConfigSpec[] vspanCfg;
   protected String dvsName;// Defaults to test case ID.
   protected ManagedObjectReference hostMor;
   protected int portsInDvpg = 2;// defaults to 2 if not given in data file.
   /* Data file properties */
   static final String NORMAL_TRAFFIC_ALLOWED = "normal-traffic-allowed";
   static final String STRIP_ORIGINAL_VLAN = "stripOriginalVlan";
   static final String ENABLED = "enabled";
   static final String ENCALSULATION_VLANID = "encapsulationVlanId";
   static final String MIRROR_PKT_LENGTH = "mirrorPacketLength";
   static final String PORTS_IN_DVPG = "ports-in-dvpg";
   /* Properties from data file */
   protected String[] srcTxWc;
   protected String[] srcRxWc;
   protected boolean normalTrafficAllowed;
   protected boolean stripOriginalVlan;
   protected boolean enabled;
   protected int encapsulationVlanId;
   protected int mirrorPacketLength;

   /**
    * Get the properties from data.
    */
   protected final void getProperties()
   {
      normalTrafficAllowed = data.getBoolean(NORMAL_TRAFFIC_ALLOWED);
      stripOriginalVlan = data.getBoolean(STRIP_ORIGINAL_VLAN);
      enabled = data.getBoolean(ENABLED);
      encapsulationVlanId = data.getInt(ENCALSULATION_VLANID);
      mirrorPacketLength = data.getInt(MIRROR_PKT_LENGTH);
      portsInDvpg = data.getInt(PORTS_IN_DVPG, portsInDvpg);
   }

   /**
    * Constructor.
    */
   public VspanTestBase()
   {
      // dvsName = getTestName() + "-dvs";
      portGroups = new MultiMap<String, String>();
      uplinkPortgroups = new MultiMap<String, String>();
      vms = new HashMap<ManagedObjectReference, VirtualMachineConfigSpec>();
   }

   public String getTestName()
   {
      return getTestId();
   }

   /**
    * Initialize the members.<br>
    *
    * @throws Exception
    */
   protected void initialize()
      throws Exception
   {
      folder = new Folder(connectAnchor);
      vm = new VirtualMachine(connectAnchor);
      hs = new HostSystem(connectAnchor);
      ns = new NetworkSystem(connectAnchor);
      vmwareDvs = new DistributedVirtualSwitchHelper(connectAnchor);
      dvpg = new DistributedVirtualPortgroup(connectAnchor);
      dvsName = getTestName();
   }

   /**
    * Create a DVS by adding a free NIC of the host.<br>
    *
    * @param name Name of the DVS.
    * @param hostMor Host to be added to DVS with pNIC.
    * @return MOR of created DVS.
    * @throws Exception
    */
   public ManagedObjectReference createDVSWithNic(final String name,
                                                  final ManagedObjectReference hostMor)
      throws Exception
   {
      final ManagedObjectReference newDvsMor;
      final Map<ManagedObjectReference, String> pNics;
      dvsCfg = new VMwareDVSConfigSpec();
      dvsCfg.setName(name);
      netFolderMor = folder.getNetworkFolder(folder.getDataCenter());
      pNics = new HashMap<ManagedObjectReference, String>();
      final String[] freePnics = ns.getPNicIds(hostMor, false);
      Assert.assertNotEmpty(freePnics, "No free nics found in host.");
      pNics.put(hostMor, freePnics[0]);
      dvsCfg = (VMwareDVSConfigSpec) DVSUtil.addHostsToDVSConfigSpecWithPnic(
               dvsCfg, pNics, getTestId());// FIXME Casting
      newDvsMor = folder.createDistributedVirtualSwitch(netFolderMor, dvsCfg);
      dvsCfgInfo = vmwareDvs.getConfig(newDvsMor);
      log.info("Created DVS {}", dvsCfgInfo.getName());
      return newDvsMor;
   }

   /**
    * Create the port groups and populate the MultiMaps for further use.<br>
    */
   protected void setupPortgroups(final ManagedObjectReference dvsMor)
      throws Exception
   {
      DistributedVirtualSwitchPortCriteria criteria;
      // need at least 3 port groups.
      final String[] pgTypes = { DVPORTGROUP_TYPE_EARLY_BINDING,
               DVPORTGROUP_TYPE_LATE_BINDING, DVPORTGROUP_TYPE_LATE_BINDING };
      for (int i = 0; i < pgTypes.length; i++) {
         final String pgName = getTestId() + "-pg-" + i + "-" + pgTypes[i];
         log.info("Adding DVPG: {} with '{}' ports", pgName, portsInDvpg);
         final String pgKey = vmwareDvs.addPortGroup(dvsMor, pgTypes[i],
                  portsInDvpg, pgName);
         criteria = vmwareDvs.getPortCriteria(null, null, null,
                  new String[] { pgKey }, null, true);
         final List<String> ports = vmwareDvs.fetchPortKeys(dvsMor, criteria);
         Assert.assertNotEmpty(ports, "No ports in PG: " + pgName);
         log.info("Added PG {} with ports {}", pgKey, ports);
         portGroups.put(pgKey, ports);
      }
   }

   /**
    * Collect uplink PG and UplinkName info for further use.<br>
    * The DVS should have a host member with at least one pNic connected.<br>
    *
    * @param aDvsMor
    * @throws Exception
    */
   protected void setupUplinkPorts(final ManagedObjectReference aDvsMor)
      throws Exception
   {
      // Fetch the uplink PG & ports to use, By default DVS has 4 uplink ports.
      final List<ManagedObjectReference> uplinks = vmwareDvs.getUplinkPortgroups(dvsMor);
      Assert.assertNotEmpty(uplinks, "No uplinks found in the DVS.");
      final ManagedObjectReference uplinkMor = uplinks.get(0);
      final String uplinkKey = dvpg.getKey(uplinkMor);
      final List<DistributedVirtualPort> uplinkPorts = dvpg.getPorts(uplinkMor);
      Assert.assertNotEmpty(uplinkPorts, "No ports found in Uplink PG: "
               + uplinkKey);
      for (final DistributedVirtualPort aUplinkPort : uplinkPorts) {
         log.info("Name: {}", aUplinkPort.getConfig().getName());
         log.info("Key : {}", aUplinkPort.getKey());
         uplinkPortgroups.putValue(uplinkKey, aUplinkPort.getConfig().getName());
      }
   }

   /**
    * Get VMs from a host member of DVS.<br>
    * Connect them to the DVPorts of DVS.<br>
    * This method will be called after
    * {@link #setupPortgroups(ManagedObjectReference)}<br>
    * After calling this method DVS to VM NIC's mapping will look like...<br>
    * PG1:Port1=VM-1:nic1<br>
    * PG1:Port2=VM-1:nic2 <br>
    * ---- <br>
    * PG2:Port3=VM-2:nic1<br>
    * PG2:Port4=VM-2:nic2<br>
    * <br>
    */
   public void setupVMs(final ManagedObjectReference aDvsMor)
      throws Exception
   {
      final DistributedVirtualSwitchHostMember[] hostMember;
      final ManagedObjectReference dvsHostMor;
      final Vector<ManagedObjectReference> hostVms;
      hostMember = com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(aDvsMor).getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
      assertNotEmpty(hostMember, "No hosts connected to DVS");
      dvsHostMor = hostMember[0].getConfig().getHost();
      hostVms = hs.getAllVirtualMachine(dvsHostMor);
      Assert.assertNotEmpty(hostVms, MessageConstants.VM_GET_FAIL);
      Assert.assertTrue(hostVms.size() >= portGroups.size(),
               "Less number of VM's found than number of PG's");
      log.info("Got '{}' VM's in host {}", hostVms.size(), hostMor);
      // FIXME wait for tools?
      assertTrue(vm.powerOnVMs(hostVms, false),
               MessageConstants.VM_POWERON_FAIL);
      final Iterator<String> iter = portGroups.keySet().iterator();
      int count = 0;
      while (iter.hasNext()) {
         final String pgKey = iter.next();
         final DistributedVirtualSwitchPortConnection[] conns;
         final VirtualMachineConfigSpec[] vmCfgs;
         final List<String> ports = portGroups.get(pgKey);// get the first
         log.info("Ports: {}", ports);
         final ManagedObjectReference aVmMor = hostVms.get(count);
         conns = new DistributedVirtualSwitchPortConnection[ports.size()];
         for (int j = 0; j < ports.size(); j++) {
            conns[j] = new DistributedVirtualSwitchPortConnection();
            conns[j].setPortKey(ports.get(j));
            conns[j].setPortgroupKey(pgKey);
            conns[j].setSwitchUuid(dvsCfgInfo.getUuid());
         }
         log.debug("Created {} DVPort Connections.", conns.length);
         vmCfgs = DVSUtil.getVMConfigSpecForDVSPort(aVmMor, connectAnchor,
                  conns);
         assertNotEmpty(vmCfgs, "Failed to get Recfg spec for VM " + aVmMor);
         log.debug("Reconfiguring the VM to connect to DVS...");
         assertTrue(vm.reconfigVM(aVmMor, vmCfgs[0]), "Failed to reconfig VM");
         log.debug("Reconfigured VM '{}' to use DVS.", aVmMor);
         vms.put(aVmMor, vmCfgs[1]);
         count++;
      }
   }

   /**
    * Restore the VMs to previous network Config.<br>
    */
   public boolean cleanupVMs()
   {
      boolean result = true;
      for (int i = 0; i < vms.size(); i++) {
         final Iterator<ManagedObjectReference> specs = vms.keySet().iterator();
         while (specs.hasNext()) {
            try {
               final ManagedObjectReference aVmMor = specs.next();
               log.info("Restoring '{}' to original Cfg.", aVmMor);
               result &= vm.reconfigVM(aVmMor, vms.get(aVmMor));
               // FIXME kiri uncomment this later.
               // result &= vm.setVMState(aVmMor, poweredOff, false);
            } catch (final Exception e) {
               log.error("Failed to restore VM to original Cfg", e);
               result = false;
            }
         }
      }
      return result;
   }

   /**
    * FIXME:<br>
    * Mainly builds a valid source VSPAN port. source cannot have it's
    * uplinkPortName set. kiri<br>
    * This method gets the first available values in the portgroups map to
    * construct a valid source VSPAN port.<br>
    * Using the given maps get the portkey,portgroupKey and construct the
    * VMwareVspanPort object & remove them once used.
    *
    * @see per bug #592282#c11 uplink port cannot be in source ports.
    * @param portGroups DVPortgroups to choose from.
    * @return VMwareVspanPort VSPAN port.
    */
   private VMwareVspanPort buildVspanPort(final MultiMap<String, String> portGroups)
   {
      assertNotNull(portGroups, "Null portGroups");
      log.debug("Available portgroups: {}", portGroups);
      //
      final Map<String, List<String>> apg = VspanHelper.popPortgroup(portGroups);
      final String portgroupKey = apg.keySet().iterator().next();
      final String portKey = apg.get(portgroupKey).get(0);
      return VspanHelper.buildVspanPort(portKey, null, null);
   }

   /**
    * Method to generate the combinations and give array of the
    * VMwareDVSVspanConfigSpec. The sourceTx and sourceRx will be interpolated
    * using the existing values. <br>
    * TODO rename to generate Cfgs<br>
    *
    * @param destinationPort destinationPort to use.
    * @param dvsMor MOR of the DVS.
    * @return VMwareDVSVspanConfigSpecs
    */
   public VMwareDVSVspanConfigSpec[] buildVspanCfgs(final VMwareVspanPort destinationPort,
                                                    final ManagedObjectReference dvsMor)
   {
      final List<VMwareDVSVspanConfigSpec> vspanCfgs;
      int key = 1;// used for name generation of vspan config.
      String vspanName = null;// This key is a combination.
      VMwareVspanSession vspanSession = null;
      VMwareVspanPort[] sourceTx = null;// contains 4
      VMwareVspanPort[] sourceRx = null; // contains 4
      // use the available PG & Port.
      log.debug("Building VMwareVspanPort for sourceTx");
      sourceTx = VspanHelper.buildVspanPorts(buildVspanPort(portGroups));
      log.debug("Building VMwareVspanPort for sourceRx");
      sourceRx = VspanHelper.buildVspanPorts(buildVspanPort(portGroups));
      vspanCfgs = new ArrayList<VMwareDVSVspanConfigSpec>();
      for (int i = 0; i < sourceTx.length; i++) {
         for (int j = 0; j < sourceRx.length; j++) {
            vspanName = getTestId() + "-" + FORMATTER.format(key);
            sourceTx[i].getWildcardPortConnecteeType().clear();
            sourceTx[i].getWildcardPortConnecteeType().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(srcTxWc));
            sourceRx[j].getWildcardPortConnecteeType().clear();
            sourceRx[j].getWildcardPortConnecteeType().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(srcRxWc));
            vspanSession = VspanHelper.buildVspanSession(vspanName,
                     sourceTx[i], sourceRx[j], destinationPort);
            vspanSession.setEncapsulationVlanId(encapsulationVlanId);
            vspanSession.setEnabled(enabled);
            vspanSession.setMirroredPacketLength(mirrorPacketLength);
            vspanSession.setNormalTrafficAllowed(normalTrafficAllowed);
            vspanSession.setStripOriginalVlan(stripOriginalVlan);
            vspanCfgs.add(VspanHelper.buildVspanCfg(vspanSession,
                     TestConstants.CONFIG_SPEC_ADD));// add it to the list.
            key++;
         }
      }
      log.info("Built " + vspanCfgs.size() + " VSPAN config specs.");
      for (final VMwareDVSVspanConfigSpec aVspanCfg : vspanCfgs) {
         final VMwareVspanSession aSession = aVspanCfg.getVspanSession();
         log.info(VspanHelper.toString(aSession));
      }
      return vspanCfgs.toArray(new VMwareDVSVspanConfigSpec[vspanCfgs.size()]);
   }

   /**
    * Destroy given DVS.<br>
    *
    * @param mor MOR of the entity to be destroyed.
    * @return boolean true, if destroyed.
    */
   boolean destroy(final ManagedObjectReference mor)
   {
      boolean status = false;
      if (mor != null) {
         try {
            status = vmwareDvs.destroy(mor);
         } catch (final Exception e) {
            log.error("Failed to destroy the DVS", e);
         }
      } else {
         log.info("Given MOR is null");
         status = true;
      }
      return status;
   }

   /**
    * Method to reconfigure the VSPAN session on given DVS<br>
    *
    * @param dvsMor ManagedObjectReference object
    * @param vspanCfg VMwareDVSVspanConfigSpec object
    * @return boolean true if successful false otherwise
    * @throws MethodFault, Exception
    */
   boolean reconfigureVspan(final ManagedObjectReference dvsMor,
                            final VMwareDVSVspanConfigSpec[] vspanCfg)
      throws Exception
   {
      boolean verify = false;
      ManagedObjectReference hostMor = null;
      log.info("Reconfiguring VSPAN session of DVS: {} ", dvsName);
      final VMwareDVSConfigInfo info = vmwareDvs.getConfig(dvsMor);
      VMwareVspanSession[] sessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(info.getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
      final VMwareDVSConfigSpec vmwareDvsCfg = new VMwareDVSConfigSpec();
      vmwareDvsCfg.setConfigVersion(info.getConfigVersion());
      vmwareDvsCfg.getVspanConfigSpec().clear();
      vmwareDvsCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      String vdsVersion = DVSUtil.getvDsVersion();
      if(vdsVersion == null){
         vdsVersion = DVSTestConstants.VDS_VERSION_DEFAULT;
      }
      int version = Integer.valueOf(TestUtil.stripString(vdsVersion,"\\."));
      assertTrue(vmwareDvs.reconfigure(dvsMor, vmwareDvsCfg),
               "Failed to reconfigure VSPAN session");
      log.info("Reconfigured VSPAN successfully.");
      log.info("Get current config & compute expected config...");
      final List<VMwareVspanSession> expected = vmwareDvs.mergeVspansCfgs(
               sessions, vspanCfg);
      // now get the current config.
      sessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
      verify = vmwareDvs.verifyVspan(
               (sessions == null ? null : Arrays.asList(sessions)), expected);
      DistributedVirtualSwitchHostMember[] hostMembers = com.vmware.vcqa.util.TestUtil.vectorToArray(info.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
      if (sessions != null && hostMembers != null && hostMembers.length > 0) {
         for (DistributedVirtualSwitchHostMember hostMember : hostMembers) {
            hostMor = hostMember.getConfig().getHost();
            if (hostMor != null) {
               VMwareVspanSession[] vmwareVspanSessionsOnVds = com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.
                     	   getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class);
               if(version <= 500){
                  verify &= InternalDVSHelper.verifyVspanSessionOnHost(
                           connectAnchor, hostMor, info.getUuid(),
                           vmwareVspanSessionsOnVds);
               } else {
                  /*
                   * For 5.1 version vds or greater, the vspan session is on the
                   * port and verification needs to be altered.
                   */
                  List<String> portKeys = VspanHelper.
                		  getPortKeysFromVspanSession(vmwareVspanSessionsOnVds);
                  verify &= InternalDVSHelper.verifyVspanSessionOnPorts(
                          connectAnchor, hostMor,info.getUuid(),
                          vmwareVspanSessionsOnVds,
                          portKeys);
                  if(verify){
                	  log.info("The verify value  :  ---------------------------------------------> " + verify);
                  }
               }

            } else {
               log.warn("hostMor is null on " +
               		"DistributedVirtualSwitchHostMember config. Skipping " +
               		"VMwareVspanSession verfication host");
            }
         }

      } else {
         log.warn("VMwareVspanSession or DistributedVirtualSwitchHostMember is null on VC. Skipping VMwareVspanSession verfication host");
      }
      return verify;
   }

   /**
    * Method to reconfigure the VSPAN session on given DVS incrementally.<br>
    *
    * @param dvsMor ManagedObjectReference object
    * @param vspanCfg VMwareDVSVspanConfigSpec object
    * @return boolean true if successful false otherwise
    * @throws MethodFault, Exception
    */
   boolean addVspanAndDelete(final ManagedObjectReference dvsMor,
                             final VMwareDVSVspanConfigSpec[] vspanCfg)
      throws Exception
   {
      boolean result = true;
      log.info("Reconfiguring VSPAN session of DVS: {} ", dvsName);
      for (int i = 0; i < vspanCfg.length; i++) {
         final VMwareDVSConfigInfo info = vmwareDvs.getConfig(dvsMor);
         VMwareVspanSession[] sessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(info.getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
         final VMwareDVSVspanConfigSpec aCfg = vspanCfg[i];
         final VMwareDVSConfigSpec reCfg = new VMwareDVSConfigSpec();
         reCfg.setConfigVersion(vmwareDvs.getConfigVersion(dvsMor));
         reCfg.getVspanConfigSpec().clear();
         reCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new VMwareDVSVspanConfigSpec[] { aCfg }));
         log.info("Session: {}: {} ", i + 1,
                  VspanHelper.toString(aCfg.getVspanSession()));
         try {
            result &= vmwareDvs.reconfigure(dvsMor, reCfg);
            log.info("Get current config & compute expected config...");
            final List<VMwareVspanSession> expected = vmwareDvs.mergeVspansCfgs(
                     sessions, com.vmware.vcqa.util.TestUtil.vectorToArray(reCfg.getVspanConfigSpec(), com.vmware.vc.VMwareDVSVspanConfigSpec.class));
            // now get the current config.
            sessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
            result &= vmwareDvs.verifyVspan(Arrays.asList(sessions), expected);
            VMwareDVSVspanConfigSpec[] recfgSpec = null;
            recfgSpec = new VMwareDVSVspanConfigSpec[sessions.length];
            for (int j = 0; j < sessions.length; j++) {
               final VMwareVspanSession aSession = sessions[j];
               log.info("Removing VSPAN: {}", VspanHelper.toString(aSession));
               recfgSpec[j] = VspanHelper.buildVspanCfg(aSession,
                        CONFIG_SPEC_REMOVE);
            }
            assertTrue(reconfigureVspan(dvsMor, recfgSpec),
                     "Failed to remove the VSPAN session");
            log.info("Reconfigured VSPAN successfully.");
         } catch (final Exception e) {
            log.error("Failed to reconfigure VSPAN.", e);
            result = false;
         }
      }
      return result;
   }

   /**
    * Method to reconfigure the VSPAN session on given DVS incrementally.<br>
    *
    * @param dvsMor ManagedObjectReference object
    * @param vspanCfg VMwareDVSVspanConfigSpec object
    * @return boolean true if successful false otherwise
    * @throws MethodFault, Exception
    */
   boolean reconfigureVspanIncrementally(final ManagedObjectReference dvsMor,
                                         final VMwareDVSVspanConfigSpec[] vspanCfg)
      throws Exception
   {
      boolean result = true;
      log.info("Reconfiguring VSPAN session of DVS: {} ", dvsName);
      final VMwareDVSConfigInfo info = vmwareDvs.getConfig(dvsMor);
      VMwareVspanSession[] sessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(info.getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
      for (int i = 0; i < vspanCfg.length; i++) {
         final VMwareDVSVspanConfigSpec aCfg = vspanCfg[i];
         final VMwareDVSConfigSpec reCfg = new VMwareDVSConfigSpec();
         reCfg.setConfigVersion(vmwareDvs.getConfigVersion(dvsMor));
         reCfg.getVspanConfigSpec().clear();
         reCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new VMwareDVSVspanConfigSpec[] { aCfg }));
         log.info("Session: {}: {} ", i + 1,
                  VspanHelper.toString(aCfg.getVspanSession()));
         try {
            result &= vmwareDvs.reconfigure(dvsMor, reCfg);
         } catch (final Exception e) {
            log.error("Failed to reconfigure VSPAN.", e);
            result = false;
         }
         log.info("Get current config & compute expected config...");
         final List<VMwareVspanSession> expected = vmwareDvs.mergeVspansCfgs(
                  sessions, com.vmware.vcqa.util.TestUtil.vectorToArray(reCfg.getVspanConfigSpec(), com.vmware.vc.VMwareDVSVspanConfigSpec.class));
         // now get the current config.
         sessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
         result &= vmwareDvs.verifyVspan(Arrays.asList(sessions), expected);
      }
      return result;
   }
}

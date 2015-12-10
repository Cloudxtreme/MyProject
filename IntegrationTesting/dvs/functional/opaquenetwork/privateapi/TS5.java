package dvs.functional.opaquenetwork.privateapi;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.Assert.assertNotNull;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.BoolPolicy;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostDVSPortData;
import com.vmware.vc.HostDVSPortDeleteSpec;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostOpaqueSwitch;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.StringPolicy;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkLacpPolicy;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.TestConstants;

public class TS5 extends PrivateApiBase
{
   String opaqueDvsUuid = null;
   ArrayList<Integer> dvPorts = null;
   ArrayList<String> vnic_ids = null;
   ArrayList<String> vnic_keys = null;
   int dvpId;
   String dvPortKey = null;
   final String user = TestConstants.ESX_USERNAME;
   final String passwd = TestConstants.ESX_PASSWORD;
   final String env_opaque_uplink = "OPAQUE_NETWORK_UPLINK";
   final String nsax_path = "http://vmweb.vmware.com/~netfvt/nsxa/files.txt";
   String opaque_uplink = "vmnic1";
   final String SWITCH_VTEP_PROPERTY_NAME = "__vtep__";
   int num_of_vteps = 5;
   HostOpaqueSwitch hostOpaqueSwitch = null;
   public HostOpaqueSwitch queryOpaqueDvs()
      throws Exception
   {
      
      List<HostOpaqueSwitch> switches = ns.getNetworkInfo(nsMor).getOpaqueSwitch();
      for (HostOpaqueSwitch opaqueSwitch : switches) {
         if (opaqueSwitch.getKey().equalsIgnoreCase(opaqueDvsUuid)) {
            hostOpaqueSwitch = opaqueSwitch;
            break;
         }
      }
      assertNotNull(hostOpaqueSwitch, "Failed to find opaque dvs with key "
               + opaqueDvsUuid);
      log.info("vmklist:" + hostOpaqueSwitch.getVtep());
      return hostOpaqueSwitch;
   }

   public void getDvPort()
   {
      while (true) {
         dvpId = (int) System.currentTimeMillis() / 1000;
         if (dvpId < 0) {
            dvpId = Integer.MAX_VALUE + dvpId;
         }
         if (dvPorts.contains(dvpId) == false) {
            dvPorts.add(dvpId);
            break;
         }
      }
      dvPortKey = Integer.toString(dvpId);
   }

   public String addVtepVirtualNic()
      throws Exception
   {
      getDvPort();
      BoolPolicy lacpEnable = new BoolPolicy();
      lacpEnable.setInherited(false);
      lacpEnable.setValue(true);
      StringPolicy lacpMode = new StringPolicy();
      lacpMode.setInherited(false);
      lacpMode.setValue("active");
      VMwareUplinkLacpPolicy newLacpPolicy = new VMwareUplinkLacpPolicy();
      newLacpPolicy.setEnable(lacpEnable);
      newLacpPolicy.setMode(lacpMode);

      VMwareDVSPortSetting portSetting = new VMwareDVSPortSetting();
      portSetting.setLacpPolicy(newLacpPolicy);
      HostDVSPortData portData = new HostDVSPortData();
      portData.setPortKey(dvPortKey);
      portData.setConnectionCookie(dvpId);
      portData.setSetting(portSetting);
      log.info("Push dvPort [" + dvPortKey + "] to the host");
      ArrayList<HostDVSPortData> portDatas = new ArrayList<HostDVSPortData>();
      portDatas.add(portData);
      hdvsManager.applyDVPort(hostDVSMgrMor, opaqueDvsUuid, portDatas);

      // Create vmknic spec and invoke updateNetworkConfig
      HostIpConfig ipConf = new HostIpConfig();
      ipConf.setDhcp(true);
      DistributedVirtualSwitchPortConnection portConn = new DistributedVirtualSwitchPortConnection();
      portConn.setSwitchUuid(opaqueDvsUuid);
      portConn.setPortKey(dvPortKey);
      portConn.setConnectionCookie(dvpId);
      HostVirtualNicSpec spec = new HostVirtualNicSpec();
      spec.setIp(ipConf);
      spec.setDistributedVirtualPort(portConn);
      String vnic_id = ns.addVirtualNic(nsMor, "", spec);
      verifyVtepVirtualNic(vnic_id, true);
      return vnic_id;
   }

   public HostVirtualNicSpec getVtepSpec(String vnic_id)
      throws Exception
   {
      HostVirtualNicSpec spec = null;
      HostOpaqueSwitch opaqueDvs = null;
      opaqueDvs = queryOpaqueDvs();
      List<HostVirtualNic> vteps = opaqueDvs.getVtep();
      for (HostVirtualNic vtep : vteps) {
         if (vtep.getDevice().equals(vnic_id)) {
            spec = vtep.getSpec();
            break;
         }
      }
      assertNotNull(spec, "Failed to get vtep step for " + vnic_id);
      return spec;
   }

   public void updateVtepVirtualNic(String vnic_id)
      throws Exception
   {
      HostVirtualNicSpec spec = getVtepSpec(vnic_id);
      spec.setMtu(9000);
      spec.setMac("00:50:56:63:66:68");
      HostIpConfig ipConf = new HostIpConfig();
      ipConf.setDhcp(false);
      ipConf.setIpAddress("192.168.168.166");
      ipConf.setSubnetMask("255.255.0.0");
      spec.setIp(ipConf);
      assertTrue(ns.updateVirtualNic(nsMor, vnic_id, spec, false),
               "Succeeded to update virtual nic",
               "Failed to update virtual nic");

   }

   public void removeVtepVirtualNic(String vnic_id)
      throws Exception
   {
      String dvPortKey = null;
      HostOpaqueSwitch opaqueDvs = null;
      opaqueDvs = queryOpaqueDvs();
      List<HostVirtualNic> vteps = opaqueDvs.getVtep();
      for (HostVirtualNic vtep : vteps) {
         if (vtep.getDevice().equals(vnic_id)) {
            DistributedVirtualSwitchPortConnection dvPort = vtep.getSpec().getDistributedVirtualPort();
            assertTrue(dvPort != null, "dvPort fof vtep is null");
            assertTrue(dvPort.getSwitchUuid().equals(opaqueDvsUuid),
                     "switch uuids are not the same");
            dvPortKey = dvPort.getPortKey();
            break;
         }
      }
      assertNotNull(dvPortKey, "VTEP " + vnic_id + " is not present");
      log.info("Removing " + vnic_id);
      ns.removeVirtualNic(nsMor, vnic_id);
      verifyVtepVirtualNic(vnic_id, false);

      HostDVSPortDeleteSpec delSpec = new HostDVSPortDeleteSpec();
      delSpec.setPortKey(dvPortKey);
      delSpec.setDeletePortFile(true);
      HostDVSPortDeleteSpec[] portDeleteSpecArray = { delSpec };
      assertTrue(hdvsManager.deletePorts(hostDVSMgrMor, opaqueDvsUuid,
               portDeleteSpecArray), "Succeeded to delete dvport " + dvPortKey,
               "Failed to delete dvport " + dvPortKey);
   }

   public void verifyVtepVirtualNic(String vnic_id,
                                    boolean need_found)
      throws Exception
   {
      boolean found = false;
      HostOpaqueSwitch opaqueDvs = null;
      opaqueDvs = queryOpaqueDvs();
      List<HostVirtualNic> vteps = opaqueDvs.getVtep();
      for (HostVirtualNic vtep : vteps) {

         if (vtep.getDevice().equals(vnic_id)) {
            found = true;
            break;
         }
      }
      assertTrue(found == need_found,
               "Failed to verify dynamic properties for VTEP ");
   }

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      vnic_ids = new ArrayList<String>();
      vnic_keys = new ArrayList<String>();
      dvPorts = new ArrayList<Integer>();
      if (System.getenv(env_opaque_uplink) != null) {
         opaque_uplink = System.getenv(env_opaque_uplink);
      }
      // start nsxa simulator
      assertTrue(DVSUtil.startNsxa(connectAnchor, user, passwd, opaque_uplink,
               hostMor, nsax_path), "Succeeded to start nsxa simulator",
               "Failed to start nsxa simulator");
      List<HostOpaqueSwitch> switches = ns.getNetworkInfo(nsMor).getOpaqueSwitch();
      assertTrue((switches != null && switches.size() > 0),
               "Please ensure host has opaque dvs");
      opaqueDvsUuid = switches.get(0).getKey();
      return true;
   }

   @Test
   public void test()
      throws Exception
   {
      for (int i = 0; i < num_of_vteps; i++) {
         String vnic_id = addVtepVirtualNic();
         vnic_ids.add(vnic_id);
      }

      updateVtepVirtualNic(vnic_ids.get(vnic_ids.size() - 1));
      Iterator<String> iter = vnic_ids.iterator();
      
      while (iter.hasNext()) {
         String vnic_id = iter.next();
         log.info("vmklist2:" + hostOpaqueSwitch.getVtep());
         removeVtepVirtualNic(vnic_id);
         iter.remove();
      }
      
   }

   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
      if (vnic_ids != null && vnic_ids.isEmpty() == false) {
         Iterator<String> iter = vnic_ids.iterator();
         while (iter.hasNext()) {
            String vnic_id = iter.next();
            removeVtepVirtualNic(vnic_id);
            iter.remove();
         }
      }
      DVSUtil.stopNsxa(connectAnchor, user, passwd);
      return true;
   }
}

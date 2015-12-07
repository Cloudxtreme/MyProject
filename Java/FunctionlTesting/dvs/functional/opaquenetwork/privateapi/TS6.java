package dvs.functional.opaquenetwork.privateapi;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.HostOpaqueSwitch;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicOpaqueNetworkSpec;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.TestConstants;

public class TS6 extends PrivateApiBase
{
   ArrayList<String> vnic_ids = null;
   ArrayList<String> vnic_keys = null;
   List<HostOpaqueNetworkInfo> opaqueNetworks = null;
   List<String> key_pnics = null;
   ArrayList<String> pnics = null;
   final String user = TestConstants.ESX_USERNAME;
   final String passwd = TestConstants.ESX_PASSWORD;
   final String env_opaque_uplink = "OPAQUE_NETWORK_UPLINK";
   final String nsax_path = "http://vmweb.vmware.com/~netfvt/nsxa/files.txt";
   String opaque_uplink = "vmnic1,vmnic2";

   public void addVirtuakNic()
      throws Exception
   {
      String vnic_id = null;

      HostIpConfig ipConf = new HostIpConfig();
      ipConf.setDhcp(true);

      // create vmknic on first opaque network (without pinnedPnic)
      HostVirtualNicOpaqueNetworkSpec opaqueNetworkSpec1 = new HostVirtualNicOpaqueNetworkSpec();
      opaqueNetworkSpec1.setOpaqueNetworkId(opaqueNetworks.get(0).getOpaqueNetworkId());
      opaqueNetworkSpec1.setOpaqueNetworkType(opaqueNetworks.get(0).getOpaqueNetworkType());
      HostVirtualNicSpec spec1 = new HostVirtualNicSpec();
      spec1.setIp(ipConf);
      spec1.setOpaqueNetwork(opaqueNetworkSpec1);
      vnic_id = ns.addVirtualNic(nsMor, "", spec1);
      vnic_ids.add(vnic_id);
      assertTrue(
               verifyPinnedPnic(opaqueNetworks.get(0).getOpaqueNetworkId(),
                        vnic_id, null),
               "Succeeded to verify pinned pnic property for " + vnic_id,
               "Failed to verify pinned pnic property for " + vnic_id);

      // create another vmknic on second opaque network with a pinnedPnic
      HostVirtualNicOpaqueNetworkSpec opaqueNetworkSpec2 = new HostVirtualNicOpaqueNetworkSpec();
      opaqueNetworkSpec2.setOpaqueNetworkId(opaqueNetworks.get(1).getOpaqueNetworkId());
      opaqueNetworkSpec2.setOpaqueNetworkType(opaqueNetworks.get(1).getOpaqueNetworkType());
      HostVirtualNicSpec spec2 = new HostVirtualNicSpec();
      spec2.setIp(ipConf);
      spec2.setOpaqueNetwork(opaqueNetworkSpec2);
      spec2.setPinnedPnic(pnics.get(1));
      vnic_id = ns.addVirtualNic(nsMor, "", spec2);
      vnic_ids.add(vnic_id);
      assertTrue(
               verifyPinnedPnic(opaqueNetworks.get(1).getOpaqueNetworkId(),
                        vnic_id, pnics.get(1)),
               "Succeeded to verify pinned pnic property for " + vnic_id,
               "Failed to verify pinned pnic property for " + vnic_id);
   }

   public void updateVirtuakNic()
      throws Exception
   {
      String vnic_id = null;

      // update vmknic1: opaque-network-1 to pin it to pnic1
      vnic_id = vnic_ids.get(0);
      HostVirtualNicSpec spec1 = new HostVirtualNicSpec();
      String pnic = pnics.get(1);
      spec1.setPinnedPnic(pnic);
      assertTrue(ns.updateVirtualNic(nsMor, vnic_id, spec1, false),
               "Succeeded to update virtual nic " + vnic_id,
               "Failed to update virtual nic " + vnic_id);
      assertTrue(
               verifyPinnedPnic(opaqueNetworks.get(0).getOpaqueNetworkId(),
                        vnic_id, pnic),
               "Succeeded to verify pinned pnic property for " + vnic_id,
               "Failed to verify pinned pnic property for " + vnic_id);

      // update vmknic1: opaque-network-1 to opaque-network-2
      HostVirtualNicOpaqueNetworkSpec opaqueNetworkSpec1 = new HostVirtualNicOpaqueNetworkSpec();
      opaqueNetworkSpec1.setOpaqueNetworkId(opaqueNetworks.get(1).getOpaqueNetworkId());
      opaqueNetworkSpec1.setOpaqueNetworkType(opaqueNetworks.get(1).getOpaqueNetworkType());
      HostVirtualNicSpec spec2 = new HostVirtualNicSpec();
      spec2.setOpaqueNetwork(opaqueNetworkSpec1);
      assertTrue(ns.updateVirtualNic(nsMor, vnic_id, spec2, false),
               "Succeeded to update virtual nic " + vnic_id,
               "Failed to update virtual nic " + vnic_id);
      assertTrue(
               verifyPinnedPnic(opaqueNetworks.get(1).getOpaqueNetworkId(),
                        vnic_id, null),
               "Succeeded to verify pinned pnic property for " + vnic_id,
               "Failed to verify pinned pnic property for " + vnic_id);

      // update vmknic2: opaque-network-2 to opaque-network-1 with pinnedPnic
      vnic_id = vnic_ids.get(1);
      HostVirtualNicOpaqueNetworkSpec opaqueNetworkSpec2 = new HostVirtualNicOpaqueNetworkSpec();
      opaqueNetworkSpec2.setOpaqueNetworkId(opaqueNetworks.get(0).getOpaqueNetworkId());
      opaqueNetworkSpec2.setOpaqueNetworkType(opaqueNetworks.get(0).getOpaqueNetworkType());
      HostVirtualNicSpec spec3 = new HostVirtualNicSpec();
      pnic = pnics.get(0);
      spec3.setPinnedPnic(pnic);
      spec3.setOpaqueNetwork(opaqueNetworkSpec2);
      assertTrue(ns.updateVirtualNic(nsMor, vnic_id, spec3, false),
               "Succeeded to update virtual nic " + vnic_id,
               "Failed to update virtual nic " + vnic_id);
      assertTrue(
               verifyPinnedPnic(opaqueNetworks.get(0).getOpaqueNetworkId(),
                        vnic_id, pnic),
               "Succeeded to verify pinned pnic property for " + vnic_id,
               "Failed to verify pinned pnic property for " + vnic_id);

   }

   public void removeVtepVirtualNic(String vnic_id)
      throws Exception
   {
      log.info("Removing vmknic " + vnic_id);
      ns.removeVirtualNic(nsMor, vnic_id);
   }

   public boolean verifyPinnedPnic(String opaqueNetworkId,
                                   String vnic_id,
                                   String pinnedPnic)
      throws Exception
   {
      HostVirtualNic virtualNic = null;
      ns.refresh(nsMor);
      List<HostVirtualNic> hostVirtualNics = ns.getVirtualNicFromOpaqueNetwork(
               nsMor, opaqueNetworkId);
      for (HostVirtualNic hostVirtualNic : hostVirtualNics) {
         if (hostVirtualNic.getDevice().equals(vnic_id)) {
            virtualNic = hostVirtualNic;
            break;
         }
      }
      assertTrue(virtualNic != null, "Failed to find vmknic " + vnic_id
               + " connecting to opaque network");
      HostVirtualNicSpec spec = virtualNic.getSpec();
      String actual_pinnedPnic = spec.getPinnedPnic();
      if (pinnedPnic == null) {
         if (actual_pinnedPnic != null) {
            log.error("Expected pinned pnic is null, actual pinned pnic is "
                     + actual_pinnedPnic);
            return false;
         }
      } else {
         if (actual_pinnedPnic == null) {
            log.error("Expected pinned pnic is " + pinnedPnic
                     + ", actual pinned pnic is null");
            return false;
         } else {
            if (pinnedPnic.equals(actual_pinnedPnic) == false) {
               log.error("Expected pinned pnic is " + pinnedPnic
                        + ", actual pinned pnic is " + actual_pinnedPnic);
               return false;
            }
         }
      }
      return true;
   }

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      if (System.getenv(env_opaque_uplink) != null) {
         opaque_uplink = System.getenv(env_opaque_uplink);
      }
      vnic_ids = new ArrayList<String>();
      vnic_keys = new ArrayList<String>();
      pnics = new ArrayList<String>();

      return true;
   }

   @Test
   public void test()
      throws Exception
   {
      // start nsxa simulator
      assertTrue(DVSUtil.startNsxa(connectAnchor, user, passwd, opaque_uplink,
               hostMor, nsax_path), "Succeeded to start nsxa simulator",
               "Failed to start nsxa simulator");
      opaqueNetworks = ns.getNetworkInfo(nsMor).getOpaqueNetwork();
      assertTrue((opaqueNetworks != null && opaqueNetworks.size() >= 2),
               "Please ensure host has at least 2 opaque networks");
      List<HostOpaqueSwitch> opaqueSwitches = ns.getNetworkInfo(nsMor).getOpaqueSwitch();
      assertTrue((opaqueSwitches != null && opaqueSwitches.size() > 0),
               "Please ensure host has at least an opaque switch");
      key_pnics = opaqueSwitches.get(0).getPnic();
      assertTrue((key_pnics != null && key_pnics.size() >= 2),
               "Please ensure opaque switch has at least 2 pnics");
      for (String key_pnic : key_pnics) {
         String[] pnic_parts = key_pnic.split("-");
         pnics.add(pnic_parts[2]);
      }

      addVirtuakNic();
      updateVirtuakNic();
      Iterator<String> iter = vnic_ids.iterator();
      while (iter.hasNext()) {
         String vnic_id = iter.next();
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

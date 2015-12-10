/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.DVS_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.DVS_CREATE_PASS;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.PhysicalNic;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * DESCRIPTION:<BR>
 * (VC cleans up connected port when pnic is snatched by another DVS) <BR>
 * TARGET: VC <BR>
 * NOTE : PR#625673 <BR>
 * SETUP:<BR>
 * 1. Get one connected host with one free pnic TEST:<BR>
 * TEST:<BR>
 * 2. Create a dvs1 with host by adding one pnic (vmnic1) <BR>
 * 3. Create a dvs2 with host by adding same pnic( vmnic1)<BR>
 * 4. Verify that pnic is connected only to dvs2 using ProxySwitch, VC's
 * dvsconfig and dvport's connectee info <BR>
 * CLEANUP:<BR>
 * 5. Destroy dvs1 and dvs2<BR>
 */

public class Pos062 extends TestBase
{
   private HostSystem hostSystem = null;
   private DistributedVirtualSwitch DVS = null;
   private DistributedVirtualPortgroup dvpg = null;
   private NetworkSystem ns = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference dvsMor = null;
   private ManagedObjectReference nsMor = null;
   private ManagedObjectReference dvsMor1 = null;
   private String[] freePnics = null;
   private String hostName = null;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      this.DVS = new DistributedVirtualSwitch(connectAnchor);
      this.dvpg = new DistributedVirtualPortgroup(connectAnchor);
      this.hostSystem = new HostSystem(connectAnchor);
      this.ns = new NetworkSystem(connectAnchor);
      hostMor = this.hostSystem.getConnectedHost(false);
      hostName = this.hostSystem.getHostName(hostMor);
      freePnics = ns.getPNicIds(hostMor);
      assertTrue(freePnics != null && freePnics.length > 0,
               " Successfully obtained free pnic on host :" + hostName,
               "Failed to get free pnics on host : " + hostName);
      nsMor = this.ns.getNetworkSystem(hostMor);
      return true;
   }

   /*
    * (non-Javadoc)
    *
    * @see com.vmware.vcqa.TestBase#test()
    */
   @Override
   @Test(description = " 1. Create a dvs1 with host 1 with the free pnic\n"
            + "2. Create a dvs2 with host 1 with the same free pnic \n"
            + "3.Verify that pnic is connected only to dvs2 using ProxySwitch, VC's dvsconfig and dvport's connectee info \n")
   public void test()
      throws Exception
   {
      List<String> keys = null;
      List<ManagedObjectReference> uplinkPGMorList = null;
      Map<String, DistributedVirtualPort> connectedEntitiespMap = null;
      final Map<ManagedObjectReference, String> pNicMap =
               new HashMap<ManagedObjectReference, String>();
      Map<ManagedObjectReference, List<String>> mapPnicsAndHost = null;
      pNicMap.put(this.hostMor, freePnics[0]);
      this.dvsMor =
               DVSUtil.createDVSFromCreateSpec(connectAnchor, DVSUtil
                        .createDVSCreateSpec(DVSUtil
                                 .addHostsToDVSConfigSpecWithPnic(null,
                                          pNicMap, null), null, null));

      assertNotNull(dvsMor, DVS_CREATE_PASS + this.DVS.getName(dvsMor),
               DVS_CREATE_FAIL);

      assertTrue(DVSUtil.removeAllUplinks(connectAnchor, this.hostMor,
               this.dvsMor), "Successfully removed all vmnics from vDs ",
               "Failed to remove all vmnics from vDs ");

      this.dvsMor1 =
               DVSUtil.createDVSFromCreateSpec(connectAnchor, DVSUtil
                        .createDVSCreateSpec(DVSUtil
                                 .addHostsToDVSConfigSpecWithPnic(null,
                                          pNicMap, null), null, null));

      assertNotNull(dvsMor1, DVS_CREATE_PASS + this.DVS.getName(dvsMor1),
               DVS_CREATE_FAIL);

      List<String> pnics =
               DVSUtil
                        .getPnicListOnProxySwitch(connectAnchor, hostMor,
                                 dvsMor1);
      List<PhysicalNic> pnicList =
               this.ns.getPhysicalNic(nsMor, pnics.toArray(new String[pnics
                        .size()]));
      assertTrue((pnicList != null && pnicList.size() > 0),
               "Failed to get  PhysicalNic for host : " + this.hostName);
      for (PhysicalNic nic : pnicList) {
         if (nic.getKey().equals(pnics.get(0))) {
            /*
             * Verifying through ProxySwitch
             */

            assertTrue((pnics != null && pnics.size() == 1 && nic.getDevice()
                     .equals(freePnics[0])), "Moved " + freePnics[0] + " to "
                     + this.DVS.getName(dvsMor1), "Failed to move  "
                     + freePnics[0] + " to " + this.DVS.getName(dvsMor1));

            /*
             * Verifying through VC's dvsconfig
             */
            mapPnicsAndHost =
                     DVSUtil
                              .getPnicsConnectedToHost(
                                       connectAnchor,
                                       dvsMor1,
                                       Arrays
                                                .asList(new ManagedObjectReference[] { this.hostMor }));
            assertTrue(mapPnicsAndHost != null
                     && !mapPnicsAndHost.isEmpty()
                     && mapPnicsAndHost.values().size() > 0
                     && mapPnicsAndHost.values().iterator().next().get(0)
                              .equals(freePnics[0]),
                     "Successfully verified that pnic :" + freePnics[0]
                              + " from host :" + this.hostName
                              + " connected to DVS :"
                              + this.DVS.getName(dvsMor1), "Pnic :"
                              + freePnics[0] + " from host :" + this.hostName
                              + " is not connected to DVS :"
                              + this.DVS.getName(dvsMor1));

            uplinkPGMorList = this.DVS.getUplinkPortgroups(dvsMor1);
            assertTrue(uplinkPGMorList != null && uplinkPGMorList.size() == 1,
                     "Failed to get UplinkPortgroups");
            keys = this.dvpg.getPortKeys(uplinkPGMorList.get(0));
            connectedEntitiespMap =
                     DVSUtil.getConnecteeInfo(connectAnchor, dvsMor1, keys);

            /*
             * Verifying through dvport's connectee info
             */
            assertTrue(connectedEntitiespMap != null
                     && !connectedEntitiespMap.isEmpty()
                     && connectedEntitiespMap.values().size() == 1
                     && connectedEntitiespMap.values().iterator().next()
                              .getConnectee().getNicKey().equals(freePnics[0]),
                     "Successfully verified that pnic :"
                              + freePnics[0]
                              + " from host :"
                              + this.hostName
                              + " connected to  :"
                              + this.DVS.getName(dvsMor1)
                              + " to  uplinkportkey :"
                              + connectedEntitiespMap.keySet().iterator()
                                       .next(), "Pnic :" + freePnics[0]
                              + " from host :" + this.hostName
                              + " is not connected to DVS :"
                              + this.DVS.getName(dvsMor1));

            break;
         }
      }

      /*
       * Verifying through ProxySwitch
       */
      pnics = DVSUtil.getPnicListOnProxySwitch(connectAnchor, hostMor, dvsMor);
      assertTrue((pnics == null || !pnics.contains(freePnics[0])), freePnics[0]
               + " is still connected to " + this.DVS.getName(dvsMor));
      /*
       * Verifying through VC's dvsconfig
       */
      mapPnicsAndHost =
               DVSUtil.getPnicsConnectedToHost(connectAnchor, dvsMor, Arrays
                        .asList(new ManagedObjectReference[] { this.hostMor }));
      assertTrue(mapPnicsAndHost == null || mapPnicsAndHost.isEmpty()
               || mapPnicsAndHost.values() == null, "Pnic :"
               + this.freePnics[0] + " from host :" + this.hostName
               + " is not connected to DVS :" + this.DVS.getName(dvsMor),
               "Successfully verified that pnic :" + freePnics[0]
                        + " from host :" + this.hostName
                        + "is not connected to DVS :"
                        + this.DVS.getName(dvsMor));
      uplinkPGMorList = this.DVS.getUplinkPortgroups(dvsMor);
      assertTrue(uplinkPGMorList != null && uplinkPGMorList.size() == 1,
               "Failed to get UplinkPortgroups");
      keys = this.dvpg.getPortKeys(uplinkPGMorList.get(0));
      /*
       * Verifying through dvport's connectee info
       */
      connectedEntitiespMap =
               DVSUtil.getConnecteeInfo(connectAnchor, dvsMor, keys);
      assertTrue(connectedEntitiespMap == null
               || connectedEntitiespMap.isEmpty()
               || connectedEntitiespMap.size() == 0
               || connectedEntitiespMap.values() == null, "Pnic :"
               + freePnics[0] + " from host :" + this.hostName
               + " is not connected to any uplinkportkey on  DVS :"
               + this.DVS.getName(dvsMor), "Successfully verified that pnic :"
               + freePnics[0] + " from host :" + this.hostName
               + " connected to  :" + this.DVS.getName(dvsMor)
               + " to uplinkportkey :");

   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      if (this.dvsMor != null) {
         assertTrue(this.DVS.destroy(this.dvsMor),
                  "Successfully destroyed DVS", "Failed to destroy DVS");
      }
      if (this.dvsMor1 != null) {
         assertTrue(this.DVS.destroy(this.dvsMor1),
                  "Successfully destroyed DVS", "Failed to destroy DVS");

      }
      return true;
   }

}
/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * DESCRIPTION:1)Reconfigure a dvPortgroup to have an nrp associated to it. Set
 * the nrpOverrideAllowed flag to true. Move a standalone dvPort associated with
 * a different nrp into this dvPortgroup.<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1. Create a vDS<BR>
 * 2. Enable netiorm <BR>
 * 3. Add a nrp to it<BR>
 * 4. Create the dv portgroup with the nrp associated with nrpOverrideAllowed
 * flag to true<BR>
 * 5. Add a standalone port with a different nrp associated<BR>
 * TEST:<BR>
 * 6. Move the dvport into the dvpg and verify nrp associated with dvportgroup
 * is attached to the dvport<BR>
 * 7. Move the dvport out of the dvpg and verify nrp associated with dvportgroup
 * is still associated<BR>
 * CLEANUP:<BR>
 * 8. Destroy the dvs<BR>
 */
public class Pos066 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private DistributedVirtualPortgroup dvpg;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool[] nrp;
   private String dvPortgroupKey;
   private String[] dvPortsArr;
   private final int nrpCount = 2;
   private DVPortSetting dvportsetting = null;

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      Folder ifolder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      dvpg = new DistributedVirtualPortgroup(connectAnchor);

      // create the dvs
      dvsMor = ifolder.createDistributedVirtualSwitch(
               DVSTestConstants.DVS_CREATE_NAME_PREFIX + getTestId(),
               DVSUtil.getvDsVersion());
      Assert.assertNotNull(dvsMor, "DVS created", "DVS not created");

      // enable netiorm
      Assert.assertTrue(dvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");

      // Get a default nrp spec
      DVSNetworkResourcePoolConfigSpec[] nrpConfigSpec = new DVSNetworkResourcePoolConfigSpec[nrpCount];
      for (int i = 0; i < nrpConfigSpec.length; i++) {
         nrpConfigSpec[i] = NetworkResourcePoolHelper.createDefaultNrpSpec(getTestId()
                  + i);
      }

      // Add the network resource pool to the dvs
      dvs.addNetworkResourcePool(dvsMor, nrpConfigSpec);

      Assert.assertTrue(NetworkResourcePoolHelper.verifyFromDvs(connectAnchor,
               dvsMor, nrpConfigSpec), "NRP verified from dvs",
               "NRP not matching with DVS nrp");

      nrp = NetworkResourcePoolHelper.extractNrpByName(connectAnchor, dvsMor,
               nrpConfigSpec);
      Assert.assertNotEmpty(nrp, "Nrps added successfully",
               "Nrps could not be added");

      List<String> standaloneDvPorts = dvs.addStandaloneDVPorts(dvsMor, 1);
      Assert.assertNotEmpty(standaloneDvPorts,
               "Standalone port added successfully",
               "Standalone port could not be added");
      dvPortsArr = (String[]) standaloneDvPorts.toArray(new String[standaloneDvPorts.size()]);

      // associate the dvport config spec to the nrp and reconfigure port
      DVPortConfigSpec[] dvportConfigSpec = dvs.getPortConfigSpec(dvsMor,
               dvPortsArr);
      NetworkResourcePoolHelper.associateNrpToDvportSpec(dvportConfigSpec[0],
               nrp[0]);
		for (DVPortConfigSpec portConfigSpec : dvportConfigSpec) {
			dvportsetting = portConfigSpec.getSetting();
			VMwareDVSPortSetting set = (VMwareDVSPortSetting) dvportsetting;
			set.setLacpPolicy(null);
			portConfigSpec.setSetting(set);
			portConfigSpec.setOperation(ConfigSpecOperation.EDIT.value());
		}
      Assert.assertTrue(dvs.reconfigurePort(dvsMor, dvportConfigSpec),
               "Successfully reconfigured dvport",
               "Unable to reconfigure dvport");

      // create the spec
      DVPortgroupConfigSpec dvpgSpec = NetworkResourcePoolHelper.createDvpgSpec(
               connectAnchor, getTestId(), dvsMor);
      DVPortgroupPolicy dvportgroupPolicy = new DVPortgroupPolicy();
      dvportgroupPolicy.setNetworkResourcePoolOverrideAllowed(true);
      dvportgroupPolicy.setLivePortMovingAllowed(true);
      dvpgSpec.setPolicy(dvportgroupPolicy);
      NetworkResourcePoolHelper.associateNrpToDvpgSpec(dvpgSpec, nrp[1]);

      // Now add the portgroup
      List<ManagedObjectReference> pgMors = dvs.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvpgSpec });
      Assert.assertNotEmpty(pgMors, "Portgroup added successfully",
               "Portgroup could not be added");
      dvPortgroupKey = dvpg.getKey(pgMors.get(0));

      return true;
   }

   /**
    * Test method
    */
   @Test(description = " Reconfigure a dvPortgroup to have an nrp associated to it. "
               + "Set the nrpOverrideAllowed flag to true."
               + "Move a standalone dvPort associated with a different nrp into this dvPortgroup.")
   public void test()
      throws Exception
   {
      // move the dvport into the portgroup
      Assert.assertTrue(dvs.movePort(dvsMor, dvPortsArr, dvPortgroupKey),
               "Successfully moved dvport to the dvportgroup",
               "Unable to move dvport to the dvportgroup");

      // retrieve the port map from the dvs
      Map<String, DistributedVirtualPort> portMap = DVSUtil.getPortMap(
               connectAnchor, dvsMor, dvPortsArr);
      Assert.assertTrue(portMap != null && !portMap.isEmpty(),
               "Ports not empty", "Ports list empty");

      // retrieve the port
      DistributedVirtualPort dvport = portMap.get(dvPortsArr[0]);

      // verify that the nrp associated with the dvport continues to remain attached to the dvport
      Assert.assertTrue(NetworkResourcePoolHelper.isNrpAssociatedToDvport(
               connectAnchor, dvport, nrp[0].getKey()),
               "Nrp is associated with the dvport",
               "Nrp is not associated with the dvport");

      // Now move the dvport out of the portgroup
      Assert.assertTrue(dvs.movePort(dvsMor, dvPortsArr, null),
               "Successfully moved dvport out of the dvportgroup",
               "Unable to move dvport out of the dvportgroup");

      // Now verify the nrp is still attached to the dvport
      Assert.assertTrue(NetworkResourcePoolHelper.isNrpAssociatedToDvport(
               connectAnchor, dvport, nrp[0].getKey()),
               "Nrp is associated with the dvport",
               "Nrp is not associated with the dvport");
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      Assert.assertTrue(dvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Test Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Reconfigure a dvPortgroup to have an nrp associated to it. "
               + "Set the nrpOverrideAllowed flag to true."
               + "Move a standalone dvPort associated with a different nrp into this dvPortgroup.");
   }

}

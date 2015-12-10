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

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * DESCRIPTION:Associate a dvPg with a newly created nrp. Have a dvPort with no
 * nrps attached to it.Move the dvPort into the dvPg.Move the dvPort out of the
 * dvPg<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1. Create a vDS<BR>
 * 2. Enable netiorm <BR>
 * 3. Add a nrp to it<BR>
 * 4. Create the dv port<BR>
 * TEST:<BR>
 * 5. Reconfigure a port on the dvs with nrp associated to it<BR>
 * 6. Verify that the port is associated with the nrp<BR>
 * CLEANUP:<BR>
 * 7. Destroy the dvs<BR>
 */
public class Pos064 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private DistributedVirtualPortgroup dvpg;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private List<String> standaloneDvPorts;
   private String dvPortgroupKey;

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
      DVPortgroupConfigSpec[] dvpgSpec = new DVPortgroupConfigSpec[1];

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
      DVSNetworkResourcePoolConfigSpec nrpConfigSpec = NetworkResourcePoolHelper.createDefaultNrpSpec();

      // Add the network resource pool to the dvs
      dvs.addNetworkResourcePool(dvsMor,
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });

      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(
               connectAnchor, dvsMor, nrpConfigSpec), "NRP verified from dvs",
               "NRP not matching with DVS nrp");

      nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor, dvsMor,
               nrpConfigSpec.getName());

      // create the spec
      dvpgSpec[0] = NetworkResourcePoolHelper.createDvpgSpec(connectAnchor,
               getTestId(), dvsMor);
      DVPortgroupPolicy dvportgroupPolicy = new DVPortgroupPolicy();
      dvportgroupPolicy.setNetworkResourcePoolOverrideAllowed(true);
      dvportgroupPolicy.setLivePortMovingAllowed(true);
      dvpgSpec[0].setPolicy(dvportgroupPolicy);
      

      // attach the nrp to the dvportgroup
      NetworkResourcePoolHelper.associateNrpToDvpgSpec(dvpgSpec, nrp);

      // Now add the portgroup
      List<ManagedObjectReference> pgMors = dvs.addPortGroups(dvsMor, dvpgSpec);
      Assert.assertNotEmpty(pgMors, "Portgroup added successfully",
               "Portgroup could not be added");
      dvPortgroupKey = dvpg.getKey(pgMors.get(0));

      standaloneDvPorts = dvs.addStandaloneDVPorts(dvsMor, 1);

      Assert.assertNotEmpty(standaloneDvPorts,
               "Standalone port added successfully",
               "Standalone port could not be added");
      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Associate a dvPg with a newly created nrp. "
               + "Have a dvPort with no nrps attached to it. "
               + "Move the dvPort into the dvPg. Move the dvPort out of the dvPg")
   public void test()
      throws Exception
   {
      // move the dvport into the portgroup
      String[] standaloneDvPortsArr = (String[]) standaloneDvPorts.toArray(new String[standaloneDvPorts.size()]);

      Assert.assertTrue(dvs.movePort(dvsMor, standaloneDvPortsArr,
               dvPortgroupKey), "Successfully moved dvport to the dvportgroup",
               "Unable to move dvport to the dvportgroup");
      // retrieve the port map from the dvs
      Map<String, DistributedVirtualPort> portMap = DVSUtil.getPortMap(
               connectAnchor, dvsMor, standaloneDvPortsArr);
      Assert.assertTrue(portMap != null && !portMap.isEmpty(),
               "Ports not empty", "Ports list empty");

      // retrieve the port
      DistributedVirtualPort dvport = portMap.get(standaloneDvPorts.get(0));

      // verify that the nrp is attached to the dvport after the move into
      // dvportgroup
      Assert.assertTrue(NetworkResourcePoolHelper.isNrpAssociatedToDvport(
               connectAnchor, dvport, nrp.getKey()),
               "Verfied nrp is attached to dvport",
               "Unable to verify nrp attached to dvport");

      // now move the dvport out of the dvportgroup
      Assert.assertTrue(dvs.movePort(dvsMor, standaloneDvPortsArr, null),
               "Successfully moved dvport out of the dvportgroup",
               "Unable to move dvport out of the dvportgroup");

      // retrieve the port map from the dvs
      portMap = DVSUtil.getPortMap(connectAnchor, dvsMor, standaloneDvPortsArr);
      Assert.assertTrue(portMap != null && !portMap.isEmpty(),
               "Ports not empty", "Ports list empty");

      // retrieve the port
      dvport = portMap.get(standaloneDvPorts.get(0));

      // verify that the nrp is not attached to the dvport after moving out of
      // dvportgroup
      Assert.assertTrue(!NetworkResourcePoolHelper.isNrpAssociatedToDvport(
               connectAnchor, dvport, nrp.getKey()),
               "Verfied nrp is not attached to dvport",
               "Unable to verify nrp not attached to dvport");

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
      setTestDescription("Associate a dvPg with a newly created nrp. "
               + "Have a dvPort with no nrps attached to it. "
               + "Move the dvPort into the dvPg. Move the dvPort out of the dvPg");
   }
}

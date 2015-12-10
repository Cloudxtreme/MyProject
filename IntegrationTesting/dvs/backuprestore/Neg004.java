package dvs.backuprestore;

/*
 * ************************************************************************
 *
 * Copyright 2011 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

/**
 * @author kmokada
 *
 */

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupSelection;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSSelection;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.EntityBackupConfig;
import com.vmware.vc.ManagedObjectNotFound;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.SelectionSet;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;
import com.vmware.vcqa.vim.host.NetworkSystem;


/**
 * Export the vds and portgroup configuration, delete the vds and import
 * the vds configuration and portgroup configuration (with new
 * identifier using the old vds uuid). The test is expected to throw
 * ManagedObjectNotFound exception.
 */
public class Neg004 extends TestBase
{
   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Map allHosts = null;
   private ManagedObjectReference hostMor = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference vmMor = null;
   private String vmName = null;
   private VirtualMachinePowerState originalVMState = null;
   private String dvSwitchUuid = null;
   private Folder iFolder = null;
   private NetworkSystem ins = null;
   private ManagedObjectReference dcMor = null;
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DistributedVirtualSwitchManager iDVSMgr = null;
   private ManagedObjectReference dvsManagerMor = null;
   private DistributedVirtualPortgroup idvpg = null;
   private ManagedObjectReference nsMor = null;
   private Map<String, DVPortgroupConfigSpec> hmPgConfig = new HashMap<String, DVPortgroupConfigSpec>();
   private ManagedObjectReference dvsMor = null;
   SelectionSet[] selectionSet = new SelectionSet[2];
   SelectionSet[] dvpgSelectionSet = new SelectionSet[2];
   EntityBackupConfig[] VDSConfig = null;
   EntityBackupConfig[] dvpgConfig = null;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      Iterator it = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      String[] pnicIds = null;
      log.info("Test setup Begin:");
      iFolder = new Folder(connectAnchor);
      iDVSMgr = new DistributedVirtualSwitchManager(connectAnchor);
      iDistributedVirtualSwitch = new DistributedVirtualSwitch(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      idvpg = new DistributedVirtualPortgroup(connectAnchor);
      dcMor = iFolder.getDataCenter();
      ihs = new HostSystem(connectAnchor);
      iNetworkSystem = new NetworkSystem(connectAnchor);
      hostMor = ihs.getConnectedHost(null);
      assertNotNull(hostMor,"Found a host in the inventory","Unable to " +
            "find a host in the inventory");
      return true;
   }

   /**
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Neg004: Export vds configuration, "
            + "portgroup configuration, recreate vds configuration and "
            + "portgroup configuration with new identifier\n")
   public void test()
      throws Exception
   {
      try {
         ManagedObjectReference srcDVSMor = null;
         log.info("Test Begin:");
         boolean status = false;
         dvsManagerMor = iDVSMgr.getDvSwitchManager();
         DVPortgroupSelection dvpgSS = new DVPortgroupSelection();
         int count = 0;
         int pgcount = 0;
         String dvsUUID;
         DistributedVirtualSwitchPortConnection portConnection = null;
         Vector<DistributedVirtualSwitchPortConnection> pcs = new
                  Vector<DistributedVirtualSwitchPortConnection>();
         String[] freePnics = ins.getPNicIds(hostMor);
         assertTrue(freePnics.length >= 1, "Found a host with free pnics",
                  "Failed to find a host with free pnics");
         /*
          * Migrate the host to the vds
          */
         srcDVSMor = migrateNetworkToDVS(hostMor, freePnics[0], "DVS1");
         assertNotNull(srcDVSMor, "Successfully created the DVSwitch",
                  "Null returned for Distributed Virtual Switch MOR");
         assertTrue(
                  (iNetworkSystem.refresh(iNetworkSystem.getNetworkSystem(hostMor))),
                  "Unable to refresh NetworkSystem of host");
         DVSSelection dvsSelSet = new DVSSelection();
         ManagedObjectReference ephepg = addPG(srcDVSMor,
                  DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL,
                  this.iDistributedVirtualSwitch.getName(srcDVSMor));
         dvsUUID = iDistributedVirtualSwitch.getConfig(srcDVSMor).getUuid();
         log.info("The DVS UUID is " + dvsUUID);
         dvsSelSet.setDvsUuid(dvsUUID);
         selectionSet[0] = dvsSelSet;
         DVPortgroupSelection pgSelection = new DVPortgroupSelection();
         pgSelection.setDvsUuid(dvsUUID);
         String[] ephemeral = new String[1];
         ephemeral[0] = idvpg.getKey(ephepg);
         pgSelection.getPortgroupKey().clear();
         pgSelection.getPortgroupKey().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(ephemeral));
         dvpgSelectionSet[0] = pgSelection;
         VDSConfig = iDVSMgr.exportEntity(dvsManagerMor, selectionSet);
         dvpgConfig = iDVSMgr.exportEntity(dvsManagerMor, dvpgSelectionSet);
         dvpgConfig[0].setName("importdvpg1");
         DVSConfigInfo info = iDistributedVirtualSwitch.getConfig(srcDVSMor);
         dvSwitchUuid = info.getUuid();
         portConnection = new DistributedVirtualSwitchPortConnection();
         portConnection.setSwitchUuid(dvSwitchUuid);
         portConnection.setPortgroupKey(ephemeral[0]);
         pcs.add(portConnection);
         /*
          * Delete the vds from inventory
          */
         assertTrue(iDistributedVirtualSwitch.destroy(srcDVSMor),
                  "Successfully destroyed DVS1", "Failed to destroy DVS1");
         iDVSMgr.importEntity(dvsManagerMor, VDSConfig,
                  "createEntityWithOriginalIdentifier");
         iDVSMgr.importEntity(dvsManagerMor, dvpgConfig,
                  "createEntityWithNewIdentifier");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.
                  util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new
                  ManagedObjectNotFound();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      List<ManagedObjectReference> vdsMorList = this.iFolder.
               getAllDistributedVirtualSwitch(this.
               iFolder.getNetworkFolder(dcMor));
      if (vdsMorList != null && vdsMorList.size() > 0) {
         for(ManagedObjectReference mor : vdsMorList){
            assertTrue(iDistributedVirtualSwitch.destroy(mor),
                     "Successfully deleted vds : " + mor,
                     "Failed to delete vds : " + mor);
         }
      }
      return true;
   }

   /*
    * add pg here
    */
   private ManagedObjectReference addPG(ManagedObjectReference dvsMor,
                                        String type,
                                        String name)
      throws Exception
   {
      ManagedObjectReference pgMor = null;
      DVPortgroupConfigSpec pgConfigSpec = new DVPortgroupConfigSpec();
      pgConfigSpec.setName(name);
      pgConfigSpec.setType(type);
      List<ManagedObjectReference> pgList = iDistributedVirtualSwitch.
               addPortGroups(
               dvsMor, new DVPortgroupConfigSpec[] { pgConfigSpec });
      if (pgList != null && pgList.size() == 1) {

         log.info("Successfully added the early binding "
                  + "portgroup to the DVS " + name);
         pgMor = pgList.get(0);
         hmPgConfig.put(type, pgConfigSpec);
      }
      return pgMor;
   }

   /*
    * CreateDistributedVirtualSwitch with HostMemberPnicSpec
    */

   private ManagedObjectReference migrateNetworkToDVS(ManagedObjectReference hostMor,
                                                      String pnic,
                                                      String vDsName)
      throws Exception
   {
      ManagedObjectReference nwSystemMor = null;
      ManagedObjectReference dvsMor = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      nwSystemMor = ins.getNetworkSystem(hostMor);
      hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
      hostMember.setHost(hostMor);
      pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new
               DistributedVirtualSwitchHostMemberPnicSpec();
      pnicSpec.setPnicDevice(pnic);
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(new
               DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
      hostMember.setBacking(pnicBacking);
      DVSConfigSpec dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(vDsName);
      dvsConfigSpec.setNumStandalonePorts(1);
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(new
               DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(iFolder.getDataCenter()),
               dvsConfigSpec);
      if (dvsMor != null
               && ins.refresh(nwSystemMor)
               && iDistributedVirtualSwitch.validateDVSConfigSpec(dvsMor,
                        dvsConfigSpec, null)) {
         log.info("Successfully created the distributed " + "virtual switch");

      } else {
         log.error("Unable to create DistributedVirtualSwitch");
      }
      return dvsMor;
   }
}

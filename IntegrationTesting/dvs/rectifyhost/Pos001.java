/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.rectifyhost;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWERON_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWERON_PASS;

import java.util.Arrays;
import java.util.List;
import java.util.Vector;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalDVSHelper;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:<br>
 * Test case for Rectifyhost api( for HostDVSManager.updateDVPortGroups api)<br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS with host<br>
 * TEST:<br>
 * 2. Add a PG to DVS<BR>
 * 3. Get the PG name  ( ON VC)<BR>
 * 4. Reconfigure PG using HostDVSManager.updateDVPortGroups (On hostd)<BR>
 * 5. Invoke Rectifyhost api<BR>
 * 6. Get the PG name  ( ON HOSTD)<BR>
 * 7. Compare PG name on hostd with VC<BR>
 * CLEANUP:<br>
 * 8. Destroy the VM<BR>
 * 9. Destroy the DVS<BR>
 */
public class Pos001 extends TestBase
{
   public static final Logger log = LoggerFactory.getLogger(Pos001.class);

   private String early = DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;
   private ManagedObjectReference pgMor = null;
   private String portgroupKey = null;
   private Vector<ManagedObjectReference> vmMors = null;

   private Folder folder;
   private HostSystem hostSystem;
   private VirtualMachine virtualMachine;
   private DistributedVirtualSwitch DVS;
   private DistributedVirtualPortgroup dvPortGroup;
   private ManagedObjectReference dvsMor;
   private ManagedObjectReference hostMor;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private String dvsName = null;
   private String dvsSwitchUuid = null;
   private ConnectAnchor hostdConnectAnchor = null;
   private String connectedHostName = null;
   private InternalHostDistributedVirtualSwitchManager hostDVSManager = null;
   private InternalServiceInstance msi = null;
   private String pgNameOnHostd = null;
   private UserSession hostLoginSession = null;
   private SessionManager sessionManager = null;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      ManagedObjectReference sessionMgrMor = null;
      this.folder = new Folder(connectAnchor);
      this.DVS = new DistributedVirtualSwitch(connectAnchor);
      this.hostSystem = new HostSystem(connectAnchor);
      this.virtualMachine = new VirtualMachine(connectAnchor);
      this.dvPortGroup = new DistributedVirtualPortgroup(connectAnchor);
      this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      this.dvPortgroupConfigSpec.setConfigVersion("");
      this.dvPortgroupConfigSpec.setName(TestUtil.getShortTime() + "_DVPG");
      this.hostMor = hostSystem.getConnectedHost(false);
      connectedHostName = hostSystem.getHostName(hostMor);
      hostdConnectAnchor =
               new ConnectAnchor(connectedHostName, connectAnchor.getPort());
      hostDVSManager =
               new InternalHostDistributedVirtualSwitchManager(
                        hostdConnectAnchor);
      sessionManager = new SessionManager(hostdConnectAnchor);
      sessionMgrMor = sessionManager.getSessionManager();
      hostLoginSession =
               new SessionManager(hostdConnectAnchor).login(sessionMgrMor,
                        TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD,
                        null);
      msi = new InternalServiceInstance(hostdConnectAnchor);
      Assert.assertNotNull(msi, "The service instance is null");
      dvsName = TestUtil.getShortTime() + "_DVS";
      dvsMor = folder.createDistributedVirtualSwitch(dvsName);
      assertNotNull(dvsMor, "Successfully created DVS: " + dvsName,
               "Failed to create DVS: " + dvsName);
      assertTrue(DVSUtil.addFreePnicAndHostToDVS(connectAnchor, hostSystem
               .getConnectedHost(false), Arrays
               .asList(new ManagedObjectReference[] { dvsMor })),
               "Failed to add host to DVS");
      dvsSwitchUuid = DVS.getConfig(dvsMor).getUuid();
      return true;
   }

   @Override
   @Test(description = "1. Create DVS\n"
            + "2. Add Host to DVS\n"
            + "3. Add a PG to DVS\n"
            + "4. Get the PG name ( ON VC)\n"
            + "5. Reconfigure PG using HostDVSManager.updateDVPortGroups ( On hostd)\n"
            + "6. Invoke Rectifyhost api\n"
            + "7. Get the PG name  ( ON HOSTD)\n"
            + "8. Compare PG name on hostd with VC\n")
   public void test()
      throws Exception
   {
      ManagedObjectReference hostDVSManagerMor = null;
      DVPortgroupConfigSpec origSpec = null;
      DVPortgroupConfigSpec updatedSpec = null;
      DVPortgroupConfigSpec pgConfigSpec = new DVPortgroupConfigSpec();
      List<ManagedObjectReference> pgList = null;
      pgConfigSpec.setName(this.getTestId() + "1-" + early);
      pgConfigSpec.setType(early);
      pgConfigSpec.setNumPorts(1);
      pgList =
               this.DVS.addPortGroups(this.dvsMor,
                        new DVPortgroupConfigSpec[] { pgConfigSpec });
      assertTrue((pgList != null && pgList.size() == 1),
               "Successfully added the " + early + " portgroup to the DVS "
                        + this.getTestId() + early, " Failed to add " + early
                        + "portgroup");

      pgMor = pgList.get(0);
      origSpec = this.dvPortGroup.getConfigSpec(this.pgMor);
      Assert.assertNotNull(pgMor, "Failed to add portgroup " + early);
      this.portgroupKey = this.dvPortGroup.getKey(pgMor);
      log.info("portgroupKey " + portgroupKey);
      /*
       * Create a VM
       */
      this.vmMors = DVSUtil.createVms(this.connectAnchor, this.hostMor, 1, 0);
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      vmConfigSpec =
               DVSUtil.getVMConfigSpecForDVSPort(this.vmMors.get(0),
                        this.connectAnchor,
                        new DistributedVirtualSwitchPortConnection[] { DVSUtil
                                 .buildDistributedVirtualSwitchPortConnection(
                                          dvsSwitchUuid, null, portgroupKey) });
      Assert
               .assertTrue((vmConfigSpec != null && vmConfigSpec.length == 2
                        && vmConfigSpec[0] != null && vmConfigSpec[1] != null),
                        "Successfully obtained the original and the updated virtual"
                                 + " machine config spec",
                        "Cannot reconfigure the virtual machine to use the "
                                 + "DV port");
      Assert.assertTrue(this.virtualMachine.reconfigVM(this.vmMors.get(0),
               vmConfigSpec[0]),
               "Successfully reconfigured the virtual machine to use "
                        + "the DV port",
               "Failed to  reconfigured the virtual machine to use "
                        + "the DV port");
      Assert.assertTrue(DVSUtil.performVDSPortVerifcation(connectAnchor,
               hostMor, this.vmMors.get(0), DVSUtil
                        .buildDistributedVirtualSwitchPortConnection(
                                 dvsSwitchUuid, null, portgroupKey),
               dvsSwitchUuid),
               " Failed to verify port connection  and/or PortPersistenceLocation for VM : "
                        + this.virtualMachine.getName(this.vmMors.get(0)));
      assertTrue((this.virtualMachine.setVMsState(this.vmMors, VirtualMachinePowerState.POWERED_ON, false)), VM_POWERON_PASS,
               VM_POWERON_FAIL);
      hostDVSManagerMor =
               msi.getInternalServiceInstanceContent()
                        .getHostDistributedVirtualSwitchManager();
      Assert.assertNotNull(hostDVSManager, "The host DVS manager "
               + "mor is null");
      assertTrue(InternalDVSHelper.updateDVPortGroupViaHostd(connectAnchor,
               hostMor, pgMor, dvsSwitchUuid),
               " Successfully updated DVPortGroup via hostd",
               " Failed to update DVPortGroup via hostd");
      pgNameOnHostd =
               this.hostDVSManager.retrieveDVPortgroupConfigSpec(
                        hostDVSManagerMor, this.dvsSwitchUuid,
                        new String[] { portgroupKey })[0].getSpecification()
                        .getName();
      log.info("DVPG name on hostd : " + pgNameOnHostd);
      assertTrue(!(origSpec.getName().equalsIgnoreCase(pgNameOnHostd)),
               " DVPG name on  host does not matches with DVPG name on VC",
               "DVPG name on  host is the same as the DVPG anme on VC");
      assertTrue(this.DVS.rectifyHost(dvsMor,
               new ManagedObjectReference[] { this.hostMor }),
               "Failed to rectifyHost");
      updatedSpec = this.dvPortGroup.getConfigSpec(this.pgMor);
      assertTrue(TestUtil.compareObject(updatedSpec, origSpec, TestUtil
               .getIgnorePropertyList(origSpec, false)),
               "rectifyHost api fixed DVPortGroup spec",
               " rectifyHost api failed  DVPortGroup spec");
      pgNameOnHostd =
               this.hostDVSManager.retrieveDVPortgroupConfigSpec(
                        hostDVSManagerMor, this.dvsSwitchUuid,
                        new String[] { portgroupKey })[0].getSpecification()
                        .getName();
      log.info("DVPG name on hostd : " + pgNameOnHostd);
      assertTrue((origSpec.getName().equalsIgnoreCase(pgNameOnHostd)),
               "DVPG name on  host is the same as the DVPG anme on VC",
               " DVPG name on  host does not matches with DVPG name on VC");
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      if(sessionManager != null) {
         Assert.assertTrue(new SessionManager(hostdConnectAnchor).logout(sessionManager.getSessionManager()),
                  "Successfully logged out ", "Failed to logout.");
      }
      if (this.vmMors != null) {
         assertTrue(this.virtualMachine.setVMsState(vmMors, VirtualMachinePowerState.POWERED_OFF, false),
                  VM_POWEROFF_PASS, VM_POWEROFF_PASS);
         this.virtualMachine.destroy(vmMors);
      }
      if (this.dvsMor != null) {
         assertTrue(this.DVS.destroy(this.dvsMor),
                  "Successfully Destroyed Vds", "Failed to destroy Vds");
      }
      return true;
   }
}
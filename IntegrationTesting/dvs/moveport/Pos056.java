/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.HostDVSPortData;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a conflict standalone DVPort to DVS.
 */
public class Pos056 extends MovePortBase
{
   private SessionManager sessionManager = null;
   private HostNetworkConfig[][] hostNetworkConfig = null;
   private ManagedObjectReference secondHostMor = null;
   private String secondHostName = null;
   private String dvsUuid = null;
   ManagedObjectReference vm1Mor = null;
   ManagedObjectReference vm2Mor = null;
   private String vm2Name = null;
   private DVPortSetting portSetting = null;
   /* deltaConfigSpec of the VM to restore it to Original form.*/
   private VirtualMachineConfigSpec vm1DeltaCfgSpec = null;
   /* deltaConfigSpec of the VM to restore it to Original form.*/
   private VirtualMachineConfigSpec vm2DeltaCfgSpec = null;
   boolean firstHostUpdated = false;
   boolean secondHostUpdated = false;
   private Connection conn = null;
   private ConnectAnchor hostConnectAnchor = null;
   private AuthorizationManager iAuthentication = null;
   private ManagedObjectReference sessionMgrMor = null;
   private HostConnectSpec hostConnectSpec = null;

   /**
    * Test setup. 1. Create DVS. 2. Create a standalone DVPort in it. 3. Create
    * a VM VM-1 which connects to the DVPort. 4. Unregister the VM-1. 5. Create
    * a VM VM-2 which connects to the same DVPort. 6. Register the VM-1, this
    * will result in creation of conflict DVPort. 7. Get the key of the conflict
    * port and use it as port key.
    *
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, if test setup was successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      sessionManager = new SessionManager(connectAnchor);

      boolean status = false;
      List<ManagedObjectReference> vms = null;
      String key = null;// key of conflict DVPort.
      Vector<ManagedObjectReference> allHosts = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      DistributedVirtualPort dvPort = null;
      List<DistributedVirtualPort> dvPorts = null;
      try {
         if (super.testSetUp()) {
            allHosts = this.ihs.getAllHost();
            if ((allHosts != null) && (allHosts.size() >= 2)) {
               for (ManagedObjectReference tempMor : allHosts) {
                  if ((tempMor != null) && this.ihs.isHostConnected(tempMor)) {
                     if (this.hostMor == null) {
                        this.hostMor = tempMor;
                     } else if (this.secondHostMor == null) {
                        this.secondHostMor = tempMor;
                        break;
                     }
                  }
               }
            }
            if ((this.hostMor != null) && (this.secondHostMor != null)) {
               this.secondHostName = this.ihs.getHostName(this.secondHostMor);
               hostConnectSpec = this.ihs.getHostConnectSpec(secondHostMor);
               this.dvsMor = iFolder.createDistributedVirtualSwitch(
                        this.dvsName, new ManagedObjectReference[] {
                                 this.hostMor, this.secondHostMor });
               if (dvsMor != null) {
                  this.dvsUuid = this.iDVSwitch.getConfig(this.dvsMor).getUuid();
                  vms = ivm.getAllVMs(hostMor);
                  if ((vms != null) && (vms.size() >= 1)) {
                     vm1Mor = vms.get(0);
                     this.hostNetworkConfig = new HostNetworkConfig[2][2];
                     // update the network to use the DVS.
                     hostNetworkConfig[0] = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                              dvsMor, hostMor);
                     if ((hostNetworkConfig[0] != null)
                              && (hostNetworkConfig[0][0] != null)
                              && (hostNetworkConfig[0][1] != null)) {
                        firstHostUpdated = ins.updateNetworkConfig(
                                 ins.getNetworkSystem(hostMor),
                                 hostNetworkConfig[0][0],
                                 TestConstants.CHANGEMODE_MODIFY);
                        if (firstHostUpdated) {
                           log.info("Successfully updated the network to use"
                                    + " DVS.");
                           hostNetworkConfig[1] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                                    this.dvsMor, this.secondHostMor);
                           if ((this.hostNetworkConfig[1] != null)
                                    && (this.hostNetworkConfig.length == 2)
                                    && (this.hostNetworkConfig[1][0] != null)
                                    && (this.hostNetworkConfig[1][1] != null)) {
                              this.secondHostUpdated = this.ins.updateNetworkConfig(
                                       this.ins.getNetworkSystem(this.secondHostMor),
                                       this.hostNetworkConfig[1][0],
                                       TestConstants.CHANGEMODE_MODIFY);
                              if (secondHostUpdated) {
                                 this.portKeys = this.iDVSwitch.addStandaloneDVPorts(
                                          this.dvsMor, 1);
                                 if ((this.portKeys != null)
                                          && (this.portKeys.size() >= 1)) {
                                    portCriteria = this.iDVSwitch.getPortCriteria(
                                             null,
                                             null,
                                             null,
                                             null,
                                             new String[] { this.portKeys.get(0) },
                                             false);
                                    dvPorts = this.iDVSwitch.fetchPorts(
                                             this.dvsMor, portCriteria);
                                    if ((dvPorts != null)
                                             && (dvPorts.size() > 0)) {
                                       dvPort = dvPorts.get(0);
                                       if (dvPort != null) {
                                          this.portSetting = dvPort.getConfig().getSetting();
                                       }
                                    }
                                    key = createConflictPort(this.dvsMor,
                                             this.portKeys.get(0),
                                             connectAnchor);
                                    if (key != null) {
                                       this.portKeys = new ArrayList<String>(1);
                                       this.portKeys.add(key);
                                       status = true;
                                    }
                                 }
                              } else {
                                 log.error("Can not update the host network "
                                          + "config");
                              }
                           } else {
                              log.error("Can not retreive the host network "
                                       + "config");
                           }
                        } else {
                           log.error("Failed to update the netwok config.");
                        }
                     } else {
                        log.info("Failed to get 2 VM's.");
                     }
                  } else {
                     log.error("Can not find the required VM's in the setup");
                  }
               } else {
                  log.error("Can not create the DVS");
               }
            } else {
               log.error("Can not find the required hosts in the setup");
            }
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         try {
            status &= SSHUtil.closeSSHConnection(this.conn);
         } catch (Exception e) {
            status &= false;
         }
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. Move the DVPort in the DVPortgroup by providing null port key.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Move a conflict standalone DVPort to DVS.")
   public void test()
      throws Exception
   {
      assertTrue(movePort(dvsMor, portKeys, null), "Successfully moved the "
               + "port", "Failed to move the port");
   }

   /**
    * Test cleanup.
    *
    * @param connectAnchor ConnectAnchor.
    * @return true, if test cleanup was successful. false, otherwise.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         // get the VM's to previous state.
         try {
            if ((this.vm1DeltaCfgSpec != null)
                     && this.ivm.setVMState(this.vm1Mor, POWERED_OFF, false)) {
               status = this.ivm.reconfigVM(this.vm1Mor, this.vm1DeltaCfgSpec);
            }
         } catch (Exception e) {
            log.error("Failed to restore VM1.");
            status &= false;
         }
         if (this.secondHostMor != null
                  && !this.ihs.isHostConnected(this.secondHostMor)) {
            Assert.assertTrue(this.ihs.reconnectHost(secondHostMor,
                     this.hostConnectSpec, null), " Host not connected");
         }

         try {
            if (this.vm2Name != null) {
               if (this.hostConnectAnchor != null) {
                  this.ivm = new VirtualMachine(this.hostConnectAnchor);
                  this.vm2Mor = this.ivm.getVMByName(this.vm2Name, null);
               }
            }
            if ((this.vm2Mor != null) && (this.vm2DeltaCfgSpec != null)
                     && this.ivm.setVMState(this.vm2Mor, POWERED_OFF, false)) {
               status &= this.ivm.reconfigVM(this.vm2Mor, this.vm2DeltaCfgSpec);
            } else {
               log.error("Failed to restore VM1.");
               status = false;
            }
         } catch (Exception e) {
            log.error("Can not reconfigure the VM to its original setting");
            TestUtil.handleException(e);
            status &= false;
         }
         if (firstHostUpdated) {
            if (this.ins.updateNetworkConfig(
                     this.ins.getNetworkSystem(hostMor),
                     this.hostNetworkConfig[0][1],
                     TestConstants.CHANGEMODE_MODIFY)) {
               log.info("Successfully restored the network config.");
            } else {
               status &= false;
               log.error("Failed to restore the network config.");
            }
         }

         if (this.secondHostUpdated) {
            if (this.ihs.isHostConnected(this.secondHostMor)
                     && this.ins.updateNetworkConfig(
                              this.ins.getNetworkSystem(this.secondHostMor),
                              this.hostNetworkConfig[1][1],
                              TestConstants.CHANGEMODE_MODIFY)) {
               log.info("Successfully restored the network config.");
            } else {
               status &= false;
               log.error("Failed to restore the network config.");
            }
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= super.testCleanUp();
         if (this.hostConnectAnchor != null) {
         }
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * Create a conflict port.
    *
    * @param dvSwtchMor DVS MOR.
    * @param portKey port key to be used.
    * @param connectAnchor ConnectAnchor object
    * @return The port key of the conflict DVPort.
    */
   private String createConflictPort(ManagedObjectReference dvSwtchMor,
                                     String portKey,
                                     ConnectAnchor connectAnchor)
      throws Exception
   {
      String conflictPortKey = null;
      InternalHostDistributedVirtualSwitchManager ihostDVSManager = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      InternalServiceInstance msi = null;
      ManagedObjectReference hostDVSManager = null;
      ManagedObjectReference haHostMor = null;
      ManagedObjectReference vmMor = null;
      HostSystem haHostSystem = null;
      VirtualMachine haVirtualMachine = null;
      UserSession hostLoginSession = null;
      HostDVSPortData portData = null;
      Vector allVMs = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<DistributedVirtualPort> ports = null;
      this.vm1DeltaCfgSpec = reconfigVM(this.vm1Mor, dvSwtchMor, connectAnchor,
               portKey, null);
      if ((this.vm1DeltaCfgSpec != null)
               && this.ivm.verifyPowerOps(vm1Mor, false)) {
         log.info("Successfully assigned DVPort with key " + portKey
                  + " to first VM VM1.");
         hostConnectAnchor = new ConnectAnchor(secondHostName,
                  data.getInt(TestConstants.TESTINPUT_PORT));
         if (hostConnectAnchor != null) {
            iAuthentication = new AuthorizationManager(hostConnectAnchor);
            sessionManager = new SessionManager(hostConnectAnchor);
            sessionMgrMor = sessionManager.getSessionManager();
            hostLoginSession = sessionManager.login(sessionMgrMor,
                     TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD,
                     null);
            if (hostLoginSession != null) {
               log.info("Successfully logged into the host "
                        + this.secondHostName);
               ihostDVSManager = new InternalHostDistributedVirtualSwitchManager(
                        hostConnectAnchor);
               haHostSystem = new HostSystem(hostConnectAnchor);
               msi = new InternalServiceInstance(hostConnectAnchor);
               haVirtualMachine = new VirtualMachine(hostConnectAnchor);
               if (this.ihs.disconnectHost(this.secondHostMor)) {
                  log.info("The host is successfully disconnected from"
                           + " the VC " + this.secondHostName);
                  haHostMor = haHostSystem.getHost(this.secondHostName);
                  if (haHostMor != null) {
                     hostDVSManager =
                              msi
                                       .getInternalServiceInstanceContent()
                                       .getHostDistributedVirtualSwitchManager();
                     portData = new HostDVSPortData();
                     portData.setPortKey(portKey);
                     portData.setSetting(this.portSetting);
                     portData.setConnectionCookie(5);
                     if (ihostDVSManager.hostDVSUpdatePorts(hostDVSManager,
                              this.dvsUuid, new HostDVSPortData[] { portData })) {
                        allVMs = haVirtualMachine.getAllVM();
                        for (Object temp : allVMs) {
                           if ((temp != null)
                                    && (temp instanceof ManagedObjectReference)) {
                              vmMor = (ManagedObjectReference) temp;
                              break;
                           }
                        }
                        if (vmMor != null) {
                           this.vm2Name = haVirtualMachine.getVMName(vmMor);
                           vdConfigSpec =
                                    DVSUtil.getAllVirtualEthernetCardDevices(
                                             vmMor, hostConnectAnchor);
                           if ((vdConfigSpec != null)
                                    && (vdConfigSpec.size() > 0)) {
                              portConnection =
                                       new DistributedVirtualSwitchPortConnection();
                              portConnection.setSwitchUuid(this.dvsUuid);
                              portConnection.setPortKey(portKey);
                              portConnection.setConnectionCookie(5);
                              vmConfigSpec =
                                       DVSUtil
                                                .getVMConfigSpecForDVSPort(
                                                         vmMor,
                                                         hostConnectAnchor,
                                                         new DistributedVirtualSwitchPortConnection[] { portConnection });
                              if ((vmConfigSpec != null)
                                       && (vmConfigSpec.length == 2)
                                       && (vmConfigSpec[0] != null)
                                       && (vmConfigSpec[1] != null)) {
                                 if (haVirtualMachine.reconfigVM(vmMor,
                                          vmConfigSpec[0])) {
                                    this.vm2DeltaCfgSpec = vmConfigSpec[1];
                                 }
                              }
                           }
                        }
                     }
                  }
               } else {
                  log.error("Can not disconnect the host from the VC ");
               }
                  if (this.vm2DeltaCfgSpec != null) {
                  if (this.ihs.reconnectHost(this.secondHostMor,
                           hostConnectSpec, null)) {
                     portCriteria =
                              this.iDVSwitch.getPortCriteria(null, null, null,
                                       null, null, false);
                     if (this.iDVSwitch.refreshPortState(this.dvsMor, null)) {
                        ports =
                                 this.iDVSwitch.fetchPorts(this.dvsMor,
                                          portCriteria);
                        if ((ports != null) && (ports.size() >= 2)) {
                           for (DistributedVirtualPort port : ports) {
                              if ((port != null)
                                       && port.isConflict()
                                       && portKey.equals(port
                                                .getConflictPortKey())) {
                                 conflictPortKey = port.getKey();
                                 break;
                              }
                           }
                        } else {
                           log.error("Can not retreive the ports");
                        }
                     } else {
                        log.error("Can not refresh the port state "
                                 + "for all the ports on the DVS");
                     }
                  } else {
                     log.error("The host is still not connected");
                  }
                  }
            } else {
               log.error("Can not login into the host "
                        + this.secondHostName);
            }
         } else {
            log.error("Can not get the connect anchor to the host "
                     + this.secondHostName);
         }
      } else {
         log.error("Failed to reconfigure the VM-1.");
      }
      return conflictPortKey;
   }
}
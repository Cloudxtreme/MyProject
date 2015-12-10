/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_ON;
import static com.vmware.vcqa.TestConstants.EESX_SSHCOMMAND_KILLVPXA;
import static com.vmware.vcqa.TestConstants.ESX_PASSWORD;
import static com.vmware.vcqa.TestConstants.ESX_USERNAME;
import static com.vmware.vcqa.TestConstants.SSHCOMMAND_KILLVPXA;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.InvalidDeviceSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Disconnect the host(H1) from the VC, Using hostd reconfigure a powered on VM
 * ) to connect to an early binding portgroup.
 */
public class Neg011 extends FunctionalTestBase
{
   private SessionManager sessionManager = null;
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec[] vmConfigSpec = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private ManagedObjectReference vmMor = null;
   private String vmName = null;
   private ConnectAnchor hostConnectAnchor = null;
   private Connection conn = null;
   private String hostName = null;
   private boolean vmReconfigured = false;
   private HostConnectSpec hostConnectSpec = null;

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the Standalone DVPort. 3. Create the VM ConfigSpec.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      sessionManager = new SessionManager(connectAnchor);

      boolean status = false;
      int timeout = TestConstants.MAX_WAIT_CONNECT_TIMEOUT;
      Vector allVms = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
      String pgKey = null;
      log.info("test setup Begin:");
      if (super.testSetUp()) {

            this.hostName = this.ihs.getHostName(this.hostMor);
            hostConnectSpec = this.ihs.getHostConnectSpec(hostMor);
            allVms = this.ihs.getVMs(this.hostMor, null);
            if (allVms != null && allVms.size() > 0) {
               this.vmMor = (ManagedObjectReference) allVms.get(0);
               if (this.vmMor != null) {
                  this.vmName = this.ivm.getVMName(this.vmMor);
                  status = this.ivm.setVMState(this.vmMor, POWERED_OFF, false);
                  if (status) {
                     vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                              this.vmMor, connectAnchor);
                     if (vdConfigSpec != null && vdConfigSpec.size() > 0) {
                        pgKey = this.iDVS.addPortGroup(this.dvsMor,
                                 DVPORTGROUP_TYPE_EARLY_BINDING,
                                 vdConfigSpec.size(), this.getTestId() + "-pg");
                        if (pgKey != null) {
                           log.info("Successfully Created theearly "
                                    + "binding portgroup");
                           for (int i = 0; i < vdConfigSpec.size(); i++) {
                              // create the
                              // DistributedVirtualSwitchPortConnection object.
                              this.dvsPortConnection = new DistributedVirtualSwitchPortConnection();
                              this.dvsPortConnection.setPortgroupKey(pgKey);
                              this.dvsPortConnection.setSwitchUuid(this.dvSwitchUUID);
                              if (this.dvsPortConnection != null) {
                                 if (portConnectionList == null) {
                                    portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                             vdConfigSpec.size());
                                 }
                                 portConnectionList.add(this.dvsPortConnection);
                              } else {
                                 log.error("The port connection object"
                                          + " is null");
                              }
                           }
                           if (portConnectionList != null
                                    && portConnectionList.size() > 0) {
                              this.vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                       this.vmMor,
                                       connectAnchor,
                                       portConnectionList.toArray(new DistributedVirtualSwitchPortConnection[portConnectionList.size()]));
                           }
                           if (this.vmConfigSpec != null
                                    && this.vmConfigSpec.length == 2
                                    && this.vmConfigSpec[0] != null
                                    && this.vmConfigSpec[1] != null) {
                              log.info("Successfully created "
                                       + "VMConfig spec.");
                              if (this.ihs.disconnectHost(this.hostMor)) {
                                 this.hostConnectAnchor = new ConnectAnchor(
                                          this.ihs.getHostName(hostMor),
                                          data.getInt(TestConstants.TESTINPUT_PORT));
                                 if (this.hostConnectAnchor != null) {
                                    log.info("Successfully "
                                             + "obtained the "
                                             + "connect anchor "
                                             + "to the host");
                                    status = true;
                                 } else {
                                    status = false;
                                    log.error("Can not obtain "
                                             + "the connect "
                                             + "anchor to the " + "host");
                                 }
                              } else {
                                 status = false;
                                 log.error("Can not disconnect"
                                          + " the Host from the VC");
                              }
                           } else {
                              status = false;
                              log.error("Can not retrieve the original"
                                       + " and updated VM config spec");
                           }

                        } else {
                           status = false;
                           log.error("Can not add the early binding "
                                    + "portgroup to the dv switch");
                        }
                     } else {
                        status = false;
                        log.error("There are no virtual ethernet cards"
                                 + " configured on the VM " + this.vmName);
                     }
                  } else {
                     log.error("Can not power off the VM ");
                  }
               } else {
                  log.error("The VM reference is null");
               }
            } else {
               log.error("There are no VM's on the host "
                        + this.hostName);
            }

      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Create the VM. 2. Varify the ConfigSpecs and Power-ops
    * operations.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Test(description = "Disconnect the host(H1) from the VC, Using hostd "
               + " reconfigure a powered on  VM  to connect to an early "
               + "binding portgroup.")
   public void test()
      throws Exception
   {
      boolean status = false;
      ManagedObjectReference hostVMMor = null;
      UserSession newLoginSession = null;
      AuthorizationManager newAuthentication = null;
      ManagedObjectReference newAuthenticationMor = null;
      /*
       * TODO use the correct method fault.
       */
      MethodFault expectedMethodFault = new InvalidDeviceSpec();

         newAuthentication = new AuthorizationManager(hostConnectAnchor);
         sessionManager = new SessionManager(hostConnectAnchor);
         newAuthenticationMor = sessionManager.getSessionManager();
         if (newAuthenticationMor != null) {
            newLoginSession = sessionManager.login(newAuthenticationMor,
                     TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD,
                     null);
            if (newLoginSession != null) {
               this.ivm = new VirtualMachine(this.hostConnectAnchor);
               hostVMMor = this.ivm.getVM(this.vmName);
               if (this.ivm.setVMState(hostVMMor, POWERED_ON, false)) {
                  try {
                     this.vmReconfigured = this.ivm.reconfigVM(hostVMMor,
                              this.vmConfigSpec[0]);
                     if (this.vmReconfigured) {
                        log.error("Successfully reconifgured the  VM.");
                     } else {
                        log.error("Unable to reconfigure the  VM.");
                     }
                  } catch (Exception mfExcep) {
                     MethodFault mf = com.vmware.vcqa.util.TestUtil.getFault(mfExcep);
                     status = TestUtil.checkMethodFault(mf, expectedMethodFault);
                  } finally {
                     status &= sessionManager.logout(newAuthenticationMor);
                  }
               }
            } else {
               log.error("Can not login into the hostd " + this.hostName);
            }
         } else {
            log.error("The authentication MOR is null");
         }

      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;

      this.ivm = new VirtualMachine(connectAnchor);
      if (this.hostMor != null && !this.ihs.isHostConnected(this.hostMor)) {
         Assert.assertTrue(this.ihs.reconnectHost(hostMor,
                  this.hostConnectSpec, null), " Host not connected");
         if (this.ivm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
            log.info("Successfully poweredOff the  VM.");
         } else {
            log.error("Can not connect the host back to the VC");
            status = false;
         }
      }
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
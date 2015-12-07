/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.TestConstants.EESX_SSHCOMMAND_KILLVPXA;
import static com.vmware.vcqa.TestConstants.SSHCOMMAND_KILLVPXA;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

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
import com.vmware.vc.NotSupported;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Disconnect the host(H1) from the VC, Using hostd Create a VM (VM1) to connect
 * to a standalone port.
 */
public class Neg004 extends FunctionalTestBase
{
   private SessionManager sessionManager = null;
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private String portKey = null;
   private ManagedObjectReference vmMor = null;
   private ConnectAnchor hostConnectAnchor = null;
   private Connection conn = null;
   private String esxHostName = null;
   private String vmName = null;
   private HostConnectSpec hostConnectSpec = null;


   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the Standalone DVPort. 3. Create the VM ConfigSpec.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      sessionManager = new SessionManager(connectAnchor);

      boolean status = false;
      List<String> portKeys = null;
      log.info("test setup Begin:");
      if (super.testSetUp()) {
         hostConnectSpec = this.ihs.getHostConnectSpec(hostMor);
         this.esxHostName = this.ihs.getHostName(this.hostMor);
         portKeys = this.iDVS.addStandaloneDVPorts(dvsMor, 1);
         if (portKeys != null) {
            log.info("Successfully get the standalone DVPortkeys");
            this.portKey = portKeys.get(0);
            // create the DistributedVirtualSwitchPortConnection object.
            this.dvsPortConnection =
                     new DistributedVirtualSwitchPortConnection();
            this.dvsPortConnection.setSwitchUuid(this.dvSwitchUUID);
            this.dvsPortConnection.setPortKey(this.portKey);
            this.vmName = this.getTestId() + "-vm";
            this.vmConfigSpec =
                     DVSUtil.buildCreateVMCfg(connectAnchor,
                              this.dvsPortConnection,
                              VM_VIRTUALDEVICE_ETHERNET_PCNET32, this.vmName,
                              this.hostMor);
            if (this.vmConfigSpec != null) {
               log.info("Successfully created VMConfig spec.");
               if (this.ihs.disconnectHost(this.hostMor)) {
                  this.hostConnectAnchor =
                           new ConnectAnchor(this.esxHostName, data
                                    .getInt(TestConstants.TESTINPUT_PORT));
                  if (this.hostConnectAnchor != null) {
                     log.info("Successfully obtained the connect"
                              + " anchor to the host");
                     status = true;
                  } else {
                     status = false;
                     log.error("Can not obtain the connect "
                              + "anchor to the host " + this.esxHostName);
                  }
               } else {
                  status = false;
                  log.error("Can not disconnect the Host from" + " the VC "
                           + this.esxHostName);
               }
            } else {
               log.error("Can not create a valid VM config spec");
            }
         } else {
            log.error("Failed to get the standalone DVPortkeys ");
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
               + "Create a VM (VM1) to connect to a standalone port.")
   public void test()
      throws Exception
   {
      try {
         boolean status = false;
         ManagedObjectReference hostHostMor = null;
         UserSession newLoginSession = null;
         ManagedObjectReference newAuthenticationMor = null;
         sessionManager = new SessionManager(hostConnectAnchor);
         newAuthenticationMor = sessionManager.getSessionManager();
         if (newAuthenticationMor != null) {
            newLoginSession =
                     new SessionManager(hostConnectAnchor).login(
                              newAuthenticationMor, TestConstants.ESX_USERNAME,
                              TestConstants.ESX_PASSWORD, null);

            if (newLoginSession != null) {
               this.ivm = new VirtualMachine(this.hostConnectAnchor);
               this.ihs = new HostSystem(this.hostConnectAnchor);
               hostHostMor = this.ihs.getConnectedHost(false);
               this.vmMor =
                        new Folder(hostConnectAnchor).createVM(this.ivm
                                 .getVMFolder(), this.vmConfigSpec, this.ihs
                                 .getPoolMor(hostHostMor), hostHostMor);
               if (this.vmMor != null) {
                  log.error("Successfully created VM. " + this.vmName);
               } else {
                  log.error("Unable to create VM. " + this.vmName);
               }
            }
         }
         assertTrue(status, "Test Failed");
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidDeviceSpec();
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
    * @return <code>true</code> if successful.
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;

      this.ihs = new HostSystem(connectAnchor);
      this.ivm = new VirtualMachine(connectAnchor);
      if (this.hostMor != null && !this.ihs.isHostConnected(this.hostMor)) {
         Assert.assertTrue(this.ihs.reconnectHost(hostMor,
                  this.hostConnectSpec, null), " Host not connected");
         log.info("Successfully connected the host back to the " + "VC "
                  + this.esxHostName);
         if (this.vmName != null && this.vmMor != null) {
            this.vmMor = this.ivm.getVM(this.vmName);
            if (this.vmMor != null) {
               if (this.ivm.destroy(this.vmMor)) {
                  log.info("Destroyed the created VM " + this.vmName);
               } else {
                  log.error("Can not destroy the VM " + this.vmName);
                  status = false;
               }
            }
         }
      }

      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
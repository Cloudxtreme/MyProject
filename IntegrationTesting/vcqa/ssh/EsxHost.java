/* **********************************************************************
 * Copyright 2013 VMware, Inc. All rights reserved. VMware Confidential
 * **********************************************************************
 * $Id$
 * DateTime - 01/28/2013
 * Change - 1
 * Author - Sivaprakashs
 * ********************************************************************
 */

package com.vmware.vcqa.ssh;

import java.io.IOException;
import java.util.Map;
import java.util.Vector;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.VirtualMachineFaultToleranceState;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.vim.FTTestConstants;

/**
 * Represents an ESX host. Commands are issued through an SSH connection.
 *
 * On garbage collection, the SSH connection is closed if it is still open.
 * Calling 'disconnect' is a more immediate method of closing the the
 * connection.
 *
 * @author sivaprakashs
 */
public class EsxHost
{
   // Time out constant
   protected static final int VALIDATION_TIMEOUT = 10000;
   private static final int FAILOVER_WAIT_MILLISEC = 60000;
   private static final int VM_CHECK_INTERVAL_MILLISEC = 5000;
   protected static final Logger log = LoggerFactory.getLogger(TestBase.class);

   /**
    * The possible state used to check the power state of a VM
    */
   protected static final String POWER_STATE_OFF = "Powered off";
   protected static final String POWER_STATE_ON = "Powered on";

   /**
    * Possible power state of an ESX host
    */
   public enum PowerState
   {
      ON, OFF;
   };

   /**
    * constants representing the type returned by the 'vmware -v' command.
    */
   public enum VMwareVersion
   {
      ESXi3_5, ESX4_0, ESXi4_0, ESX4_1, ESXi4_1, ESXi5_0;

      /**
       * Return the ESX version based on the string passed in. Intended to
       * look for the ESX version substring contained in the result of a
       * 'vmware -v' command.
       *
       * @param strVersion Result of the 'vmware -v' command
       * @return ESX version constant
       */
      public static VMwareVersion valueOfVersion(String strVersion)
      {
         if (strVersion.contains("ESXi 3.5")) {
            return VMwareVersion.ESXi3_5;
         } else if (strVersion.contains("ESX 4.0")) {
            return VMwareVersion.ESX4_0;
         } else if (strVersion.contains("ESXi 4.0")) {
            return VMwareVersion.ESXi4_0;
         } else if (strVersion.contains("ESX 4.1")) {
            return VMwareVersion.ESX4_1;
         } else if (strVersion.contains("ESXi 4.1")) {
            return VMwareVersion.ESXi4_1;
         } else if (strVersion.contains("ESXi 5.0")) {
            return VMwareVersion.ESXi5_0;
         }
         throw new IllegalArgumentException("Unknown ESX version: " + strVersion);
      }
   }


   // Connection object to the ESX host.
   private Connection objConnection = null;
   // Default the connection parameters, but allow them to be updated.
   private static String strUserName = TestConstants.ESX_USERNAME;
   private static String strPassword = TestConstants.ESX_PASSWORD;
   // IP of the remote Host
   private String strHostIp = null;
   // Verson information for this Host
   private String strVersion = null;

   /*
    * Block the default constructor. Connection IP must be specified.
    */
   protected EsxHost()
   {
   }

   /**
    * Store the host IP for the SSH connection.
    *
    * @param strHostIp IP of remote ESX server
    * @throws Exception Failure with the SSH connection has occurred.
    * @throws IOException Failure reading or writing SSH connection
    */
   public EsxHost(String strHostIp)
      throws IOException, Exception
   {
      this.strHostIp = strHostIp;
   }

   /*
    * Constructor used my instantiateHost routine to instantiate the correct
    * version of the host based on the ESX version.
    */
   protected EsxHost(String strHostIp, Connection objConnection)
   {
      this.objConnection = objConnection;
      this.strHostIp = strHostIp;
   }

   /*
    * Local method to manage getting the SSH connection.
    */
   public Connection getSshConnection()
      throws IOException, Exception
   {
      if (this.objConnection == null) {
         this.objConnection = SSHUtil.getSSHConnection(this.strHostIp,
            strUserName, strPassword);
      } else {
         /*
          * SSH connections timeout, so execute a command
          * to verify that the SSH connection is active
          */
         try {
            SSHUtil.executeRemoteSSHCommand(objConnection,
               "echo Testing SSH connection");
         } catch (Exception e) {
            this.objConnection.close();
            this.objConnection = SSHUtil.getSSHConnection(this.strHostIp,
               strUserName, strPassword);
         }
      }
      return this.objConnection;
   }

   /**
    * On garbage collection, the finalize method closes the SSH connection, if
    * if hasn't already been closed.
    *
    * @throws Throwable Not used.
    */
   @Override
   public void finalize()
      throws Throwable
   {
      this.disconnect();
   }

   /**
    * Disconnects from the remote ESX server.
    */
   public void disconnect()
   {
      if (this.objConnection != null) {
         this.objConnection.close();
         this.objConnection = null;
      }
   }

   /**
    * Local method that returns the identifying information associated with the
    * VMs on the host, including VMID, name, VMX datastore path, guest OS,
    * version from the remote server.
    *
    * @return String array, each element containing a String array of
    *         information for a VM.
    *
    * @throws ErrorInOperation If remote connection fails.
    */
   public String[][] getVmInfo()
      throws Exception
   {
      Vector<String[]> objVmInfoList = new Vector<String[]>();
      String[] objVmInfo = null;
      try {
         Connection objConnection = this.getSshConnection();
         Map<String, String> objResults = SSHUtil.getRemoteSSHCmdOutput(
            objConnection, "vim-cmd /vmsvc/getallvms");
         String strResults = objResults.get(TestConstants.SSH_OUTPUT_STREAM);
         for (String strOutline : strResults.split("\\n")) {
            objVmInfo = strOutline.split("[\\s][\\s]+");
            if (objVmInfo.length == 0 || objVmInfo[0].equalsIgnoreCase("vmid")) {
               continue;
            }
            objVmInfoList.add(objVmInfo);
         }
      } catch (Exception e) {
         throw new Exception("Unable to retrieve list of VMs: " +
            e.getMessage(), e);
      }

      /*
       * Return the String[][]
       */
      String[][] objResult = new String[objVmInfoList.size()][];
      objVmInfoList.copyInto(objResult);

      return objResult;
   }

   /**
    * Method to get the VM power state in the host
    *
    * @param vmId ID of the VM in the host
    * @return String power state of the VM on the host
    * @throws Exception
    */
   public String getVMStateFromHost(String vmId) throws Exception
   {
      String output = null;
      String command = "vim-cmd vmsvc/get.runtime ";
      command += vmId;
      command += " | grep \"powerState\"";
      output = this.sshCmd(command);
      try {
         output = output.substring(output.indexOf("\"") + 1).trim();
         output = output.substring(0, output.indexOf("\"")).trim();
      } catch (IndexOutOfBoundsException ex) {
         return null;
      }
      return output;
   }

   /**
    * Get the Virtual Machine Identifier for a named VM.
    *
    * @param strVmName
    *           The name of the VM to retrieve the ID for.
    * @return VM identifier
    * @throws ErrorInOperation
    *            If the VM is not found or there is an error calling getVmInfo.
    */
   public String getVmId(String strVmName)
      throws Exception
   {
      String[][] objVmInfoList = this.getVmInfo();
      for (String[] objVmInfo : objVmInfoList) {
         if (objVmInfo.length < 2) {
            continue;
         }
         if (objVmInfo[1].equals(strVmName)) {
            return objVmInfo[0];
         }
      }
      throw new Exception("Couldn't find a registered VM, " + strVmName);
   }

   /**
    * Wait for the named VM to achieve the desired power state
    *
    * @param strVmName VM name.
    * @param eDesiredState PowerState desired
    * @throws ErrorInOperation If unable to execute SSH command
    * @throws ValidationFailure If VMs fail to achieve desired power state.
    */
   public boolean waitForPowerState(String strVmName, VirtualMachinePowerState powerState,
      int timeout)
      throws Exception
   {
      // Get the VM ID
      String strVmId = this.getVmId(strVmName);

      boolean isCorrectPowerState = false;
      int count = 0;
      while (count < timeout) {
         log.info("Waiting " + FTTestConstants.ITERATION_DELAY / 1000
            + " seconds for VM power state " + powerState + ": " + count
            + ", current state = " + this.getVMStateFromHost(strVmId));
         if (this.getVMStateFromHost(strVmId).equals(powerState.value())) {
            isCorrectPowerState = true;
            break;
         }
         count++;
         Thread.sleep(FTTestConstants.ITERATION_DELAY);
      }
      return isCorrectPowerState;

   }

   /**
    * Check the version of ESX or ESXi for the specified host.
    *
    * @param strVersion The version returned from a call to <code>vmware -v</code> on the host
    * @return <code>true</code> if the version matches, else <code>false</code>
    * @throws IOException
    * @throws Exception
    */
   public boolean isVersion(String strVersion)
      throws IOException, Exception
   {
      String strCachedVersion = this.getVersion();
      return strCachedVersion.contains(strVersion);
   }

   /**
    * Get the version of ESX or ESXi for this host. The version information is
    * cached on the first call.
    *
    * @return String version information
    * @throws IOException
    * @throws Exception
    */
   public String getVersion()
      throws IOException, Exception
   {
      if (this.strVersion == null || this.strVersion.isEmpty()) {
         Connection objConn = this.getSshConnection();
         Map<String, String> objResult = SSHUtil.getRemoteSSHCmdOutput(objConn,
            "vmware -v");
         this.strVersion = objResult.get(TestConstants.SSH_OUTPUT_STREAM);
      }
      return this.strVersion;
   }

   /**
    * Method to execute a ssh command on a host
    *
    * @param command to excute on the host
    * @return command output after execution
    * @throws Exception
    */
   public String sshCmd(String command) throws Exception
   {
      String result = null;
      try {
         Connection objConnection = this.getSshConnection();
         result = SSHUtil.getSSHOutputStream(
            objConnection, command);
      } catch (Exception e) {
         throw new Exception("Communication error: " +
            e.getMessage());
      }
      return result;
   }

   /**
    * Method to check if VM is primaryVM or not
    *
    * @param vmId ID of the VM in the host
    * @return true if VM on the host is primary else false
    * @throws Exception
    */
   public boolean isPrimaryVm(String vmId) throws Exception
   {
      String output = null;
      String command = "vim-cmd vmsvc/get.config ";
      String PrimaryRole = "1";
      command += vmId;
      command += " | grep \"role\"";
      output = this.sshCmd(command);
      try {
         output = output.substring(output.indexOf("=") + 1).trim();
         output = output.substring(0, output.indexOf(",")).trim();
      } catch (IndexOutOfBoundsException ex) {
         return false;
      }
      return PrimaryRole.equals(output);
   }

   /**
    * Method to get the VM FT state in the host
    *
    * @param vmId ID of the VM in the host
    * @return String FT state of the VM on the host
    * @throws Exception
    */
   public String getVmFtState(String vmId) throws Exception
   {
      String output = null;
      String command = "vim-cmd vmsvc/get.runtime ";
      command += vmId;
      command += " | grep \"faultToleranceState\"";
      output = this.sshCmd(command);
      try {
         output = output.substring(output.indexOf("\"") + 1).trim();
         output = output.substring(0, output.indexOf("\"")).trim();
      } catch (IndexOutOfBoundsException ex) {
         return null;
      }
      return output;
   }

   /**
    * Method to get the VM VMX path in the host
    *
    * @param vmId ID of the VM in the host
    * @return String VMX path of VM on the host
    * @throws Exception
    */
   public String getVmxPath(String vmId) throws Exception
   {
      String output = null;
      String command = "vim-cmd vmsvc/get.config ";
      command += vmId;
      command += " | grep \"vmPathName\"";
      output = this.sshCmd(command);
      try {
         output = output.substring(output.indexOf("\"") + 1).trim();
         output = output.substring(0, output.indexOf("\"")).trim();
      } catch (IndexOutOfBoundsException ex) {
         return null;
      }
      return output;
   }

   /**
    * Method to wait for primary failover
    *
    * Ported from faulttolerance.FTTestBase in the platform solutions (fvt)
    * repository
    *
    * @param vmName Name of the VM
    * @param secondaryVMX VMX file name for the secondary VM
    * @return boolean true if successful, false otherwise
    * @throws Exception
    */
   public boolean waitForFailover(String vmName,
      String secondaryVMX) throws Exception
   {
      // Get the VM ID
      String strVmId = this.getVmId(vmName);
      boolean failover = false;
      long elapsedTime = 0;
      long startTime = System.currentTimeMillis();
      /* Wait to see if failover occurs */
      while (elapsedTime < FAILOVER_WAIT_MILLISEC) {
         if (this.isPrimaryVm(strVmId)
            && this.getVmxPath(strVmId).equals(secondaryVMX)) {
            failover = true;
            log.info("Failover took " + elapsedTime + " seconds");
            break;
         }
         Thread.sleep(VM_CHECK_INTERVAL_MILLISEC);
         elapsedTime = System.currentTimeMillis() - startTime;
      }
      return failover;
   }

   /**
    * Wait for specified timeout a FT VM to reach the required Faulttolerance
    * state.
    *
    * @param vmName Name of the VM
    * @param ftState The expected FT state
    * @param timeout The number of (5*seconds) to wait
    * @return True if the VM reached the FT state, false otherwise
    * @throws Exception
    */
   public boolean waitForVmFtState(String vmName,
      VirtualMachineFaultToleranceState ftState,
      int timeout)
      throws Exception
   {
      // Get the VM ID
      String strVmId = this.getVmId(vmName);

      boolean isExpectedFtState = false;
      int count = 0;
      while (count < timeout) {
         String actualFTState = this.getVmFtState(strVmId);
         if (actualFTState.equals(ftState.value())) {
            log.info("Found VM in required FT State " + ftState.value());
            isExpectedFtState = true;
            break;
         }
         log.info("Waiting " + FTTestConstants.ITERATION_DELAY / 1000
            + " seconds for VM FT state " + ftState.value() + ": "
            + count + ", current state = " + actualFTState);
         count++;
         ThreadUtil.sleep(FTTestConstants.ITERATION_DELAY);
      }
      return isExpectedFtState;
   }

   /**
    * Wait "n" number of seconds for a host to be reachable
    *
    * @param EsxHost object of the host to ping
    * @param timeout The number of seconds to wait
    * @return True if the host is reachable, false otherwise
    * @throws Exception
    */
   public boolean waitForHostToConnect(EsxHost esxHost, int timeout) throws InterruptedException
   {
      boolean expectedState = false;
      int count = 0;
      Connection sshConn = null;
      while (count < timeout) {
         log.info("Waiting " + timeout + " seconds for host state, Connected: " + count);

         try {
            sshConn = esxHost.getSshConnection();
         } catch (Exception ex) {
            sshConn = null;
         }
         if (sshConn != null) {
            expectedState = true;
            break;
         }
         count++;
         Thread.sleep(FTTestConstants.ITERATION_DELAY);
      }
      return expectedState;
   }
}
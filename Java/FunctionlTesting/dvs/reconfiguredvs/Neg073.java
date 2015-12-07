/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import java.util.Arrays;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DvsOperationBulkFault;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;

/**
 * DESCRIPTION:<br>
 * Modify the uplinks in DVS when host is disconnected and expect that
 * DvsOperationBulkFault is thrown.<br>
 * <br>
 * NOTE : Bug 625917#c10.<br>
 * This is a data driven test and number of up-link ports will be increased or
 * decreased base on "uplink-change" property.<br>
 * <br>
 * SETUP:<br>
 * 1. Create the DVS. with host in it. <br>
 * 2. Now disconnect the host.<br>
 * TEST:<br>
 * 3. Reconfigure DVS to modify the number of up-links ports.<br>
 * 4. Expect that DvsOperationBulkFault is thrown.<br>
 * CLEANUP:<br>
 * 5. Reconnect the host.<br>
 * 6. Destroy the DVS.<br>
 */
public class Neg073 extends TestBase implements IDataDrivenTest
{
   private ManagedObjectReference hostMor;
   private HostConnectSpec hostConnSpec;
   private boolean hostDisconnected;
   private DVSConfigSpec deltaCfg;
   private HostSystem ihs;
   private DistributedVirtualSwitch iDvs;
   private ManagedObjectReference dvsMor;
   boolean done = false;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      final String s = data.getString("uplink-change");
      log.info("uplink change  {}", s);
      final int uplinkChange = data.getInt("uplink-change");
      final Folder iFolder = new Folder(connectAnchor);
      iDvs = new DistributedVirtualSwitch(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      hostMor = ihs.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      dvsMor = iFolder.createDistributedVirtualSwitch(getTestId(), hostMor);
      assertNotNull(dvsMor, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      final DVSConfigInfo dvsCfgInfo = iDvs.getConfig(dvsMor);
      final String cfgVersion = dvsCfgInfo.getConfigVersion();
      final DVSNameArrayUplinkPortPolicy uplinkPortPolicy;
      uplinkPortPolicy = (DVSNameArrayUplinkPortPolicy) dvsCfgInfo.getUplinkPortPolicy();
      final String[] presentUplinks = com.vmware.vcqa.util.TestUtil.vectorToArray(uplinkPortPolicy.getUplinkPortName(), java.lang.String.class);
      log.info("PresentUplinks : {}", Arrays.toString(presentUplinks));
      final int numUplinks = presentUplinks.length + uplinkChange;
      final String[] uplinkPortNames = new String[numUplinks];
      for (int i = 0; i < numUplinks; i++) {
         uplinkPortNames[i] = "uplink" + (i + 1);
      }
      log.info("NewUplinks : {}", Arrays.toString(uplinkPortNames));
      final DVSNameArrayUplinkPortPolicy uplinkPolicy = new DVSNameArrayUplinkPortPolicy();
      uplinkPolicy.getUplinkPortName().clear();
      uplinkPolicy.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
      deltaCfg = new DVSConfigSpec();
      deltaCfg.setConfigVersion(cfgVersion);
      deltaCfg.setUplinkPortPolicy(uplinkPolicy);
      hostConnSpec = ihs.getHostConnectSpec(hostMor);
       hostDisconnected = ihs.disconnectHost(hostMor);
      assertTrue(hostDisconnected, "Disconnected the host",
       "Failed to disconnect the host.");
      return true;
   }

   @Override
   @Test(description = "Modify the uplinks in DVS when host is disconnected "
            + "and expect that DvsOperationBulkFault is thrown.", timeOut = 1000 * 60)
   public void test()
      throws Exception
   {
      try {
         // this task was taking 10 mins to complete when uplinks are reduced.
         iDvs.reconfigure(dvsMor, deltaCfg);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new DvsOperationBulkFault();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (hostDisconnected) {
         status = ihs.reconnectHost(hostMor, hostConnSpec, null);
      }
      if (dvsMor != null) {
         status &= iDvs.destroy(dvsMor);
      }
      Assert.assertTrue(status, "Cleanup failed");
      return status;
   }

   @Factory
   @Parameters( { "dataFile" })
   public Object[] getTests(@Optional("") final String dataFile)
      throws Exception
   {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }

   public String getTestName()
   {
      return getTestId();
   }
}

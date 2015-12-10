/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.querycompatiblehostforexistingdvs;

import java.util.Vector;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.ClusterConfigSpec;
import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.LogUtil;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<br>
 * (Test case for queryCompatibleHostForExistingDvs) <br>
 * TARGET: VC <br>
 * <br>
 * SETUP:<br>
 * 1.Get the Compatible Hosts for given vDs version and move hosts to cluster<BR>
 * 2.Create dvs with valid vDs version<BR>
 * TEST:<br>>
 * 3.Invoke queryCompatibleHostForExistingDvs method by passing container as
 * cluster, recursive as true and valid dvs mor <BR>
 * CLEANUP:<br>
 * 4.Destroy vDs<br>
 */
public class Pos003 extends TestBase implements IDataDrivenTest 
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager dvsManager = null;
   private DistributedVirtualSwitch DVS = null;
   private ManagedObjectReference dvsManagerMor = null;
   private Folder folder = null;
   private HostSystem hostSystem = null;
   private ManagedObjectReference[] allHosts = null;
   private DistributedVirtualSwitchProductSpec productSpec = null;
   private ManagedObjectReference dvsMor = null;
   private String newVdsVersion = null;
   private ManagedObjectReference clusterMor = null;
   private ManagedObjectReference hostFolderMor = null;
   private ManagedObjectReference dcMor = null;
   private boolean moved = false;
   private ClusterComputeResource clusterComputeResource = null;
   private final int TIMEOUT_MULTIPLIER = 3;

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    *
    * @throws Exception
    */
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("")String dataFile) throws Exception {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }
   public String getTestName()
   {
      return getTestId();
   }

   public void setTestDescription()
   {
      setTestDescription("1.Get the compatible hosts for given vDs version and move hosts to cluster"
               + "2. Create dvs with given vDs version\n"
               + "3.Invoke queryCompatibleHostForExistingDvs  method by "
               + "passing container as cluster, recursive as true and"
               + " valid dvs mor");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      DVSCreateSpec createSpec = null;
      ClusterConfigSpec clusterSpec = null;
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      folder = new Folder(connectAnchor);
      hostSystem = new HostSystem(connectAnchor);
      clusterComputeResource = new ClusterComputeResource(connectAnchor);
      DVS = new DistributedVirtualSwitch(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      newVdsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      log.info(DVSTestConstants.NEW_VDS_VERSION + newVdsVersion);
      productSpec = DVSUtil.getProductSpec(connectAnchor, newVdsVersion);
      /*
       * Move two hosts to cluster
       */
      dcMor = folder.getDataCenter();
      hostFolderMor = folder.getHostFolder(dcMor);
      clusterSpec = folder.createClusterSpec();
      clusterMor =
               folder.createCluster(hostFolderMor, getTestId() + "-cluster",
                        clusterSpec);
      allHosts =
               dvsManager.queryCompatibleHostForNewDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, productSpec);
      assertNotNull(allHosts, "Found compatible host for "
               + DVSTestConstants.NEW_VDS_VERSION,
               " Unable to find compatible host for "
                        + DVSTestConstants.NEW_VDS_VERSION);
      assertTrue(clusterComputeResource.moveInto(clusterMor, allHosts),
               "hosts  moved successfully ",
               "Unable to move the hosts to cluster");
      moved=true;
      createSpec =
               DVSUtil.createDVSCreateSpec(DVSUtil
                        .createDefaultDVSConfigSpec(null), productSpec, null);
      dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      return true;
   }

   @Test(description = "1.Get the compatible hosts for given vDs version and move hosts to cluster"
               + "2. Create dvs with given vDs version\n"
               + "3.Invoke queryCompatibleHostForExistingDvs  method by "
               + "passing container as cluster, recursive as true and"
               + " valid dvs mor")
   public void test()
      throws Exception
   {
      ManagedObjectReference[] hosts =
               this.dvsManager.queryCompatibleHostForExistingDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, this.dvsMor);
      Assert.assertTrue(TestUtil.compareArray(hosts, allHosts),
               " Successfully verified"
                        + " the compatible host for an existing DVS",
               "Test to verify compatible host for an existing DVS");
   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      if (this.dvsMor != null) {
         assertTrue(this.DVS.destroy(this.dvsMor),
                  "dvsMor destroyed successfully",
                  "dvsMor could not be removed");
      }
      if (moved) {
         /*
          * reset the hosts back
          */
         hostFolderMor = folder.getHostFolder(dcMor);
         VirtualMachine ivm = new VirtualMachine(connectAnchor);
         ivm.powerOffVMs(ivm.getAllVM());
         try {
             hostSystem.enterMaintenanceModes(TestUtil.arrayToVector(allHosts),
                 TestConstants.ENTERMAINTENANCEMODE_TIMEOUT
                 * TIMEOUT_MULTIPLIER, false);
             assertTrue((folder.moveInto(hostFolderMor, allHosts)),
                 "Moved hosts  successfully", " Move hosts failed ");
         } catch (Exception e) {
             log.error("Unable to enter MT mode or enter MT mode timeout!");
         } finally {
             try {
                 hostSystem.exitMaintenanceModes(TestUtil.arrayToVector(allHosts),
                     TestConstants.EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS);
             } catch (Exception e) {
                 log.error("Unable to exit MT mode or currently not in MT mode!");
             } finally {
                 assertTrue((folder.destroy(clusterMor)),
                     "Successfully destroyed cluster",
                     "Unable to  destroy cluster");
             }
         }
      }
      return true;
   }
}

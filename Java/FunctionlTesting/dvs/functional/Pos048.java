package dvs.functional;

import java.util.Vector;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ClusterAttemptedVmInfo;
import com.vmware.vc.ClusterConfigSpecEx;
import com.vmware.vc.ClusterDrsFaults;
import com.vmware.vc.ClusterDrsFaultsFaultsByVm;
import com.vmware.vc.ClusterNotAttemptedVmInfo;
import com.vmware.vc.ClusterPowerOnVmResult;
import com.vmware.vc.DrsBehavior;
import com.vmware.vc.HostProxySwitch;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;

/**
 * 2 Standalone host. 3 VMs per host. Bug #424097 - CISCO DVS Port use case. In
 * a DRS Cluster with two hosts, 3 VMs each. Set a Max Port on DVS per host,
 * such that only two VMs can be powered on. So that in total only 4 VMs can be
 * powered on in Cluster. 2VMs per host. Usecase #1 Datacenter Power On 6 VMs.
 * Four VMs should power on and Two VMs should fail. Usecase #2 Assuming HostB
 * has no free port, Enter Maintenance mode on HosttA should raise DRS Fault.
 */
public class Pos048 extends FunctionalDRSTestBase
{
   @Override
   public void setTestDescription()
   {
      setTestDescription("CISCO use case - DVS MaxProxyPort should be consider by DRS.");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
	   log.info("Setup begain: ");
      boolean setUpDone = false;
     
         Assert.assertTrue(super.testSetUp(), "Setup super success","Setup Failed");
         ClusterConfigSpecEx clusterSpecEx = iFolder.createClusterConfigSpecEx();
         log.info("after configspec");
         clusterMor = iFolder.createClusterEx(hostFolderMor, getTestId(),
                  clusterSpecEx);
         Assert.assertNotNull(clusterMor, "Created Cluster "
                  + icr.getName(clusterMor), "Failed to create Cluster.");
         Assert.assertTrue(icr.moveInto(clusterMor,
                  allHosts.toArray(new ManagedObjectReference[0])),
                  "Moved hosts into cluster " + icr.getName(clusterMor),
                  "Failed to move hosts into cluster "
                           + icr.getName(clusterMor));
         Assert.assertTrue(icr.setDRS(clusterMor, true, DrsBehavior.FULLY_AUTOMATED), "Enabled DRS on cluster",
                  "Failed to enable DRS on cluster");
         setUpDone = true;
     
      Assert.assertTrue(setUpDone, "Setup failed");
      return setUpDone;
   }

   /**
	 *
	 */
   @Override
   @Test(description = "CISCO use case - DVS MaxProxyPort should be consider by DRS.")
   public void test()
      throws Exception
   {
	   log.info("Test begain: ");
      boolean testDone = false;
     
         int totalVMsToBePoweredOn = 0;
         for (ManagedObjectReference hostMor : ihs.getAllHost()) {
            int vmsPerHost = getNumPortsAvailable(hostMor);
            totalVMsToBePoweredOn += vmsPerHost;
            log.info("Num Of VMs could be Powered on "
                     + ihs.getHostName(hostMor) + " : " + vmsPerHost);
            Assert.assertTrue(vmsPerHost > 0 && vmsPerHost <= MAX_PORTS,
                     "Number of Available Ports is with in expected Range.",
                     "Number of Available Ports is not within expected Range.");
         }
         log.info("Total Number Of VMs could be Powered on Cluster : "
                  + totalVMsToBePoweredOn);
         Assert.assertTrue(totalVMsToBePoweredOn < ivm.getAllVM().size(),
                  "VMs could be powered on " + totalVMsToBePoweredOn
                           + " is lesser than the total number of VMs "
                           + ivm.getAllVM().size(),
                  "VMs could be powered on is not lesser than total number of VMs in inventory.");
         ClusterPowerOnVmResult powerOnVMResult = dc.powerOnVm(dcMor,
                  ivm.getAllVM().toArray(new ManagedObjectReference[0]));
         Thread.sleep(45 * 1000);
         for (ManagedObjectReference hostMor : icr.getHosts(clusterMor)) {
            int portno = getNumPortsAvailable(hostMor);
            int itr = 0;
            while (itr < 24) {
               if (portno == 0) {
                  log.info("numAvailablePort is 0 as expected on "
                           + ihs.getHostName(hostMor));
                  break;
               } else {
                  log.warn("numAvailablePort is not 0 as expected on "
                           + ihs.getHostName(hostMor));
                  portno = getNumPortsAvailable(hostMor);
                  log.info("Sleeping for 10000 msec");
                  Thread.sleep(10000);
               }
               itr++;
            }
            Assert.assertTrue(getNumPortsAvailable(hostMor) == 0,
                     "numAvailablePort is 0 as expected on "
                              + ihs.getHostName(hostMor),
                     "numAvailablePort is not 0 as expected on "
                              + ihs.getHostName(hostMor));
         }
         ClusterAttemptedVmInfo[] vmsPoweredOnPassList = com.vmware.vcqa.util.TestUtil.vectorToArray(powerOnVMResult.getAttempted(), com.vmware.vc.ClusterAttemptedVmInfo.class);
         ClusterNotAttemptedVmInfo[] vmsPoweredOnFailedList = com.vmware.vcqa.util.TestUtil.vectorToArray(powerOnVMResult.getNotAttempted(), com.vmware.vc.ClusterNotAttemptedVmInfo.class);
         log.info("Total VMs, Powered On Passed : "
                  + vmsPoweredOnPassList.length);
         log.info("Total VMs, Powered On Failed : "
                  + vmsPoweredOnFailedList.length);
         Assert.assertTrue(totalVMsToBePoweredOn == vmsPoweredOnPassList.length
                  && vmsPoweredOnFailedList.length == ivm.getAllVM().size()
                           - totalVMsToBePoweredOn,
                  "Number of PoweredOn VM count is expected.",
                  "Number of PoweredOn VM count is not as expected.");
         ManagedObjectReference clHostMor1 = icr.getHosts(clusterMor).elementAt(
                  0);
         ManagedObjectReference clHostMor2 = icr.getHosts(clusterMor).elementAt(
                  1);
         log.info("Put " + ihs.getHostName(clHostMor1)
                  + " into Maintenance mode.");
         Assert.assertTrue(ivm.setVMState(ihs.getVMs(clHostMor2,
                           VirtualMachinePowerState.POWERED_ON).elementAt(0), VirtualMachinePowerState.POWERED_OFF, false),
                  "Failed to Power off VM on " + ihs.getName(clHostMor2));
         int portno = getNumPortsAvailable(clHostMor2);
         int itr = 0;
         while (itr < 24) {
            if (portno == 1) {
               log.info("numAvailablePort is 1 as expected on "
                        + ihs.getHostName(clHostMor2));
               break;
            } else {
               log.warn("numAvailablePort is not 1 as expected on "
                        + ihs.getHostName(clHostMor2));
               portno = getNumPortsAvailable(clHostMor2);
               log.info("Sleeping for 10000 msec");
               Thread.sleep(10000);
            }
            itr++;
         }
         Assert.assertTrue(getNumPortsAvailable(clHostMor2) == 1,
                  "numAvailablePort is 1 as expected on "
                           + ihs.getHostName(clHostMor2),
                  "numAvailablePort is not 1 as expected on "
                           + ihs.getHostName(clHostMor2));
         ManagedObjectReference enterMaintTask = ihs.asyncEnterMaintenanceMode(
                  clHostMor1, 0, false);
         Thread.sleep(45 * 1000);
         Vector<ClusterDrsFaults> drsFaults = icr.getDrsFaults(clusterMor);
         Assert.assertTrue(drsFaults != null && drsFaults.size() > 0,
                  "Drs Fault raised.", "Drs Fault not raised.");
         for (ClusterDrsFaults drsFault : drsFaults) {
            ClusterDrsFaultsFaultsByVm[] vmFaults = com.vmware.vcqa.util.TestUtil.vectorToArray(drsFault.getFaultsByVm(), com.vmware.vc.ClusterDrsFaultsFaultsByVm.class);
            Assert.assertTrue(vmFaults != null && vmFaults.length > 0,
                     "No Fault raised for VM.");
            log.info(com.vmware.vcqa.util.TestUtil.vectorToArray(vmFaults[0].getFault(), com.vmware.vc.LocalizedMethodFault.class)[0].getLocalizedMessage());
         }
         if (enterMaintTask != null) {
            Assert.assertTrue(iTask.cancelActiveTask(enterMaintTask),
                     "Cancelled enterMaintenance mode task.",
                     "Failed to cancel enter Maintenance mode Task.");
         }
         testDone = true;
     

   }

   private int getNumPortsAvailable(ManagedObjectReference hostMor)
      throws Exception
   {
      String hostName = ihs.getHostName(hostMor);
      ManagedObjectReference hostNetworkSystem = ihs.getHostConfigManager(
               hostMor).getNetworkSystem();
      HostProxySwitch[] hostProxySwitchList = com.vmware.vcqa.util.TestUtil.vectorToArray(ins.getNetworkInfo(
                        hostNetworkSystem).getProxySwitch(), com.vmware.vc.HostProxySwitch.class);
      log.info(hostName + " numPorts : "
               + hostProxySwitchList[0].getNumPorts());
      log.info(hostName + " numPortsAvailable : "
               + hostProxySwitchList[0].getNumPortsAvailable());
      return hostProxySwitchList[0].getNumPortsAvailable();
   }
}

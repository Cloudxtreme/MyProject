package dvs.nrp.updatenetiorm;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.HostConfigSpec;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.SharesLevel;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;
import com.vmware.vcqa.vim.profile.ProfileConstants;

/**
 * Configure a NRP with limit as 0 or a negative value(-2) other than -1 as
 * Limit for a Resource pool
 */
public class Neg009 extends TestBase
{
   private DistributedVirtualSwitch idvs;
   private Folder ifolder;
   private HostSystem ihs;
   private ManagedObjectReference dvsMor;
   private HashMap<ManagedObjectReference, HostSystemInformation> hostMors;
   private ManagedObjectReference hostMor1;
   private ManagedObjectReference hostMor2;
   private HostConfigSpec srcHostProfile1;
   private HostConfigSpec srcHostProfile2;
   private Vector<DVSNetworkResourcePoolConfigSpec> configSpecList = new Vector<DVSNetworkResourcePoolConfigSpec>(
            2);
   private Vector<DVSNetworkResourcePool> nrps = new Vector<DVSNetworkResourcePool>(
            2);

   /**
    * Test method
    */
   @Override
   @Test(description = "Configure a NRP with limit as  0 or a negative value"
               + "(-2) other than -1 as Limit for a Resource pool")
   public void test()
      throws Exception
   {
      try {
         boolean status = false;
         DVSNetworkResourcePoolConfigSpec spec = null;
         try {
            spec = configSpecList.firstElement();
            log.info("Checking for LIMIT value : "
                     + spec.getAllocationInfo().getLimit());
            NetworkResourcePoolHelper.testNrp(connectAnchor, dvsMor,
                     new ManagedObjectReference[] { hostMor1, hostMor2 },
                     new DVSNetworkResourcePool[] { nrps.firstElement() },
                     new DVSNetworkResourcePoolConfigSpec[] { spec });

         } catch (Exception actualMethodFaultExcep) {
            MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
            InvalidArgument expectedMethodFault = new InvalidArgument();
            status = TestUtil.checkMethodFault(actualMethodFault,
                     expectedMethodFault);
         }
         if (status) {
            spec = configSpecList.lastElement();
            log.info("Checking for LIMIT value : "
                     + spec.getAllocationInfo().getLimit());
            NetworkResourcePoolHelper.testNrp(connectAnchor, dvsMor,
                     new ManagedObjectReference[] { hostMor1, hostMor2 },
                     new DVSNetworkResourcePool[] { nrps.lastElement() },
                     new DVSNetworkResourcePoolConfigSpec[] { spec });
         } else {
            Assert.assertTrue(status,
                     "User should not be allowed to enter 0 or a negative value(-2)"
                              + " other than -1 as Limit for a Resource pool");
         }
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidArgument();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }

   }

   /**
    * Cleanup method Destroy the dvs
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      // delete the dvs
      NetworkResourcePoolHelper.restoreHosts(
               connectAnchor,
               new HostConfigSpec[] { srcHostProfile1, srcHostProfile2 },
               new ManagedObjectReference[] { hostMor1, hostMor2 });

      Assert.assertTrue(idvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      ifolder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);
      ihs = new HostSystem(connectAnchor);

      // get a standalone hostmors
      // We need at at least 2 hostmors
      hostMors = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);

      Assert.assertTrue(hostMors.size() >= 2, "Unable to find two hosts");

      Set<ManagedObjectReference> hostSet = hostMors.keySet();
      Iterator<ManagedObjectReference> hostIterator = hostSet.iterator();
      if (hostIterator.hasNext()) {
         hostMor1 = hostIterator.next();
         srcHostProfile1 = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId(),
                  hostMor1);
      }
      if (hostIterator.hasNext()) {
         hostMor2 = hostIterator.next();
         srcHostProfile2 = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId()
                           + "-1", hostMor2);
      }

      // create the dvs
      dvsMor = ifolder.createDistributedVirtualSwitch(
               DVSTestConstants.DVS_CREATE_NAME_PREFIX + getTestId(),
               DVSTestConstants.VDS_VERSION_41);
      Assert.assertNotNull(dvsMor, "DVS created", "DVS not created");

      Assert.assertNotNull(idvs.addPortGroup(dvsMor,
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 4,
               DVSTestConstants.DV_PORTGROUP_CREATE_NAME_PREFIX + getTestId()),
               "Unable to add portgroup");

      // enable netiorm
      Assert.assertTrue(idvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");

      // Extract the network resource pool related to the vm from the dvs
      nrps.add(idvs.extractNetworkResourcePool(dvsMor, DVSTestConstants.NRP_VM));
      // Extract the network resource pool related to the nfs from the dvs
      nrps.add(idvs.extractNetworkResourcePool(dvsMor, DVSTestConstants.NRP_NFS));
      setNrpConfigSpec(new int[] { 0, -2 });
      return true;
   }

   /**
    * Set up the nrp config spec
    */
   private void setNrpConfigSpec(int[] values)
   {
      for (int i = 0; i < 2; i++) {
         DVSNetworkResourcePool nrp = nrps.get(i);
         DVSNetworkResourcePoolConfigSpec nrpConfigSpec = new DVSNetworkResourcePoolConfigSpec();
         nrpConfigSpec.setKey(nrp.getKey());
         nrpConfigSpec.setAllocationInfo(nrp.getAllocationInfo());
         nrpConfigSpec.getAllocationInfo().setLimit(new Long(values[i]));
         nrpConfigSpec.getAllocationInfo().getShares().setLevel(
                  SharesLevel.HIGH);
         configSpecList.add(nrpConfigSpec);
      }

   }

   /**
    * Test Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Configure a NRP with limit as  0 or a negative value"
               + "(-2) other than -1 as Limit for a Resource pool");
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new InvalidArgument();
   }

}

package dvs.nrp.updatenetiorm;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.HostApplyProfile;
import com.vmware.vc.HostConfigInfo;
import com.vmware.vc.HostConfigSpec;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostPortGroupProfile;
import com.vmware.vc.HostProfileConfigInfo;
import com.vmware.vc.HostProfileHostBasedConfigSpec;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.SharesLevel;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;
import com.vmware.vcqa.vim.profile.ProfileConstants;
import com.vmware.vcqa.vim.profile.host.HostProfile;
import com.vmware.vcqa.vim.profile.host.ProfileManager;
import com.vmware.vcqa.vim.profile.host.ProfileManagerUtil;

public class Pos019 extends TestBase
{
   private DistributedVirtualSwitch idvs;
   private Folder ifolder;
   private HostSystem ihs;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;
   private HashMap<ManagedObjectReference, HostSystemInformation> hostMors;
   private ManagedObjectReference hostMor;
   private HostConfigSpec srcHostProfile;


   /**
    * Test method
    */
   @Override
   @Test(description = "Configure a invalid IPv6 address to hostprofile")
   public void test()
      throws Exception
   {
     
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
               new HostConfigSpec[] { srcHostProfile },
               new ManagedObjectReference[] { hostMor });

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

      hostMors = null;
      hostMors = ihs.getAllHosts(VersionConstants.ALL_ESX, HostSystemConnectionState.CONNECTED);
      if(hostMors == null){
    	  log.info("There is no host connected");
    	  return false;
      }
      
      Set<ManagedObjectReference> hostSet = hostMors.keySet();
      Iterator<ManagedObjectReference> hostIterator = hostSet.iterator();
      if (hostIterator.hasNext()) {
         hostMor = hostIterator.next();
         this.srcHostProfile  = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId(),
                  hostMor);
      
         NetworkResourcePoolHelper.extractProfile(connectAnchor, ProfileConstants.SRC_PROFILE + getTestId()+"2",
              hostMor);
      }
      return true;
   }

   /**
    * Configure an invalid IPv6 address to hostprofile
    */
   /*
   private void setInvalidIPv6Addr()
		   throws Exception
   {
	  ProfileManager hostProfileManager = new ProfileManager(connectAnchor);
	  ProfileManagerUtil util = new ProfileManagerUtil(connectAnchor);
	  ManagedObjectReference hostProfileManagerMor = hostProfileManager.getHostProfileManager();

	  HostProfile profile = new HostProfile(connectAnchor);
	  HostSystem ihs = new HostSystem(connectAnchor);
	  HostConfigInfo configInfo = ihs.getHostConfig(hostMor);
	  HostNetworkInfo networkInfo = configInfo.getNetwork();
	  
	  HostNetworkConfig hostNetworkConf = srcHostProfile.getNetwork();

	  
	  
      com.vmware.vcqa.util.Assert.assertNotNull(srcHostProfileMor,
              "src host Profile Mor is null");
	  
	  HostProfileConfigInfo info = (HostProfileConfigInfo) profile.getConfigInfo(srcHostProfileMor);
      HostApplyProfile applyProfile = info.getApplyProfile();
	  
	  HostPortGroupProfile[] hostPortgroupProfiles = com.vmware.vcqa.util.TestUtil.vectorToArray(applyProfile.getNetwork().getHostPortGroup(), com.vmware.vc.HostPortGroupProfile.class);
      HostVirtualNic[] vnics = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class);
      if (vnics != null) {            for (HostVirtualNic hostVirtualNic : vnics) {
          // check if the vmkernel profile name matches the
          // consolenic.portgroup property
          if (hostPortgroupProfile.getName().equals(
                   hostVirtualNic.getPortgroup())) {
             HashMap<String, Object> map = new HashMap<String, Object>();
             if (hostVirtualNic.getSpec().getIp().isDhcp()) {
                util.setPolicy(hostProfileManagerMor,
                         com.vmware.vcqa.util.TestUtil.vectorToArray(hostPortgroupProfile.getIpConfig().getPolicy(), com.vmware.vc.ProfilePolicy.class),
                         ProfileConstants.IPADDRESSPOLICY,
                         ProfileConstants.FIXEDDHCPOPTION, map, true, srcHostProfileMor);
             } else {
                map.put(ProfileConstants.ADDRESS,
                         hostVirtualNic.getSpec().getIp().getIpAddress());
                map.put(ProfileConstants.SUBNET_MASK,
                         hostVirtualNic.getSpec().getIp().getSubnetMask());
                util.setPolicy(hostProfileManagerMor,
                         com.vmware.vcqa.util.TestUtil.vectorToArray(hostPortgroupProfile.getIpConfig().getPolicy(), com.vmware.vc.ProfilePolicy.class),
                         ProfileConstants.IPADDRESSPOLICY,
                         ProfileConstants.FIXEDIPCONFIG, map, true, srcHostProfileMor);
             }
             break;
          }
       }
    }
 
   }
*/
   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Configure a NRP for vm traffic");
   }

   
   
}
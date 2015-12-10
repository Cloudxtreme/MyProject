/*
 * ************************************************************************
 *
 * Copyright 2011 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.HostConfigChangeOperation;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * DESCRIPTION:<br>
 * TARGET: VC <br>
 * NOTE : PR#456609 <br>
 * <br>
 * SETUP:<br>
 * 1. Create a distributed switch associating with host
 * 2. Two vmnics of the host are added to the vDS. For example vmnic2 is connected to dvUplink1 and vmnic3 is connected
 * to dvUplink3 <br>
 * 
 * TEST:<br>
 * 3. Attach connection cookie with physical nics while adding them to uplinks <br>
 * 4. Remove physical nics from the uplink portgroup associated with an
		 uplink portkey  <br>
 * 5. Swap uplinkportKey and pNic device and check whether the
		connectionCookie is reset to null <br>
 * 
 * CLEANUP:<br>
 * 6. Remove host from VDs 7. Destroy vDs<br>
 */

public class Pos070 extends TestBase
{

	private HostSystem ihs = null;
	private HostProxySwitchConfig proxySwConfig = null;
	private NetworkSystem ins = null;
	private DistributedVirtualSwitch idvs = null;
	private DistributedVirtualPortgroup idvpg = null;
	private HostNetworkConfig hostNetConfig = null;
	private Map<String, String> dvsNicsUplinks = new HashMap<String, String>();
	private ManagedObjectReference hostMor = null;
	private ManagedObjectReference dvsMor = null;
	private ManagedObjectReference nsMor = null;
	private Folder folder = null;
	private String dvsName = null;
	private String portGroupKey = null;

	/**
	 * Method to set up the Environment for the test.
	 * 
	 * @return Return true, if test set up was successful false, if test set up
	 *         was not successful
	 * @throws Exception
	 */

	@BeforeMethod(alwaysRun = true)
	public boolean testSetUp() throws Exception
	{
		this.ihs = new HostSystem(connectAnchor);
		this.folder = new Folder(connectAnchor);
		this.idvs = new DistributedVirtualSwitch(connectAnchor);
		this.idvpg = new DistributedVirtualPortgroup(connectAnchor);
		ins = new NetworkSystem(connectAnchor);
		hostNetConfig = new HostNetworkConfig();
		DVSConfigSpec configSpec = new DVSConfigSpec();
		hostMor = ihs.getConnectedHost(false);
		Assert.assertNotNull(hostMor, "Failed to get a connected host");
		nsMor = ins.getNetworkSystem(hostMor);

		/**
		 * Create a distributed switch associating with host
		 */
		dvsName = TestUtil.getShortTime() + "_DVS";
		DistributedVirtualSwitchHostMemberConfigSpec hostMemberConfigSpec0 = new DistributedVirtualSwitchHostMemberConfigSpec();
		hostMemberConfigSpec0.setHost(hostMor);
		hostMemberConfigSpec0.setOperation(TestConstants.CONFIG_SPEC_ADD);
		configSpec.getHost().clear();
      configSpec.getHost()
				.addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMemberConfigSpec0 }));
		configSpec.setName(dvsName);
		configSpec.setConfigVersion("");
		dvsMor = folder.createDistributedVirtualSwitch(folder
				.getNetworkFolder(folder.getDataCenter()), configSpec);
		Assert.assertNotNull(dvsMor, "Failed to create DVS switch");

		/**
		 * Attach nics to uplinks with connectionCookie and update the network
		 * config
		 */

		proxySwConfig = idvs.getDVSVswitchProxyOnHost(dvsMor, hostMor);
		Assert.assertNotNull(proxySwConfig,
				"Failed to get the proxy switch config");
		String[] pNicDevices = ins.getPNicIds(hostMor, false);
		Assert.assertNotNull(pNicDevices, "Failed to get free Physical nics");
		Vector<DistributedVirtualSwitchHostMemberPnicSpec> pNicSpecsVector = new Vector<DistributedVirtualSwitchHostMemberPnicSpec>();
		List<ManagedObjectReference> uplinkPortGrps = idvs
				.getUplinkPortgroups(dvsMor);
		List<String> portKeys = idvpg.getPortKeys(uplinkPortGrps.get(0));
		String portGroupKey = idvpg.getKey(uplinkPortGrps.get(0));
		log.info("Got the PortGroupKey ->" + portGroupKey);
		DistributedVirtualSwitchHostMemberPnicSpec[] pNicSpecs = new DistributedVirtualSwitchHostMemberPnicSpec[pNicDevices.length];
		for (int i = 0; i < pNicSpecs.length; i++)
		{
			if (i < portKeys.size())
			{
				pNicSpecs[i] = new DistributedVirtualSwitchHostMemberPnicSpec();
				pNicSpecs[i].setPnicDevice(pNicDevices[i]);
				pNicSpecs[i].setUplinkPortgroupKey(portGroupKey);
				pNicSpecs[i].setUplinkPortKey(portKeys.get(i));
				pNicSpecs[i].setConnectionCookie(100 + i);
				dvsNicsUplinks.put(pNicDevices[i], portKeys.get(i));
				pNicSpecsVector.add(pNicSpecs[i]);
			} else
			{
				break;
			}
		}

		DistributedVirtualSwitchHostMemberPnicBacking pNicBaking0 = (DistributedVirtualSwitchHostMemberPnicBacking) proxySwConfig
				.getSpec().getBacking();
		pNicBaking0.getPnicSpec().clear();
      pNicBaking0.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(pNicSpecsVector
				.toArray(new DistributedVirtualSwitchHostMemberPnicSpec[] {})));
		proxySwConfig.getSpec().setBacking(pNicBaking0);
		proxySwConfig.setChangeOperation(HostConfigChangeOperation.EDIT.value());
		hostNetConfig.getProxySwitch().clear();
      hostNetConfig.getProxySwitch()
				.addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { proxySwConfig }));
		assertTrue(ins.updateNetworkConfig(nsMor, hostNetConfig,
				TestConstants.CHANGEMODE_MODIFY), "failed");

		/**
		 * Existing Connection cookiee
		 */
		confirmConnectionCookie();

		return true;
	}

	/**
	 * Method where the test logic is implemented .This method will be called
	 * only if testSetup is completed successfully.
	 * 
	 */

	@Test(description = "This Test will address SR bug 456609")
	public void test() throws Exception
	{

		/**
		 * Remove physical nics from the uplink portgroup associated with an
		 * uplink portkey
		 */
		String[] dvsAttachedNics = dvsNicsUplinks.keySet().toArray(
				new String[] {});

		String[] nicToRemove = { dvsAttachedNics[dvsAttachedNics.length - 1],
				dvsAttachedNics[dvsAttachedNics.length - 2] };

		List<String> nicRemovedUplkPortkeys = new ArrayList<String>();
		for (int j = 0; j < nicToRemove.length; j++)
			nicRemovedUplkPortkeys.add(dvsNicsUplinks.get(nicToRemove[j]));

		HostNetworkConfig netConfig = idvs.unbindPnicsFromDVS(dvsMor, hostMor,
				nsMor, proxySwConfig, nicToRemove);

		assertTrue(ins.updateNetworkConfig(nsMor, netConfig,
				TestConstants.CHANGEMODE_MODIFY), "failed");

		confirmConnectionCookie();

		/**
		 * Swap uplinkportKey and pNic device and check whether the
		 * connectionCookie is reset to a new value or not
		 */

		DistributedVirtualSwitchHostMemberPnicBacking pNicBaking2 = (DistributedVirtualSwitchHostMemberPnicBacking) proxySwConfig
				.getSpec().getBacking();
		DistributedVirtualSwitchHostMemberPnicSpec[] pNicSpecs1 = new DistributedVirtualSwitchHostMemberPnicSpec[nicToRemove.length];

		for (int i = 0; i < pNicSpecs1.length; i++)
		{
			pNicSpecs1[i] = new DistributedVirtualSwitchHostMemberPnicSpec();
			pNicSpecs1[i].setPnicDevice(nicToRemove[i]);
			pNicSpecs1[i].setUplinkPortgroupKey(portGroupKey);
			pNicSpecs1[i].setUplinkPortKey(nicRemovedUplkPortkeys.get(1 - i));
			pNicBaking2.getPnicSpec().add(pNicSpecs1[i]);
		}
		proxySwConfig.getSpec().setBacking(pNicBaking2);
		proxySwConfig.setChangeOperation(HostConfigChangeOperation.EDIT.value());
		hostNetConfig.getProxySwitch().clear();
      hostNetConfig.getProxySwitch()
				.addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { proxySwConfig }));
		assertTrue(ins.updateNetworkConfig(nsMor, hostNetConfig,
				TestConstants.CHANGEMODE_MODIFY), "failed");
		confirmConnectionCookie();

		DistributedVirtualSwitchHostMemberPnicBacking pnicBacking3 = (DistributedVirtualSwitchHostMemberPnicBacking) proxySwConfig
				.getSpec().getBacking();
		/**
		 * Check to address whether the connection cookie has been reset
		 */

		for (DistributedVirtualSwitchHostMemberPnicSpec nicSpec : Arrays
				.asList(com.vmware.vcqa.util.TestUtil.vectorToArray(pnicBacking3.getPnicSpec(), com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec.class)))
		{
			if (Arrays.asList(nicToRemove).contains(nicSpec.getPnicDevice()))
			{
				Assert.assertNull(nicSpec.getConnectionCookie());
			}
		}

	}

	/**
	 * Method to restore the state, as it was, before setting up the test
	 * environment.
	 * 
	 * @return true, if test clean up was successful false, otherwise
	 * @throws Exception
	 */

	@AfterMethod(alwaysRun = true)
	public boolean testCleanUp() throws Exception
	{
		Assert.assertTrue(DVSUtil.removeHostFromDVS(connectAnchor, hostMor,
				dvsMor), "Could not remove Host from DVS");
		Assert.assertTrue(idvs.destroy(dvsMor), "Failed to remove DVS from VC");
		return true;
	}

	/**
	 * Method which helps in displaying the connection cookie information.
	 */

	public void confirmConnectionCookie() throws Exception
	{

		DistributedVirtualSwitchHostMemberPnicBacking pnicBacking2 = (DistributedVirtualSwitchHostMemberPnicBacking) proxySwConfig
				.getSpec().getBacking();
		for (DistributedVirtualSwitchHostMemberPnicSpec nicSpec : com.vmware.vcqa.util.TestUtil
				.vectorToArray(pnicBacking2.getPnicSpec(), com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec.class))
		{
			log.info("Physical Nic " + nicSpec.getPnicDevice()
					+ " has UplinkportKey ->" + nicSpec.getUplinkPortKey());
			if (nicSpec.getConnectionCookie() == null)
			{

				log.info("Physical Nic " + nicSpec.getPnicDevice()
						+ " has connectionCookie resetted  as expected");
			} else
			{
				log.info("Physical Nic " + nicSpec.getPnicDevice()
						+ " has connectionCookie ->"
						+ nicSpec.getConnectionCookie().toString());

			}

		}

	}

}

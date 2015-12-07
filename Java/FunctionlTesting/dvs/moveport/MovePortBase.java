/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import java.util.ArrayList;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * This class is the base class for all the move port test cases. All the
 * necessary interfaces like iDVSwitch,iFolder are initialized to respective
 * implementations using factory so the they can be used directly in the tests.
 * The common methods like movePort, fetchPortKeys etc are handy and can be
 * directly called in the tests which helps us to concentrate on functional
 * aspects in tests. dvsMor,portKeys and portgroupKey are the protected members
 * which are use in all the test cases.
 */
public abstract class MovePortBase extends TestBase
{
   /* * CONSTANTS * */
   /** Represents default number ports */
   public static final int DEFAULT_NUM_PORT = 1;
   /** a counter used while creating DVPortgroups. */
   private static volatile int count = 0;
   /* * INSTANCE VARIABLES * */
   protected DistributedVirtualSwitch iDVSwitch;
   protected DistributedVirtualPortgroup iDVPortGroup;
   protected Folder iFolder;
   protected VirtualMachine ivm;
   protected ManagedEntity iManagedEntity;
   protected HostSystem ihs;
   protected NetworkSystem ins;
   /* DVS MOR used in tests. */
   protected ManagedObjectReference dvsMor;
   protected ManagedObjectReference hostMor;
   protected String dvsName;
   /** port keys of the ports to be moved. */
   protected List<String> portKeys;
   /** The destination port group key */
   protected String portgroupKey;
   /** Prefix used for names used. */
   protected String prefix;

   /**
    * Get the port keys based on the port criteria passed.
    * 
    * @param dvsMor DVS MOR.
    * @param portgroupKey Given DVPortgroup key.
    * @return List<String> List containing port keys of the DVSwitch.
    * @throws MethodFault If any API error occurs.
    * @throws Exception on any other errors.
    */
   public List<String> fetchPortKeys(ManagedObjectReference dvsMor,
                                     String portgroupKey)
      throws Exception
   {
      log.info("Getting DVPorts from DVPortgroup: " + portgroupKey);
      DistributedVirtualSwitchPortCriteria portCriteria = iDVSwitch.getPortCriteria(
               null, null, null, new String[] { portgroupKey }, null, true);
      return iDVSwitch.fetchPortKeys(dvsMor, portCriteria);
   }

   /**
    * Move the portkeys to portgroup represented by the portgroupkey.
    * 
    * @param dvsMor MOR of the DVS.
    * @param portKeys portkeys of the DVPorts to be moved.
    * @param portgroupKey Key of the destination portgroup.
    * @return boolean true, If moved successfully. false, otherwise.
    * @throws MethodFault On API errors.
    * @throws Exception On other problems.
    */
   public boolean movePort(ManagedObjectReference dvsMor,
                           List<String> portKeys,
                           String portgroupKey)
      throws Exception
   {
      boolean status = false;
      String[] keys = null;
      if (portKeys != null) {
         keys = portKeys.toArray(new String[portKeys.size()]);
      }
      if (portgroupKey != null) {
         log.info("Moving port(s) " + portKeys + " to portgroup: "
                  + portgroupKey);
      } else {
         log.info("Moving port(s) " + portKeys + " to DVS.");
      }
      if (iDVSwitch.movePort(dvsMor, keys, portgroupKey)) {
         log.info("Successfully moved given ports.");
         status = true;
      } else {
         log.error("Failed to move the ports.");
      }
      return status;
   }

   /**
    * Add DVPortgroups to the DVS.
    * 
    * @param dvsMor DVS MOR.
    * @param configSpec DVPortgroup configspecs.
    * @return List<String> keys of added DVPortgroups.
    * @throws MethodFault, Exception
    */
   public List<String> addPortgroups(ManagedObjectReference dvsMor,
                                     DVPortgroupConfigSpec... configSpec)
      throws Exception
   {
      log.info("Adding port groups: " + toString(configSpec));
      List<ManagedObjectReference> portgroupMors = null;
      List<String> portgroupKeys = null;
      portgroupMors = iDVSwitch.addPortGroups(dvsMor, configSpec);
      if ((portgroupMors != null) && (portgroupMors.size() > 0)) {
         log.info("Succssfully added " + portgroupMors.size()
                  + " portgroups.");
         portgroupKeys = new ArrayList<String>(portgroupMors.size());
         for (ManagedObjectReference portgroupMor : portgroupMors) {
            portgroupKeys.add(iDVPortGroup.getKey(portgroupMor));
         }
         log.info("Added port group keys:" + portgroupKeys);
      } else {
         log.error("Failed to add port group(s).");
      }
      return portgroupKeys;
   }

   /**
    * String representation of DVPortgroupConfigSpec.
    * 
    * @param configSpecs
    * @return String representation of DVPortgroupConfigSpec
    */
   public static String toString(DVPortgroupConfigSpec... configSpecs)
   {
      StringBuilder s = new StringBuilder(50);
      if (configSpecs != null) {
         s.append("Num of Portgroups: ").append(configSpecs.length);
         for (int i = 0; i < configSpecs.length; i++) {
            DVPortgroupConfigSpec aCfg = configSpecs[i];
            s.append("\n Type: ").append(aCfg.getType());
            s.append(" Name: ").append(aCfg.getName());
            s.append(" Ports: ").append(aCfg.getNumPorts());
            DVPortgroupPolicy policy = aCfg.getPolicy();
            if (policy != null) {
               boolean flag = policy.isBlockOverrideAllowed();
               if (flag) {
                  s.append(" BlockOverrideAllowed= ").append(flag);
               }
               flag = policy.isLivePortMovingAllowed();
               if (flag) {
                  s.append(" LivePortMovingAllowed= ").append(flag);
               }
               flag = policy.isPortConfigResetAtDisconnect();
               if (flag) {
                  s.append(" PortConfigResetAtDisconnect= ").append(flag);
               }
               flag = policy.isShapingOverrideAllowed();
               if (flag) {
                  s.append(" ShapingOverrideAllowed= ").append(flag);
               }
               flag = policy.isVendorConfigOverrideAllowed();
               if (flag) {
                  s.append(" VendorConfigOverrideAllowed= ").append(flag);
               }
            }
         }
      }
      return s.toString();
   }

   /**
    * Reconfigure the given VirtualMachine to use the given DVPort key or
    * DVportgroup key of the DVS. If reconfiguration is successful this method
    * will return the originalDeltaCfgSpec which can be use to restore the VM to
    * original configuration.
    * 
    * @param vmMor MOR of VM to be reconfigured.
    * @param dvsMor DVS MOR.
    * @param connectAnchor ConnectAnchor
    * @param portKey port key.
    * @param portgroupKey DVPortgroup key.
    * @return VirtualMachineConfigSpec delta VM configSpec.
    */
   public VirtualMachineConfigSpec reconfigVM(ManagedObjectReference vmMor,
                                              ManagedObjectReference dvsMor,
                                              ConnectAnchor connectAnchor,
                                              String portKey,
                                              String portgroupKey)
   {
      DVSConfigInfo dvsInfo = null;
      VirtualMachineConfigSpec originalDeltaCfgSpec = null;
      VirtualMachineConfigSpec[] deltaVmConfigSpecs = null;
      DistributedVirtualSwitchPortConnection dvsConn = null;
      try {
         dvsInfo = iDVSwitch.getConfig(dvsMor);
         dvsConn = new DistributedVirtualSwitchPortConnection();
         dvsConn.setPortKey(portKey);
         dvsConn.setPortgroupKey(portgroupKey);
         dvsConn.setSwitchUuid(dvsInfo.getUuid());
         deltaVmConfigSpecs = DVSUtil.getVMConfigSpecForDVSPort(vmMor,
                  connectAnchor,
                  new DistributedVirtualSwitchPortConnection[] { dvsConn });
         if (deltaVmConfigSpecs != null) {
            log.info("Got the VM config, Now reconfiguring VM ...");
            if (ivm.reconfigVM(vmMor, deltaVmConfigSpecs[0])) {
               log.info("Successfully reconfigured the VM");
               originalDeltaCfgSpec = deltaVmConfigSpecs[1];
            } else {
               log.error("Failed to reconfigure the VM.");
            }
         }
      } catch (Exception e) {
         e.printStackTrace();
      }
      return originalDeltaCfgSpec;
   }

   /**
    * Destroy given managed entity.
    * 
    * @param mor MOR of the entity to be destroyed.
    * @return boolean true, if destroyed.
    */
   public boolean destroy(ManagedObjectReference mor)
   {
      boolean status = false;
      if (mor != null) {
         try {
            log.info("Destroying: " + iManagedEntity.getName(mor));
            status = iManagedEntity.destroy(mor);
         } catch (Exception eExcep) {
            TestUtil.handleException(eExcep);
         } 
      } else {
         log.info("Given MOR is null");
         status = true;
      }
      return status;
   }

   /**
    * Create a DVPortgroupConfigSpec object using the given values.
    * 
    * @param type Type of the port group.
    * @param numPort number of ports to create.
    * @param policy the policy to be used.
    * @param scope Scope.
    * @return DVPortgroupConfigSpec with given values set.
    */
   public DVPortgroupConfigSpec buildDVPortgroupCfg(String type,
                                                    int numPort,
                                                    DVPortgroupPolicy policy,
                                                    ManagedObjectReference scope)
   {
      DVPortgroupConfigSpec cfg = new DVPortgroupConfigSpec();
      cfg.setName(getTestId() + count++);
      cfg.setType(type);
      cfg.setNumPorts(numPort);
      cfg.setPolicy(policy);
      if(scope != null){
    	  cfg.getScope().addAll(com.vmware.vcqa.util.
    	     TestUtil.arrayToVector(new ManagedObjectReference[] { scope }));
      }
      return cfg;
   }

   /**
    * Default setup used in all the Move port tests.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, If successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      prefix = getTestId() + "-";
      dvsName = prefix + "DVS";
      iFolder = new Folder(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iDVPortGroup = new DistributedVirtualPortgroup(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      return true;
   }

   /**
    * Test cleanup. Try to destroy the DVS if it was created in test setup.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return true, if test cleanup was successful. false, otherwise.
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      return destroy(dvsMor);
   }
}

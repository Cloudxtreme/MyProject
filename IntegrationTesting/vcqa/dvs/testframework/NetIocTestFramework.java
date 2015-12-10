/* ************************************************************************
*
* Copyright 2012 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa.vim.dvs.testframework;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.io.ByteArrayInputStream;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Map.Entry;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.DVPortSelection;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupSelection;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSKeyedOpaqueData;
import com.vmware.vc.DVSKeyedOpaqueDataList;
import com.vmware.vc.DVSOpaqueDataConfigInfo;
import com.vmware.vc.DVSOpaqueDataConfigSpec;
import com.vmware.vc.DVSSelection;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.DvsVmVnicResourceAllocation;
import com.vmware.vc.DvsVmVnicResourcePoolConfigSpec;
import com.vmware.vc.HostDVSPortData;
import com.vmware.vc.HostMemberSelection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.SelectionSet;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.i18n.I18NDataProvider;
import com.vmware.vcqa.i18n.I18NDataProviderConstants;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalDistributedVirtualSwitchManager;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * This class represents the subsystem for network IO control
 * operations.It encompasses all possible states and transitions in any
 * scenario (positive/negative/I18n) with respect to network resource IO
 * control
 *
 * @author sabesanp
 *
 */
public class NetIocTestFramework
{

   private DistributedVirtualSwitch vds = null;
   private Folder folder = null;
   private DistributedVirtualPortgroup vdsPortgroup = null;
   private ManagedObjectReference vdsMor = null;
   private HostSystem host = null;
   private VirtualMachine virtualMachine = null;
   private ServiceInstance serviceInstance = null;
   private ManagedObjectReference dcMor = null;
   private DataFactory xmlFactory = null;
   private ArrayList<DvsVmVnicResourcePoolConfigSpec> vmVnicResPoolList = null;
   private ManagedObjectReference hostDVSMgrMor = null;
   private InternalHostDistributedVirtualSwitchManager internalHostDVSMgr =
      null;
   private List<Step> stepList = null;
   private CustomMap customMap = null;
   private static final Logger log = LoggerFactory.getLogger(
      NetIocTestFramework.class);
   private ConnectAnchor connectAnchor = null;
   private Map<ManagedObjectReference,VirtualMachineConfigSpec>
      vmMorConfigSpecMap = null;
   private VDSTestFramework vdsTestFramework = null;

   /**
    * Constructor
    *
    * @param connectAnchor
    * @param xmlFilePath
    *
    * @throws MethodFault, Exception
    */
   public NetIocTestFramework(ConnectAnchor connectAnchor,
                                String xmlFilePath)
      throws Exception
   {
      folder = new Folder(connectAnchor);
      serviceInstance = new ServiceInstance(connectAnchor);
      vds = new DistributedVirtualSwitch(connectAnchor);
      host = new HostSystem(connectAnchor);
      vdsPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      dcMor = folder.getDataCenter();
      xmlFactory = new DataFactory(xmlFilePath);
      stepList = new ArrayList<Step>();
      this.connectAnchor = connectAnchor;
      virtualMachine = new VirtualMachine(connectAnchor);
      vdsTestFramework = new VDSTestFramework(connectAnchor,
              xmlFilePath);
   }

    /**
     * Method to execute a list of steps provided
     *
     * @param stepList
     *
     * @throws Exception
     */
    public void execute(List<Step> stepList)
         throws Exception {
       for(Step step : stepList) {
          Class currClass = Class.forName(step.getTestFrameworkName());
          Method method = currClass.getDeclaredMethod(step.getName());
          if(currClass.getName().equals(
             VDSTestFramework.class.getName())) {
             this.vdsTestFramework.addStep(step);
             method.invoke(this.vdsTestFramework);
          } else if (currClass.getName().equals(this.getClass().getName())) {
             addStep(step);
             method.invoke(this);
          }
       }
    }

   /**
    * This method adds a step to the list of steps
    *
    * @param step
    */
   public void addStep(Step step)
   {
      this.stepList.add(step);
   }

   /**
    * This method initializes the data pertaining to the step as mentioned in
    * the data file.
    *
    * @param stepName
    *
    * @throws Exception
    */
   public void init(String stepName)
      throws Exception
   {
      Step step = getStep(stepName);
      if(step != null){
         List<String> data  = step.getData();
         if(data != null){
            List<Object> objIdList = this.xmlFactory.getData(data);
            if(objIdList != null){
               initData(objIdList);
            }
         }
      }
   }

   /**
    * This method gets the step associated with the step name. If the step is
    * not executed, return the step and change executed to true.
    *
    * @param name
    *
    * @return Step
    */
   public Step getStep(String name)
   {
      for(Step step : stepList){
         if(step.getName().equals(name)){
            if(!step.getExecuted()){
               step.setExecuted(true);
               return step;
            }
         }
      }
      return null;
   }

   /**
    * This method initializes the data for input parameters
    *
    * @param objIdList
    *
    * @throws Exception
    */
   public void initData(List<Object> objIdList)
      throws Exception
   {
      vmVnicResPoolList= new
               ArrayList<DvsVmVnicResourcePoolConfigSpec>();
      for(Object object : objIdList){
         if(object instanceof DvsVmVnicResourcePoolConfigSpec){
            vmVnicResPoolList.add((DvsVmVnicResourcePoolConfigSpec)object);
         }
      }
   }
}

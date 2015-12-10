package com.vmware.vcqa.vim.dvs;



import org.slf4j.Logger;

import org.slf4j.LoggerFactory;



import com.vmware.vc.DVSFeatureCapability;
import com.vmware.vc.EntityBackupConfig;
import com.vmware.vc.SelectionSet;

import com.vmware.vc.DVSManagerDvsConfigTarget;

import com.vmware.vc.DistributedVirtualSwitchHostProductSpec;

import com.vmware.vc.DistributedVirtualSwitchManagerCompatibilityResult;

import com.vmware.vc.DistributedVirtualSwitchManagerDvsProductSpec;

import com.vmware.vc.DistributedVirtualSwitchManagerHostContainer;

import com.vmware.vc.DistributedVirtualSwitchManagerHostDvsFilterSpec;

import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.DistributedVirtualSwitchManagerImportResult;

import com.vmware.vc.ManagedObjectReference;

import com.vmware.vc.MethodFault;

import com.vmware.vcqa.ConnectAnchor;

import com.vmware.vcqa.TestConstants;

import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.Task;

import com.vmware.vcqa.vim.ServiceInstance;

public class DistributedVirtualSwitchManager extends ManagedEntity

{

   private static final Logger log = LoggerFactory.getLogger(DistributedVirtualSwitchManager.class);
   /**
    * Constructor
    *
    * @param connectAnchor
    *
    * @throws MethodFault, Exception
    */
   public DistributedVirtualSwitchManager(ConnectAnchor connectAnchor)
                                                    throws Exception
   {
      super(connectAnchor);
   }

   /**
    * Returns the DVS Manager MOR.
    *
    * @return ManagedObjectReference of thd DVS Manager.
    *
    * @throws MethodFault, Exception
    */
   public ManagedObjectReference
   getDvSwitchManager()
   {
      ManagedObjectReference mor = null;
      ServiceInstance mServiceInst =
         new ServiceInstance(super.getConnectAnchor());
      mor = mServiceInst.getSC().getDvSwitchManager();
      if (mor == null) {
         log.warn("DVS Manager : MOR object Ref is null");
      } else {
         if (log.isTraceEnabled()) {
            log.debug("Login : MOR object : Type = " + mor.getType() +
                              " : Value =  " + mor.getValue());
         }
      }
      return mor;
   }

   /**
    * Queries the compatible host for an existing DVS.
    *
    * @param dvsManagerMor ManagedObjectReference
    * @param container ManagedObjectReference
    * @param recursive boolean
    * @param dvsMor ManagedObjectReference
    *
    * @return ManagedObjectReference[] of the hosts.
    *
    * @throws MethodFault, Exception
    */
   public ManagedObjectReference[]
   queryCompatibleHostForExistingDVS(ManagedObjectReference dvsManagerMor,
                                     ManagedObjectReference container,
                                     boolean recursive,
                                     ManagedObjectReference dvsMor)
                                     throws Exception
   {
      ManagedObjectReference[] compatbileHosts = null;
      super.setOpStartTime();
      compatbileHosts = com.vmware.vcqa.util.TestUtil.
                                 vectorToArray(
                                               super.getPortType().queryCompatibleHostForExistingDvs(
                                                      dvsManagerMor, container,
                                                      recursive, dvsMor), com.vmware.vc.ManagedObjectReference.class);
      super.setOpCompleteTime();
      return compatbileHosts;
   }

   /**
    * Queries the compatible host for a new DVS.
    *
    * @param dvsManagerMor ManagedObjectReference
    * @param container ManagedObjectReference
    * @param recursive boolean
    * @param productSpec DistributedVirtualSwitchProductSpec
    *
    * @return ManagedObjectReference[] of the hosts.
    *
    * @throws MethodFault, Exception
    */
   public ManagedObjectReference[]
   queryCompatibleHostForNewDVS(ManagedObjectReference dvsManagerMor,
                                ManagedObjectReference container,
                                boolean recursive,
                                DistributedVirtualSwitchProductSpec
                                   productSpec)
                                throws Exception
   {
      ManagedObjectReference[] compatbileHosts = null;
      super.setOpStartTime();
      compatbileHosts = com.vmware.vcqa.util.TestUtil.
                                 vectorToArray(
                                               super.getPortType().queryCompatibleHostForNewDvs(
                                                      dvsManagerMor, container,
                                                      recursive, productSpec), com.vmware.vc.ManagedObjectReference.class);
      super.setOpCompleteTime();
      return compatbileHosts;
   }

   /**
    * Queries the avaialable switch spec.
    *
    * @param dvsManagerMor ManagedObjectReference
    *
    * @return DistributedVirtualSwitchProductSpec[] Object.
    *
    * @throws MethodFault, Exception
    */
   public DistributedVirtualSwitchProductSpec[]
   queryAvailableSwitchSpec(ManagedObjectReference dvsManagerMor)
                            throws Exception
   {
      DistributedVirtualSwitchProductSpec[] productSpec = null;
      super.setOpStartTime();
      productSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(
                                           super.getPortType().queryAvailableDvsSpec(dvsManagerMor, null),
                                           com.vmware.vc.DistributedVirtualSwitchProductSpec.class);
      super.setOpCompleteTime();
      return productSpec;
   }

   /**
    * Returns the DistributedVirtualSwitchProductSpec on the host.
    *
    * @param dvsManagerMor
    * @param productSpec DistributedVirtualSwitchProductSpec
    *
    * @return DistributedVirtualSwitchHostProductSpec[] Object
    *
    * @throws MethodFault, Exception
    */
   public DistributedVirtualSwitchHostProductSpec[]
   queryCompatibleHostSpec(ManagedObjectReference dvsManagerMor,
                           DistributedVirtualSwitchProductSpec productSpec)
                           throws Exception
   {
      DistributedVirtualSwitchHostProductSpec[] hostSpec = null;
      super.setOpStartTime();
      hostSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(
                                        super.getPortType().queryDvsCompatibleHostSpec(
                                                dvsManagerMor, productSpec), com.vmware.vc.DistributedVirtualSwitchHostProductSpec.class);
      super.setOpCompleteTime();
      return hostSpec;
   }

   /**
    * Queries the switch by uuid on the host.
    *
    * @param dvsManagerMor ManagedObjectReference
    * @param dvsUuid String
    *
    * @return ManagedObjectReference of the dvss MOR.
    *
    * @throws MethodFault, Exception
    */
   public ManagedObjectReference
   querySwitchByUuid(ManagedObjectReference dvsManagerMor,
                     String dvsUuid)
                     throws Exception
   {
      ManagedObjectReference dvsMor = null;
      super.setOpStartTime();
      dvsMor = super.getPortType().queryDvsByUuid(dvsManagerMor,
                                                               dvsUuid);
      super.setOpCompleteTime();
      return dvsMor;
   }

   /**
    * Returns the DVS manager config target.
    *
    * @param dvsManagerMor ManagedObjectReference
    * @param hostMor ManagedObjectReference
    * @param dvsMor ManagedObjectReference
    *
    * @return DVSManagerDvsConfigTarget Object
    *
    * @throws MethodFault, Exception
    */
   public DVSManagerDvsConfigTarget
   getDVSManagerQueryDvsConfigTarget(ManagedObjectReference dvsManagerMor,
                                     ManagedObjectReference hostMor,
                                     ManagedObjectReference dvsMor)
                                     throws Exception
   {
      DVSManagerDvsConfigTarget configTarget = null;
      super.setOpStartTime();
      configTarget = super.getPortType().queryDvsConfigTarget(
                                            dvsManagerMor,
                                            hostMor,
                                            dvsMor);
      super.setOpCompleteTime();
      return configTarget;
   }

   /**
    * This method returns DVS features that are available for the given
    * DistributedVirtualSwitch product specification
    *
    * @param dvsManagerMor ManagedObjectReference
    * @param productSpec - The productSpec of a DistributedVirtualSwitch.
    *
    * @return DVSFeatureCapability Object
    *
    * @throws MethodFault, Exception
    */
   public DVSFeatureCapability queryDvsFeatureCapability(
                                           ManagedObjectReference dvsManagerMor,
                                           DistributedVirtualSwitchProductSpec
                                           productSpec)
      throws Exception
   {
      DVSFeatureCapability featureCapability = null;
      super.setOpStartTime();
      featureCapability =
               super.getPortType().queryDvsFeatureCapability(dvsManagerMor,
                        productSpec);
      super.setOpCompleteTime();
      return featureCapability;
   }

   /**
    * This method retrieves an array of compatibility results for the hosts
    *
    * @param dvsManagerMor ManagedObjectReference
    * @param hostContainer - The container of hosts on which we check the
    *            compatibility.
    * @param dvsProductSpec The productSpec of a DistributedVirtualSwitch
    * @param hostFilterSpec The hosts against which to check compatibility. This
    *            is a filterSpec and users can use this to specify all hosts in
    *            a container, (datacenter, folder or computeResource) or an
    *            array of hosts, or hosts which are member of a DVS or not a
    *            member of a DVS.
    *
    *
    * @return DistributedVirtualSwitchManagerCompatibilityResult[]
    *
    * @throws MethodFault, Exception
    */
   public DistributedVirtualSwitchManagerCompatibilityResult[]
          queryCheckCompatibility(ManagedObjectReference dvsManagerMor,
          DistributedVirtualSwitchManagerHostContainer hostContainer,
          DistributedVirtualSwitchManagerDvsProductSpec dvsProductSpec,
          DistributedVirtualSwitchManagerHostDvsFilterSpec[] hostFilterSpec)
      throws Exception
   {
      DistributedVirtualSwitchManagerCompatibilityResult[] compatibilityResult =
               null;
      super.setOpStartTime();
      compatibilityResult =
               com.vmware.vcqa.util.TestUtil.vectorToArray(super.getPortType().queryDvsCheckCompatibility(
                                 dvsManagerMor,
                                 hostContainer,
                                 dvsProductSpec,
                                 com.vmware.vcqa.util.TestUtil.arrayToVector(hostFilterSpec)), com.vmware.vc.DistributedVirtualSwitchManagerCompatibilityResult.class);
      super.setOpCompleteTime();
      return compatibilityResult;
   }
   
   /**
    * Async method for exportEntity API
    *
    * @param dvsManagerMor ManagedObjectReference
    * @param selectionSet - Array containing DVS, DVS Port Group SelectionSet
    *
    * @return EntityBackupConfig[]
    *
    * @throws MethodFault, Exception
    */
    public ManagedObjectReference
    asyncExportEntity(ManagedObjectReference dvsManagerMor,
 		             SelectionSet[] selectionSet)
                             throws Exception
    {
       ManagedObjectReference taskMor = null;
       super.setOpStartTime();
       taskMor = getPortType().dvsManagerExportEntityTask(dvsManagerMor, TestUtil.arrayToVector(selectionSet));
       super.setOpMiddleTime();
       return taskMor;
    }
    
    /**
     * Async method for importEntity API
     *
     * @param dvsManagerMor ManagedObjectReference
     * @param config - Array of type EntityBackupConfig[], containing DVS, DVS Port 
     * Group SelectionSet to be imported
     *
     * @return void
     *
     * @throws MethodFault, Exception
     */
     public ManagedObjectReference
     asyncImportEntity(ManagedObjectReference dvsManagerMor,
     		          EntityBackupConfig[] config, String importType)
                              throws Exception
     {
        ManagedObjectReference taskMor = null;
        super.setOpStartTime();
        taskMor = getPortType().dvsManagerImportEntityTask(dvsManagerMor, TestUtil.arrayToVector(config), importType);
        super.setOpMiddleTime();
        return taskMor;
     }
    /**
     * This method exports the given VDS/VDS port group configuration.
     *
     * @param dvsManagerMor ManagedObjectReference
     * @param selectionSet - Array containing DVS, DVS Port Group SelectionSet
     *
     * @return EntityBackupConfig[]
     *
     * @throws Exception
     */
    public EntityBackupConfig[] exportEntity(ManagedObjectReference dvsManagerMor,
            SelectionSet[] selectionSet) throws Exception                                                   
    {
       ManagedObjectReference exportTaskMor = null;
       boolean taskSuccess = false;
       super.setOpStartTime();
       final Task mTasks = new Task(super.getConnectAnchor());

       EntityBackupConfig[] config = null;	   

       exportTaskMor = asyncExportEntity(dvsManagerMor, selectionSet);

       taskSuccess = mTasks.monitorTask(exportTaskMor);
       setOpCompleteTime();

       final com.vmware.vc.TaskInfo taskInfo = mTasks.getTaskInfo(exportTaskMor);

       if (!taskSuccess) {
          throw new com.vmware.vc.MethodFaultFaultMsg(taskInfo.getError().getLocalizedMessage(),
                  taskInfo.getError().getFault());
       }
       /*verify the configuration array returned by the export entity task */
       config = (EntityBackupConfig[])TestUtil.checkAndConvertArrayOfObjects(taskInfo.getResult());
       return config;
    }
    
    /**
     * This method imports the given VDS/VDS port group configuration.
     *
     * @param dvsManagerMor ManagedObjectReference
     * @param config - Configuration to be imported, EntityBackupConfig
     * @param String - ImportType
     * @return importResult - DistributedVirtualSwitchManagerImportResult
     *
     * @throws Exception
     */
    public DistributedVirtualSwitchManagerImportResult importEntity(
                       ManagedObjectReference dvsManagerMor,
                       EntityBackupConfig[] config,
                       String importType)
                       throws Exception
    {
       DistributedVirtualSwitchManagerImportResult importResult = null;
       ManagedObjectReference importTaskMor = null;
       boolean taskSuccess = false;
       super.setOpStartTime();
       final Task mTasks = new Task(super.getConnectAnchor());
       importTaskMor = asyncImportEntity(dvsManagerMor, config, importType);

       taskSuccess = mTasks.monitorTask(importTaskMor);
       setOpCompleteTime();

       final com.vmware.vc.TaskInfo taskInfo = mTasks.getTaskInfo(importTaskMor);

       if (!taskSuccess) {
          throw new com.vmware.vc.MethodFaultFaultMsg(taskInfo.getError().getLocalizedMessage(),
                  taskInfo.getError().getFault());
       }

       /* To retrieve import result returned by the import entity task */
       importResult = (DistributedVirtualSwitchManagerImportResult)
             TestUtil.checkAndConvertArrayOfObjects(taskInfo.getResult());
       return importResult;
    }
}

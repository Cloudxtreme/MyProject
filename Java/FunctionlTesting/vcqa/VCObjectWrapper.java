/* **********************************************************************
 * Copyright 2012 VMware, Inc.  All rights reserved. VMware Confidential
 * **********************************************************************
 * $Id$
 * $DateTime$
 * $Change$
 * $Author$
 * *********************************************************************/

package com.vmware.vcqa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.InternalServiceInstanceContent;
import com.vmware.vcqa.internal.vim.InternalDatastore;
import com.vmware.vcqa.internal.vim.InternalFolder;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.InternalStoragePod;
import com.vmware.vcqa.internal.vim.InternalStorageResourceManager;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.Datastore;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.ResourcePool;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.Task;
import com.vmware.vcqa.vim.VirtualApp;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.virtualresourcepool.VirtualResourcePool;

/**
 * @author reaswaramoorthy
 */
public class VCObjectWrapper
{
   private static final Logger log = LoggerFactory.getLogger(VCObjectWrapper.class);

   private ConnectAnchor connectAnchorToVC;
   private Task task;
   private Folder folder;
   private Datastore datastore;
   private Datacenter datacenter;
   private HostSystem hostSystem;
   private ResourcePool resourcePool;
   private NetworkSystem networkSystem;
   private VirtualMachine virtualMachine;
   private VirtualApp virtualApp;
   private ClusterComputeResource clusterComputeResource;
   private DistributedVirtualSwitch distributedVirtualSwitch;
   private DistributedVirtualPortgroup distributedVirtualPortgroup;
   private ServiceInstance serviceInstance;
   private InternalServiceInstance internalServiceInstance;
   private VirtualResourcePool virtualResourcePool;
   private InternalFolder internalFolder;
   private InternalStoragePod internalstoragePod;
    private InternalStorageResourceManager internalStorageResourceManager;
    private InternalDatastore internalDatastore;
    private ManagedEntity managedEntity;

   /**
    * @param connectAnchor
    */
   public VCObjectWrapper(ConnectAnchor connectAnchor)
   {
      try
      {
         if (connectAnchor == null)
            throw new IllegalArgumentException(
                     "ConnectAnchor object reference cannot be null.");
         connectAnchorToVC = connectAnchor;
         task = new Task(connectAnchor);
         folder = new Folder(connectAnchor);
         internalFolder = new InternalFolder(connectAnchor);
         datastore = new Datastore(connectAnchor);
         internalstoragePod = new InternalStoragePod(connectAnchor);
         datacenter = new Datacenter(connectAnchor);
         hostSystem = new HostSystem(connectAnchor);
         virtualApp = new VirtualApp(connectAnchor);
         resourcePool = new ResourcePool(connectAnchor);
         networkSystem = new NetworkSystem(connectAnchor);
         virtualMachine = new VirtualMachine(connectAnchor);
         clusterComputeResource = new ClusterComputeResource(connectAnchor);
         distributedVirtualSwitch = new DistributedVirtualSwitch(connectAnchor);
         distributedVirtualPortgroup = new DistributedVirtualPortgroup(
                  connectAnchor);
         serviceInstance = new ServiceInstance(connectAnchor);
         internalServiceInstance = new InternalServiceInstance(connectAnchor);
         virtualResourcePool = new VirtualResourcePool(connectAnchor);
            internalStorageResourceManager = new InternalStorageResourceManager(connectAnchor);
            internalDatastore = new InternalDatastore(connectAnchor);
            managedEntity = new ManagedEntity(connectAnchor);
      } catch (Exception e)
      {
         log.error(
                  "Initialization of VC objects failed with the following exception. ",
                  e);
         throw new RuntimeException(e);
      }
   }


    /**
     * @return the connectAnchorToVC
     */
   public ConnectAnchor getConnectAnchorToVC()
   {
      return connectAnchorToVC;
   }

   /**
    * @return the task
    */
   public Task getTask()
   {
      return task;
   }

   /**
    * @return the folder
    */
   public Folder getFolder()
   {
      return folder;
   }

   /**
    * @return the datastore
    */
   public Datastore getDatastore()
   {
      return datastore;
   }

   /**
    * @return the hostSystem
    */
   public HostSystem getHostSystem()
   {
      return hostSystem;
   }

   /**
    * @return the virtualApp
    */
   public VirtualApp getVirtualApp()
   {
      return virtualApp;
   }

   /**
    * @return the resourcePool
    */
   public ResourcePool getResourcePool()
   {
      return resourcePool;
   }

   /**
    * @return the networkSystem
    */
   public NetworkSystem getNetworkSystem()
   {
      return networkSystem;
   }

   /**
    * @return the virtualMachine
    */
   public VirtualMachine getVirtualMachine()
   {
      return virtualMachine;
   }

   /**
    * @return the clusterComputeResource
    */
   public ClusterComputeResource getClusterComputeResource()
   {
      return clusterComputeResource;
   }

   /**
    * @return the distributedVirtualSwitch
    */
   public DistributedVirtualSwitch getDistributedVirtualSwitch()
   {
      return distributedVirtualSwitch;
   }

   /**
    * @return the serviceInstance
    */
   public ServiceInstance getServiceInstance()
   {
      return serviceInstance;
   }

   /**
    * @return the distributedVirtualPortgroup
    */
   public DistributedVirtualPortgroup getDistributedVirtualPortgroup()
   {
      return distributedVirtualPortgroup;
   }

   /**
    * @return the InternalServiceInstanceContent
    */
   public InternalServiceInstanceContent getInternalServiceInstanceContent()
   {
      return internalServiceInstance.getInternalServiceInstanceContent();
   }

   /**
    * @return the virtualResourcePool
    */
   public VirtualResourcePool getVirtualResourcePool()
   {
      return virtualResourcePool;
   }

   /**
    * @return
    */
   public Datacenter getDatacenter()
   {
      return datacenter;
   }

   /**
    * @return the internalFolder
    */
   public InternalFolder getInternalFolder()
   {
      return internalFolder;
   }

   /**
    * @return the storagePod
    */
   public InternalStoragePod getInternalStoragePod()
   {
      return internalstoragePod;
   }

    /**
     * @return the internalStorageResourceManager
     */
    public InternalStorageResourceManager getInternalStorageResourceManager() {
        return internalStorageResourceManager;
    }

    /**
     * @return the internalDatastore
     */
    public InternalDatastore getInternalDatastore() {
        return internalDatastore;
    }

    /**
     * @return the managedEntity
     */
    public ManagedEntity getManagedEntity() {
        return managedEntity;
    }
}

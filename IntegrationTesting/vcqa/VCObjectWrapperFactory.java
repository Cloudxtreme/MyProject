/* **********************************************************************
 * Copyright 2012 VMware, Inc.  All rights reserved. VMware Confidential
 * **********************************************************************
 * $Id$
 * $DateTime$
 * $Change$
 * $Author$
 * *********************************************************************/

package com.vmware.vcqa;

import com.gs.collections.api.block.function.Function0;
import com.gs.collections.api.map.MutableMap;
import com.gs.collections.impl.map.mutable.UnifiedMap;

/**
 * @author reaswaramoorthy
 */
public class VCObjectWrapperFactory
{
   private static final VCObjectWrapperFactory VC_OBJECT_WRAPPER_FACTORY_INSTANCE = new VCObjectWrapperFactory();
   public static final MutableMap<ConnectAnchor, VCObjectWrapper> vcObjectWrapperMap = UnifiedMap.newMap();

   public static VCObjectWrapperFactory getInstance()
   {
      return VCObjectWrapperFactory.VC_OBJECT_WRAPPER_FACTORY_INSTANCE;
   }

   private VCObjectWrapperFactory()
   {
   }

   @SuppressWarnings("serial")
   public VCObjectWrapper getVcObjectWrapper(final ConnectAnchor connectAnchor)
   {
         return vcObjectWrapperMap.getIfAbsentPut(connectAnchor,
                  new Function0<VCObjectWrapper>()
                  {
                     @Override
                     public VCObjectWrapper value()
                     {
                        return new VCObjectWrapper(connectAnchor);
                     }
                  });
   }

}

package com.vmware.vcqa;

import org.apache.commons.configuration.HierarchicalConfiguration;

public interface IDataProviderTest
{

   /**
    * Return the data objects as dataProvider
    * 
    * @return Object[][] input of the Data-Driven tests. The second dimension of
    *         the array include four value: 
    *         1) test Id 
    *         2) test description (optional in XML) 
    *         3) test priority (optional in XML) 
    *         4) data from xml file
    */
   public Object[][] createDataObject()
                                       throws Exception;

   public void test(String testId,
                    String testDescription,
                    String priority,
                    HierarchicalConfiguration data)
                                                   throws Exception;
}
/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa;

import org.testng.ITest;

/**
 * Interface that defines the contract and the methods to be implemented by
 * every data driven test.
 */
public interface IDataDrivenTest extends ITest
{
   /**
    * Returns the Data driven test instances of the test class, based on the
    * data file passed or the xml file in the test class package or class
    * format.
    *
    * @param dataFile String data file.
    *
    * @return Object[] an array of test base instances.
    *
    * @throws Exception
    */
   public Object[] getTests(String dataFile) throws Exception;
}
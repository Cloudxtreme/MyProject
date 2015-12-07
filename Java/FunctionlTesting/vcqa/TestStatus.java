package com.vmware.vcqa;

import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;

public enum TestStatus {
	NONE(0), PASS(1), FAIL(2), SETUPFAIL(3), EXCEPTION(4), CLEANUPFAIL(5);

	// Holds the value of the sensor
	private final int outcome;
	private static final Map<Integer, TestStatus> lookup = new HashMap<Integer, TestStatus>();

	private TestStatus(int result) {
		this.outcome = result;
	}

	/**
	 * Returns the Value of the TestStatus
	 * 
	 * @return String Sensor name
	 */
	public int getTestStatus() {
		return this.outcome;
	}

	static {
		for (TestStatus s : EnumSet.allOf(TestStatus.class))
			lookup.put(s.getTestStatus(), s);
	}
	
	public static TestStatus get(int code) { 
        return lookup.get(code); 
   }


}

#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use FindBin;

use FindBin;
use lib "$FindBin::Bin/../../";
use lib "$FindBin::Bin/../../VDNetLib/";
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";
use Text::Table;
use VDNetLib::Common::Operator;
use VDNetLib::Common::Compare;
use VDNetLib::Common::GlobalConfig;
use VDNetLib::Workloads::Utilities;

# One time initialization of variables for unit tests
my ($testResult, $expectedResult, $userData, $serverData, $previous, $current);
my ($diff, $logDir, $currentLogLocation, $previousLogLocation, $currentHash, $previousHash);
my ($result);
my $compareObj = VDNetLib::Common::Compare->new();
my $failCount = "0";
my $passCount = "0";
VDNetLib::Common::GlobalConfig::CreateVDLogObj('logLevel'    => 7,
                                               # use 9 for full scale logging
                                               # use 7 for INFO level logging
                                               # use 4 for no out puts logging
                                               'logToFile'   => 1,
                                               'logFileName' => "/tmp/vdnet/verificationUnitTest.log");
if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::Common::VDLog object";
   exit -1;
}
my $tb = Text::Table->new("Test #", "Test Name", "Result ");




#if (0) {
# Unit Test 1: Check if equal_to passes if values dont match
$userData = [
          {
            'abc' => [
                       {
                         'password[?]equal_to' => 'default',
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'zone[?]equal_to' => '6.0'
                                                 }
                                      }
                                    ],
                         'ipaddress[?]equal_to' => '10.10.10.10',
                         'schema[?]equal_to' => '12345',
                         'username[?]equal_to' => 'admin',
                         'name[?]equal_to' => 'test2'
                       }
                     ]
          }
];

$serverData = [
          {
            'abc' => [
                       {
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'zone' => '6.0'
                                                 }
                                      }
                                    ],
                         'password' => 'default',
                         'name' => 'test2',
                         'schema' => 12345,
                         'ipaddress' => '10.10.10.10',
                         'username' => 'admin'
                       }
                     ]
          }
];
$testResult = $compareObj->CompareDataStructures($userData, $serverData);
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 1: Positive test for \'equal_to\' Failed!!!\n\n";
   $tb->load(["1", "Positive test for \'equal_to\'", "Failed"]);
   $failCount++;
} else {
   print "Test 1: Positive test for \'equal_to\' Passed\n\n";
   $tb->load(["1", "Positive test for \'equal_to\'", "Passed"]);
   $passCount++;
}





# Unit Test 2: Check if equal_to fails if values dont match
$userData = [
          {
            'abc' => [
                       {
                         'password[?]equal_to' => 'default',
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'zone[?]equal_to' => '6.0'
                                                 }
                                      },
                                    ],
                         'ipaddress[?]equal_to' => '10.10.10.10',
                         'schema[?]equal_to' => '12345',
                         'username[?]equal_to' => 'admin',
                         'name[?]equal_to' => 'test2'
                       }
                     ]
          }
];

$serverData = [
          {
            'abc' => [
                       {
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'zone' => '5.9'
                                                 }
                                      },
                                    ],
                         'password' => 'default',
                         'name' => 'test2',
                         'schema' => 12345,
                         'ipaddress' => '10.10.10.10',
                         'username' => 'admin'
                       }
                     ]
          }
];
$testResult = $compareObj->CompareDataStructures($userData, $serverData);
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 2: Negative Test for \'equal_to\' Failed!!!\n\n";
   $tb->load(["2", "Negative test for \'equal_to\'", "Failed"]);
   $failCount++;
} else {
   print "Test 2: Negative Test for \'equal_to\' Passed\n\n";
   $tb->load(["2", "Negative test for \'equal_to\'", "Passed"]);
   $passCount++;
}





# Unit Test 3: Check if nested contain_once passes for negative scenario
$userData = [
   {
     'ip[?]contain_once' => [
        'a',
        'b'
     ]
   },
];

$serverData = [
   {
     'ip' => [
        'a',
        'b'
     ]
   },
   {
     'ip' => [
        'a',
        'b'
     ]
   },
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 3: Negative test for nested \'contain_once\' Failed!!!\n\n";
   $tb->load(["3", "Negative test for nested \'contain_once\'", "Failed"]);
   $failCount++;
} else {
   print "Test 3: Negative test for nested \'contain_once\' Passed\n\n";
   $tb->load(["3", "Negative test for nested \'contain_once\'", "Passed"]);
   $passCount++;
}




# Unit Test 4: Check if contain_once passes for positive scenario
$userData = [
   {
     'ip' => '10.10.10.10',
     'mac' => 'A3::BB::CC::DD::EE::FF'
   },
   {
     'ip' => '10.10.10.10',
     'mac' => 'A1::BB::CC::DD::EE::FF'
   }
];

$serverData = [
   {
     'ip' => '10.10.10.10',
     'mac' => 'A1::BB::CC::DD::EE::FF'
   },
   {
     'ip' => '10.10.10.10',
     'mac' => 'A2::BB::CC::DD::EE::FF'
   },
   {
     'ip' => '10.10.10.10',
     'mac' => 'A3::BB::CC::DD::EE::FF'
   }
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 4: Positive test for \'contain_once\' Failed!!!\n\n";
   $tb->load(["4", "Positive test for \'contain_once\'", "Failed"]);
   $failCount++;
} else {
   print "Test 4: Positive test for \'contain_once\' Passed\n\n";
   $tb->load(["4", "Positive test for \'contain_once\'", "Passed"]);
   $passCount++;
}



# Unit Test 5: Check if contain_once passes for negative scenarios
$userData = [
   {
     'ip' => '10.10.10.10',
     'mac' => 'A3::BB::CC::DD::EE::FF'
   },
   {
     'ip' => '10.10.10.10',
     'mac' => 'A1::BB::CC::DD::EE::FF'
   }
];

$serverData = [
          {
            'ip' => '10.10.10.10',
            'mac' => 'A1::BB::CC::DD::EE::FF'
          },
          {
            'ip' => '10.10.10.10',
            'mac' => 'A1::BB::CC::DD::EE::FF'
          },
          {
            'ip' => '10.10.10.10',
            'mac' => 'A1::BB::CC::DD::EE::FF'
          },
          {
            'ip' => '10.10.10.10',
            'mac' => 'A3::BB::CC::DD::EE::FF'
          }
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 5: Negative test for \'contain_once\' Failed!!!\n\n";
   $tb->load(["5", "Negative test for \'contain_once\'", "Failed"]);
   $failCount++;
} else {
   print "Test 5: Negative test for \'contain_once\' Passed\n\n";
   $tb->load(["5", "Negative test for \'contain_once\'", "Passed"]);
   $passCount++;
}


# Unit Test 6: Check if contains passes for positive scenario
$userData = [
   {
     'ip' => '10.10.10.10',
     'mac' => 'A3::BB::CC::DD::EE::FF'
   },
   {
     'ip' => '10.10.10.10',
     'mac' => 'A1::BB::CC::DD::EE::FF'
   }
];

$serverData = [
          {
            'ip' => '10.10.10.10',
            'mac' => 'A1::BB::CC::DD::EE::FF'
          },
          {
            'ip' => '10.10.10.10',
            'mac' => 'A2::BB::CC::DD::EE::FF'
          },
          {
            'ip' => '10.10.10.10',
            'mac' => 'A3::BB::CC::DD::EE::FF'
          }
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contains');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 6: Positive test for \'contains\' Failed!!!\n\n";
   $tb->load(["6","Positive test for \'contains\'", "Failed"]);
   $failCount++;
} else {
   print "Test 6: Positive test for \'contains\' Passed\n\n";
   $tb->load(["6","Positive test for \'contains\'", "Passed"]);
   $passCount++;
}


# Unit Test 7: Check if contains passes for negative scenarios
$userData = [
   {
     'ip' => '10.10.10.10',
     'mac' => 'A9::BB::CC::DD::EE::FF'
   },
];

$serverData = [
          {
            'ip' => '10.10.10.10',
            'mac' => 'A1::BB::CC::DD::EE::FF'
          },
          {
            'ip' => '10.10.10.10',
            'mac' => 'A1::BB::CC::DD::EE::FF'
          },
          {
            'ip' => '10.10.10.10',
            'mac' => 'A3::BB::CC::DD::EE::FF'
          }
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contains');
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 7: Negative test for \'contains\' Failed!!!\n\n";
   $tb->load(["7", "Negative test for \'contains\'", "Failed"]);
   $failCount++;
} else {
   print "Test 7: Negative test for \'contains\' Passed\n\n";
   $tb->load(["7", "Negative test for \'contains\'", "Passed"]);
   $passCount++;
}


# Unit Test 8: Check if not_contains passes for positive scenario
$userData = [
   {
     'ip' => '11.10.10.10',
     'mac' => 'A5::BB::CC::DD::EE::FF'
   },
   {
     'ip' => '11.10.10.10',
     'mac' => 'A6::BB::CC::DD::EE::FF'
   }
];

$serverData = [
          {
            'ip' => '10.10.10.10',
            'mac' => 'A1::BB::CC::DD::EE::FF'
          },
          {
            'ip' => '10.10.10.10',
            'mac' => 'A2::BB::CC::DD::EE::FF'
          },
          {
            'ip' => '10.10.10.10',
            'mac' => 'A3::BB::CC::DD::EE::FF'
          }
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'not_contains');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 8: Positive test for \'not_contains\' Failed!!!\n\n";
   $tb->load(["8", "Positive test for \'not_contains\'", "Failed"]);
   $failCount++;
} else {
   print "Test 8: Positive test for \'not_contains\' Passed\n\n";
   $tb->load(["8", "Positive test for \'not_contains\'", "Passed"]);
   $passCount++;
}


# Unit Test 9: Check if not_contains passes for negative scenarios
$userData = [
   {
     'ip' => '10.10.10.10',
     'mac' => 'A3::BB::CC::DD::EE::FF'
   },
];

$serverData = [
          {
            'ip' => '10.10.10.10',
            'mac' => 'A1::BB::CC::DD::EE::FF'
          },
          {
            'ip' => '10.10.10.10',
            'mac' => 'A1::BB::CC::DD::EE::FF'
          },
          {
            'ip' => '10.10.10.10',
            'mac' => 'A3::BB::CC::DD::EE::FF'
          }
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'not_contains');
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 9: Negative test for \'not_contains\' Failed!!!\n\n";
   $tb->load(["9", "Negative test for \'not_contains\'", "Failed"]);
   $failCount++;
} else {
   print "Test 9: Negative test for \'not_contains\' Passed\n\n";
   $tb->load(["9", "Negative test for \'not_contains\'", "Passed"]);
   $passCount++;
}


# Unit Test 10: Check if nested contain_once passes for positive scenario
$userData = [
   {
     'ip[?]contain_once' => [
        'a',
        'b'
     ]
   },
];

$serverData = [
   {
     'ip' => [
        'a',
        'b'
     ]
   },
   {
     'id' => [
        'c',
        'd'
     ]
   },
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 10: Positive test for nested \'contain_once\' Failed!!!\n\n";
   $tb->load(["10", "Positive test for nested \'contain_once\'", "Failed"]);
   $failCount++;
} else {
   print "Test 10: Positive test for nested \'contain_once\' Passed\n\n";
   $tb->load(["10", "Positive test for nested \'contain_once\'", "Passed"]);
   $passCount++;
}


# Unit Test 11: Check if array in hash for contains for positive scenarios
$userData = [
          {
            'sourceaddrs' => [
                               '192.168.1.1',
                               '192.168.1.2'
                             ],
            'mcastversion' => '3',
            'groupaddr' => '239.1.1.1',
            'mcastmode' => 'exclude',
            'mcastprotocol' => 'IGMP'
          }
];

$serverData = [
          {
            'sourceaddrs' => [
                               '192.168.1.2',
                               '192.168.1.1'
                             ],
            'mcastversion' => '3',
            'groupaddr' => '239.1.1.1',
            'mcastmode' => 'exclude',
            'mcastprotocol' => 'IGMP'
          }
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 11: Positive test for array in hash for \'contain_once\' Failed!!!\n\n";
   $tb->load(["11", "Positive test for array in hash for \'contain_once\'", "Passed"]);
   $failCount++;
} else {
   print "Test 11: Positive test for array in hash for  \'contain_once\' Passed\n\n";
   $tb->load(["11", "Positive test for array in hash for \'contain_once\'", "Passed"]);
   $passCount++;
}


# Unit Test 12: Check if not_contains passes for empty server data
$userData = [
   {
     'ip' => '11.10.10.10',
     'mac' => 'A5::BB::CC::DD::EE::FF'
   },
   {
     'ip' => '11.10.10.10',
     'mac' => 'A6::BB::CC::DD::EE::FF'
   }
];

$serverData = [
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'not_contains');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 12: Positive test for \'not_contains\' for empty server data Failed!!!\n\n";
   $tb->load(["12", "Positive test for \'not_contains\' for empty server data", "Failed"]);
   $failCount++;
} else {
   print "Test 12: Positive test for \'not_contains\' for empty server data Passed\n\n";
   $tb->load(["12", "Positive test for \'not_contains\' for empty server data", "Passed"]);
   $passCount++;
}


# Unit Test 13: Check if nested contain_once passes for complex positive scenario
$userData = [
   {
     'ip[?]contain_once' => [
        'a',
        'b'
     ]
   },
];

$serverData = [
   {
     'ip' => [
        'a',
        'b'
     ]
   },
   {
     'id' => [
        'a',
        'b'
     ]
   },
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 13: Positive test for nested \'contain_once\' for complex structure Failed!!!\n\n";
   $tb->load(["13", "Positive test for nested \'contain_once\' for complex structure", "Failed"]);
   $failCount++;
} else {
   print "Test 13: Positive test for nested \'contain_once\' for complex structure Passed\n\n";
   $tb->load(["13", "Positive test for nested \'contain_once\' for complex structure", "Passed"]);
   $passCount++;
}


# Unit Test 14: Check if nested not_contains passes for complex positive scenario
# Currently this test is suppose to fail
$userData = [
   {
     'ip[?]not_contains' => [
        'a',
        'b'
     ]
   },
];

$serverData = [
   {
     'ip' => [
        'a1',
        'b1'
     ]
   },
   {
     'ip' => [
        'a2',
        'b2'
     ]
   },
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'not_contains');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 14: Positive test for nested \'not_contains\' for complex structure Failed!!!\n\n";
   $tb->load(["14", "Positive test for nested \'not_contains\' for complex structure", "Failed"]);
   $failCount++;
} else {
   print "Test 14: Positive test for nested \'not_contains\' for complex structure Passed\n\n";
   $tb->load(["14", "Positive test for nested \'not_contains\' for complex structure", "Passed"]);
   $passCount++;
}


# Unit Test 15: Check if nested contains fails for empty user data
$userData = [
];

$serverData = [
   {
     'ip' => [
        'a1',
        'b1'
     ]
   },
   {
     'ip' => [
        'a2',
        'b2'
     ]
   },
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contains');
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 15: Negative test for \'contains\' for empty user data Failed!!!\n\n";
   $tb->load(["15", "Negative test for \'contains\' for empty user data", "Failed"]);
   $failCount++;
} else {
   print "Test 15: Negative test for \'contains\' for empty user data Passed\n\n";
   $tb->load(["15", "Negative test for nested \'contains\' for empty user data", "Passed"]);
   $passCount++;
}


# Unit Test 16: Check if boolean passes for positive test
$userData = [
          {
            'abc' => [
                       {
                         'services1[?]boolean' => undef,
                         'services2[?]boolean' => undef,
                         'services3[?]boolean' => undef,
                         'services4[?]boolean' => undef,
                       }
                     ]
          }
];

$serverData = [
          {
            'abc' => [
                       {
                         'services1' => 'false',
                         'services2' => 'true',
                         'services3' => 1,
                         'services4' => 0,
                       }
                     ]
          }
];
$testResult = $compareObj->CompareDataStructures($userData, $serverData);
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 16: Positive test for \'boolean\' Failed!!!\n\n";
   $tb->load(["16", "Positive test for \'boolean\'", "Failed"]);
   $failCount++;
} else {
   print "Test 16: Positive test for \'boolean\' Passed\n\n";
   $tb->load(["16", "Positive test for \'boolean\'", "Passed"]);
   $passCount++;
}


# Unit Test 17: Check if boolean passes for negative test
$userData = [
          {
            'abc' => [
                       {
                         'services[?]boolean' => undef,
                       }
                     ]
          }
];

$serverData = [
          {
            'abc' => [
                       {
                         'services' => "1234",
                       }
                     ]
          }
];
$testResult = $compareObj->CompareDataStructures($userData, $serverData);
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 17: Negative test for \'boolean\' Failed!!!\n\n";
   $tb->load(["17", "Negative test for \'boolean\'", "Failed"]);
   $failCount++;
} else {
   print "Test 17: Negative test for \'boolean\' Passed\n\n";
   $tb->load(["17", "Negative test for \'boolean\'", "Passed"]);
   $passCount++;
}


# Unit Test 18: Check contain_once at nested and not global for positive scenario
$userData = [
   {
     'sourceaddrs[?]contain_once' => [
                        '192.168.1.1',
                        '192.168.1.2'
                      ],
     'mcastprotocol[?]equal_to' => 'IGMP',
     'groupaddr[?]equal_to' => '239.1.1.1',
     'mcastmode[?]equal_to' => 'exclude',
     'mcastversion[?]equal_to' => '3'
   }
];

$serverData = [
   {
     'sourceaddrs' => [
                        '192.168.1.1',
                        '192.168.1.2'
                      ],
     'mcastversion' => '3',
     'groupaddr' => '239.1.1.1',
     'mcastmode' => 'exclude',
     'mcastprotocol' => 'IGMP'
   }
];
$testResult = $compareObj->CompareDataStructures($userData, $serverData);
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 18: Positive test for \'contain_once\' at nested and not global Failed!!!\n\n";
   $tb->load(["18", "Positive test for \'contain_once\' at nested and not global", "Failed"]);
   $failCount++;
} else {
   print "Test 18: Positive test for \'contain_once\' at nested and not global Passed\n\n";
   $tb->load(["18", "Positive test for \'contain_once\' at nested and not global", "Passed"]);
   $passCount++;
}


# Unit Test 19: Check contain_once at global level for jumbled array positive scenario
$userData = [
          {
            'sslenabled' => 'false',
            'server' => '10.144.136.199',
            'port' => '1234'
          }
        ];

$serverData = [
          {
            'server' => '10.144.136.200',
            'sslenabled' => 'false',
            'port' => '1234'
          },
          {
            'server' => '10.144.136.199',
            'sslenabled' => 'false',
            'port' => '1234'
          },
          {
            'server' => '10.144.136.201',
            'sslenabled' => 'false',
            'port' => '1234'
          }
        ];
$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 19: Positive test for \'contain_once\' at global level for jumbled array Failed!!!\n\n";
   $tb->load(["19", "Positive test for \'contain_once\' at global level for jumbled array", "Failed"]);
   $failCount++;
} else {
   print "Test 19: Positive test for \'contain_once\' at global level for jumbled array Passed\n\n";
   $tb->load(["19", "Positive test for \'contain_once\' at global level for jumbled array", "Passed"]);
   $passCount++;
}


# Unit Test 20: Check contain_once at global level for jumbled array negative scenario
$userData = [
          {
            'sslenabled' => 'false',
            'server' => '10.144.136.199',
            'port' => '1234'
          }
        ];

$serverData = [
          {
            'server' => '10.144.136.200',
            'sslenabled' => 'false',
            'port' => '1234'
          },
          {
            'server' => '10.144.136.199',
            'sslenabled' => 'false',
            'port' => '1234'
          },
          {
            'server' => '10.144.136.201',
            'sslenabled' => 'false',
            'port' => '1234'
          },
          {
            'server' => '10.144.136.199',
            'sslenabled' => 'false',
            'port' => '1234'
          },
        ];
$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 20: Negative test for \'contain_once\' at global level for jumbled array Failed!!!\n\n";
   $tb->load(["20", "Negative test for \'contain_once\' at global level for jumbled array", "Failed"]);
   $failCount++;
} else {
   print "Test 20: Negative test for \'contain_once\' at global level for jumbled array Passed\n\n";
   $tb->load(["20", "Negative test for \'contain_once\' at global level for jumbled array", "Passed"]);
   $passCount++;
}


# Unit Test 21: Check contain_once for global level for duplicates at nested
# here, the user doesn't give contain_once for sourceaddrs but rather gives
# contain_once at global level. For this scenario, the operator should return
# contain_once.
$userData = [
   {
     'sourceaddrs[?]' => [
                        '192.168.1.1',
                        '192.168.1.1',
                        '192.168.1.2'
                      ],
     'mcastprotocol[?]equal_to' => 'IGMP',
     'groupaddr[?]equal_to' => '239.1.1.1',
     'mcastmode[?]equal_to' => 'exclude',
     'mcastversion[?]equal_to' => '3'
   }
];

$serverData = [
   {
     'sourceaddrs' => [
                        '192.168.1.1',
                        '192.168.1.2'
                      ],
     'mcastversion' => '3',
     'groupaddr' => '239.1.1.1',
     'mcastmode' => 'exclude',
     'mcastprotocol' => 'IGMP'
   }
];
$testResult = $compareObj->CompareDataStructures($userData, $serverData, 'contain_once');
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 21: Positive test for \'contain_once\' at global level for duplicates at nested Failed!!!\n\n";
   $tb->load(["21", "Positive test for \'contain_once\' at global level for duplicates at nested", "Failed"]);
   $failCount++;
} else {
   print "Test 21: Positive test for \'contain_once\' at global level for duplicates at nested Passed\n\n";
   $tb->load(["21", "Positive test for \'contain_once\' at global level for duplicates at nested", "Passed"]);
   $passCount++;
}


# Unit Test 22: Check if contain_once passes for empty server data
$userData = [
   {
     'ip' => '11.10.10.10',
     'mac' => 'A5::BB::CC::DD::EE::FF'
   },
];

$serverData = [
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 22: Negative test for \'contain_once\' for empty server data Failed!!!\n\n";
   $tb->load(["22", "Negative test for \'contain_once\' for empty server data", "Failed"]);
   $failCount++;
} else {
   print "Test 22: Negative test for \'contain_once\' for empty server data Passed\n\n";
   $tb->load(["22", "Negative test for \'contain_once\' for empty server data", "Passed"]);
   $passCount++;
}

# Unit Test 23: Check if contain_once fails for one mismatch for negative case
$userData =  [
          {
            'sourceaddrs[?]contain_once' => [
               '2002010001',
               '2002010003'
            ]
          }
];
$serverData = [
          {
            'sourceaddrs' => [
                               '2002010001',
                               '2002010002'
                             ],
          }
];
$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 23: Negative test for \'contain_once\' for one mismatch Failed!!!\n\n";
   $tb->load(["23", "Negative test for \'contain_once\' for one mismatch", "Failed"]);
   $failCount++;
} else {
   print "Test 23: Negative test for \'contain_once\' for one mismatch Passed\n\n";
   $tb->load(["23", "Negative test for \'contain_once\' for one mismatch", "Passed"]);
   $passCount++;
}

# Unit Test 24: Check if contain_once/equal_to in nested for positive case
$userData = [
    {
        "static_routes[?]contain_once"  => [
            {
               "destination_cidr" => '192.168.10.0/24',
               "next_hop"         => '192.168.10.5',
             },
        ],
        "dns_nameservers[?]contain_once"   => ['10.10.10.11', '10.10.10.12'],
        "allocation_ranges[?]contain_once" => [
            {
                "start"   => '192.168.1.2',
                 "end"     => '192.168.1.6',
            },
            {
                "start"  => '192.168.1.10',
                "end"    => '192.168.1.100'
            },
        ],
        "gateway_ip[?]equal_to"  => '192.168.1.1',
        "ip_version[?]equal_to"  => 4,
        "cidr[?]equal_to"        => '192.168.1.0/24',
    },
];
$serverData = [
    {
        "static_routes"  => [
            {
               "destination_cidr" => '192.168.10.0/24',
               "next_hop"         => '192.168.10.5',
             },
        ],
        "dns_nameservers"   => ['10.10.10.11', '10.10.10.12'],
        "allocation_ranges" => [
            {
                "start"   => '192.168.1.2',
                 "end"     => '192.168.1.6',
            },
            {
                "start"  => '192.168.1.10',
                "end"    => '192.168.1.100'
            },
        ],
        "gateway_ip"  => '192.168.1.1',
        "ip_version"  => 4,
        "cidr"        => '192.168.1.0/24',
    },
];
$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 24: Positive test for nested \'contain_once\/equal_to\' Failed!!!\n\n";
   $tb->load(["24", "Positive test for nested \'contain_once\'", "Failed"]);
   $failCount++;
} else {
   print "Test 24: Positive test for nested \'contain_once\' Passed\n\n";
   $tb->load(["24", "Positive test for nested \'contain_once\'", "Passed"]);
   $passCount++;
}


# Unit Test 25: Check  equal_to for global level for positive case
$userData = [
    {
        "static_routes"  => [
            {
               "destination_cidr" => '192.168.10.0/24',
               "next_hop"         => '192.168.10.5',
             },
        ],
        "dns_nameservers"   => ['10.10.10.11', '10.10.10.12'],
        "allocation_ranges" => [
            {
                "start"   => '192.168.1.2',
                 "end"     => '192.168.1.6',
            },
            {
                "start"  => '192.168.1.10',
                "end"    => '192.168.1.100'
            },
        ],
        "gateway_ip"  => '192.168.1.1',
        "ip_version"  => 4,
        "cidr"        => '192.168.1.0/24',
    },
];
$serverData = [
    {
        "static_routes"  => [
            {
               "destination_cidr" => '192.168.10.0/24',
               "next_hop"         => '192.168.10.5',
             },
        ],
        "dns_nameservers"   => ['10.10.10.11', '10.10.10.12'],
        "allocation_ranges" => [
            {
                "start"   => '192.168.1.2',
                 "end"     => '192.168.1.6',
            },
            {
                "start"  => '192.168.1.10',
                "end"    => '192.168.1.100'
            },
        ],
        "gateway_ip"  => '192.168.1.1',
        "ip_version"  => 4,
        "cidr"        => '192.168.1.0/24',
    },
];
$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'equal_to');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 25: Positive test for global \'equal_to\' Failed!!!\n\n";
   $tb->load(["25", "Positive test for global \'equal_to\'", "Failed"]);
   $failCount++;
} else {
   print "Test 25: Positive test for global \'equal_to\' Passed\n\n";
   $tb->load(["25", "Positive test for global \'equal_to\'", "Passed"]);
   $passCount++;
}


# Unit Test 26: Check  equal_to for global level for negative case
$userData = [
    {
        "static_routes"  => [
            {
               "destination_cidr" => '192.168.10.0/24',
               "next_hop"         => '192.168.10.5',
             },
        ],
        "dns_nameservers"   => ['10.10.10.11', '10.10.10.12'],
        "allocation_ranges" => [
            {
                "start"   => '192.168.1.2',
                 "end"     => '192.168.1.6',
            },
            {
                "start"  => '192.168.1.10',
                "end"    => '192.168.1.101'
            },
        ],
        "gateway_ip"  => '192.168.1.1',
        "ip_version"  => 4,
        "cidr"        => '192.168.1.0/24',
    },
];
$serverData = [
    {
        "static_routes"  => [
            {
               "destination_cidr" => '192.168.10.0/24',
               "next_hop"         => '192.168.10.5',
             },
        ],
        "dns_nameservers"   => ['10.10.10.11', '10.10.10.12'],
        "allocation_ranges" => [
            {
                "start"   => '192.168.1.2',
                 "end"     => '192.168.1.6',
            },
            {
                "start"  => '192.168.1.10',
                "end"    => '192.168.1.100'
            },
        ],
        "gateway_ip"  => '192.168.1.1',
        "ip_version"  => 4,
        "cidr"        => '192.168.1.0/24',
    },
];
$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'equal_to');
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 26: Negative test for global \'equal_to\' Failed!!!\n\n";
   $tb->load(["26", "Negative test for global \'equal_to\'", "Failed"]);
   $failCount++;
} else {
   print "Test 26: Negative test for global \'equal_to\' Passed\n\n";
   $tb->load(["26", "Negative test for global \'equal_to\'", "Passed"]);
   $passCount++;
}



# Unit Test 27: Positive Diff operation scenario
$logDir = "/tmp/vdnet/";
$current = [
          {
            'abc' => [
                       {
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'zone' => '6.0'
                                                 }
                                      },
                                    ],
                         'password' => 'default',
                         'name' => 'test2',
                         'schema' => 12345,
                         'ipaddress' => '10.10.10.10',
                         'username' => 'admin'
                       }
                     ]
          }
];
$result = VDNetLib::Workloads::Utilities::StoreDataToFile($current,$logDir);
$previous = [
          {
            'abc' => [
                       {
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'zone' => '6.0'
                                                 }
                                      },
                                    ],
                         'password' => 'default',
                         'name' => 'test2',
                         'schema' => 12345,
                         'ipaddress' => '10.10.10.10',
                         'username' => 'admin'
                       }
                     ]
          }
];
$result = VDNetLib::Workloads::Utilities::StoreDataToFile($previous,$logDir);
$currentLogLocation = $logDir . '/' . 'current.log';
$previousLogLocation = $logDir . '/' . 'previous.log';
$currentHash = VDNetLib::Workloads::Utilities::GetDataFromFile($currentLogLocation);
$previousHash = VDNetLib::Workloads::Utilities::GetDataFromFile($previousLogLocation);
$diff = $compareObj->GetDiffBetweenDataStructures($currentHash, $previousHash);
$userData = [
          {
            'abc' => [
                       {
                         'password[?]equal_to' => 'default',
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'zone[?]equal_to' => '0'
                                                 }
                                      },
                                    ],
                         'ipaddress[?]equal_to' => '10.10.10.10',
                         'schema[?]equal_to' => '0',
                         'username[?]equal_to' => 'admin',
                         'name[?]equal_to' => 'test2'
                       }
                     ]
          }
];
$testResult = $compareObj->CompareDataStructures($userData, $diff);
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 27: Positive Test for \'diff\' Failed!!!\n\n";
   $tb->load(["27", "Positive test for \'diff\'", "Failed"]);
   $failCount++;
} else {
   print "Test 27: Positive Test for \'diff\' Passed\n\n";
   $tb->load(["27", "Positive test for \'diff\'", "Passed"]);
   $passCount++;
}


# Unit Test 28: Negative Diff operation scenario
$logDir = "/tmp/vdnet/";
$current = [
          {
            'abc' => [
                       {
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'zone' => '6.0'
                                                 }
                                      },
                                    ],
                         'password' => 'default',
                         'name' => 'test2',
                         'schema' => 12345,
                         'ipaddress' => '10.10.10.10',
                         'username' => 'admin'
                       }
                     ]
          }
];
$result = VDNetLib::Workloads::Utilities::StoreDataToFile($current,$logDir);
$previous = [
          {
            'abc' => [
                       {
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'zone' => '5.9'
                                                 }
                                      },
                                    ],
                         'password' => 'default',
                         'name' => 'test2',
                         'schema' => 12345,
                         'ipaddress' => '10.10.10.10',
                         'username' => 'admin'
                       }
                     ]
          }
];
$result = VDNetLib::Workloads::Utilities::StoreDataToFile($previous,$logDir);
$currentLogLocation = $logDir . '/' . 'current.log';
$previousLogLocation = $logDir . '/' . 'previous.log';
$currentHash = VDNetLib::Workloads::Utilities::GetDataFromFile($currentLogLocation);
$previousHash = VDNetLib::Workloads::Utilities::GetDataFromFile($previousLogLocation);
$diff = $compareObj->GetDiffBetweenDataStructures($currentHash, $previousHash);
$userData = [
          {
            'abc' => [
                       {
                         'password[?]equal_to' => 'default',
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'zone[?]equal_to' => '0'
                                                 }
                                      },
                                    ],
                         'ipaddress[?]equal_to' => '10.10.10.10',
                         'schema[?]equal_to' => '0',
                         'username[?]equal_to' => 'admin',
                         'name[?]equal_to' => 'test2'
                       }
                     ]
          }
];
$testResult = $compareObj->CompareDataStructures($userData, $diff);
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 28: Negative Test for \'diff\' Failed!!!\n\n";
   $tb->load(["28", "Negative test for \'diff\'", "Failed"]);
   $failCount++;
} else {
   print "Test 28: Negative Test for \'diff\' Passed\n\n";
   $tb->load(["28", "Negative test for \'diff\'", "Passed"]);
   $passCount++;
}


# Unit Test 29: Check contains_once simple array for negative scenario
$userData = {
   "ip[?]contain_once" => ['10.10.10.12', '10.10.10.11'],
};

$serverData = {
   "ip" => ['10.10.10.11', '10.10.10.12', '10.10.10.12'],
};

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData);
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 29: Negative test for simple array \'contain_once\' Failed!!!\n\n";
   $tb->load(["29", "Negative test for simple array \'contain_once\'", "Failed"]);
   $failCount++;
} else {
   print "Test 29: Negative test for simple array \'contain_once\' Passed\n\n";
   $tb->load(["29", "Negative test for simple array \'contain_once\'", "Passed"]);
   $passCount++;
}

# Unit Test 30: Check if LessThan/GreaterThan passes with positive values
$userData = [
          {
            'abc' => [
                       {
                         'length1[?]>' => '1500',
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'length2[?]<' => '1000'
                                                 }
                                      },
                                      #{
                                      #  'fgh' => {
                                      #             'length4[?]>' => '8000'
                                      #           }
                                      #}
                                    ],
                         'length3[?]<' => '100'
                       }
                     ]
          }
];

$serverData = [
          {
            'abc' => [
                       {
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'length2' => '800'
                                                 }
                                      },
                                      #{
                                      #  'fgh' => {
                                      #             'length4' => '8500'
                                      #           }
                                      #}
                                    ],
                         'length1' => '2000',
                         'length3' => '50'
                       }
                     ]
          }
];
$testResult = $compareObj->CompareDataStructures($userData, $serverData);
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 30: Positive test for \'LessThan or GreaterThan\' Failed!!!\n\n";
   $tb->load(["30", "Positive test for \'LessThan or GreaterThan\'", "Failed"]);
   $failCount++;
} else {
   print "Test 30: Positive test for \'LessThan or GreaterThan\' Passed\n\n";
   $tb->load(["30", "Positive test for \'LessThan or GreaterThan\'", "Passed"]);
   $passCount++;
}

# Unit Test 31: Check if LessThan/GreaterThan passes with negative values
$userData = [
          {
            'abc' => [
                       {
                         'length1[?]>' => '1500',
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'length2[?]<' => '1000'
                                                 }
                                      },
                                      #{
                                      #  'fgh' => {
                                      #             'length2[?]>' => '8000'
                                      #           }
                                      #}
                                    ],
                         'length3[?]<' => '100'
                       }
                     ]
          }
];

$serverData = [
          {
            'abc' => [
                       {
                         'array' => [
                                      {
                                        'cdf' => {
                                                   'length2' => '800'
                                                 }
                                      },
                                      #{
                                      #  'fgh' => {
                                      #             'length2' => '7500'
                                      #           }
                                      #}
                                    ],
                         'length1' => '2000',
                         'length3' => '150'
                       }
                     ]
          }
];
$testResult = $compareObj->CompareDataStructures($userData, $serverData);
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 31: Negative test for \'LessThan or GreaterThan\' Failed!!!\n\n";
   $tb->load(["31", "Negative test for \'LessThan or GreaterThan\'", "Failed"]);
   $failCount++;
} else {
   print "Test 31: Negative test for \'LessThan or GreaterThan\' Passed\n\n";
   $tb->load(["31", "Negative test for \'LessThan or GreaterThan\'", "Passed"]);
   $passCount++;
}

# Unit Test 32: Check if not_contains passes for hash scenario
$userData = [
   {
     'adapter_ip' => '192.168.1.12',
     'adapter_mac' => 'ff:ff:ff:ff:ff:ff'
   },
   {
     'adapter_ip' => '192.168.1.32',
     'adapter_mac' => '00:0c:29:7c:ad:aa'
   },
];

$serverData = [
   {
     'adapter_mac' => '00:0c:29:89:29:12',
     'adapter_ip' => '192.168.1.12'
   },
   {
     'adapter_mac' => '00:0c:29:7c:ad:aa',
     'adapter_ip' => '192.168.1.56'
   },
   {}
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'not_contains');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 32: Positive test for \'not_contains\' in Hash Failed!!!\n\n";
   $tb->load(["32", "Positive test for \'not_contains\' in Hash", "Failed"]);
   $failCount++;
} else {
   print "Test 32: Positive test for \'not_contains\' in Hash Passed\n\n";
   $tb->load(["32", "Positive test for \'not_contains\' in Hash", "Passed"]);
   $passCount++;
}

# Unit Test 33: Check ip address within an range for positive test
$userData = {
   "ip[?]ip_range" => '192.168.1.1-192.168.1.10',
   "ip2[?][]" => '192.168.1.1-192.168.1.10',
};

$serverData = {
   "ip" => '192.168.1.9',
   "ip2" => '192.168.1.2-192.168.1.5',
};

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData);
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 33:  Positive test for ip \'within\' a range !!!\n\n";
   $tb->load(["33", "Positive test for ip \'within\' a range", "Failed"]);
   $failCount++;
} else {
   print "Test 33: Positive test for ip \'within\' a range Passed\n\n";
   $tb->load(["33", "Positive test for ip \'within\' a range", "Passed"]);
   $passCount++;
}

# Unit Test 34: Check ip address within an range for negative test
$userData = {
   "ip[?][]" => '192.168.1.10-192.168.1.11',
};

$serverData = {
   "ip" => '192.168.1.9',
};

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData);
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 34:  Negative test for ip \'within\' a range !!!\n\n";
   $tb->load(["34", "Negative test for ip \'within\' a range", "Failed"]);
   $failCount++;
} else {
   print "Test 34: Negative test for ip \'within\' a range Passed\n\n";
   $tb->load(["34", "Negative test for ip \'within\' a range", "Passed"]);
   $passCount++;
}

# Unit Test 35: Check operator for arrray container
$userData = {
    'result_count[?]equal_to' => 8,
    'results[?]equal_to' => [
                              {
                                'service_name' => 'snmp'
                              },
                              {
                                'service_name' => 'proton'
                              },
                              {
                                'service_name' => 'syslog'
                              },
                              {
                                'service_name' => 'ntp'
                              },
                              {
                                'service_name' => 'httpd'
                              },
                              {
                                'service_name' => 'rabbitmq'
                              },
                              {
                                'service_name' => 'ssh'
                              },
                              {
                                'service_name' => 'appmgmt'
                              }
                            ]
};

$serverData = {
    'result_count' => 8,
    'sort_by' => undef,
    'cursor' => undef,
    'sort_ascending' => undef,
    'results' => [
                   {
                     'service_name' => 'snmp',
                     '_schema' => undef,
                     '_self' => {
                                  'rel' => undef,
                                  'href' => undef,
                                  'action' => undef
                                },
                     '_links' => []
                   },
                   {
                     'service_name' => 'proton',
                     '_schema' => undef,
                     '_self' => {
                                  'rel' => undef,
                                  'href' => undef,
                                  'action' => undef
                                },
                     '_links' => []
                   },
                   {
                     'service_name' => 'syslog',
                     '_schema' => undef,
                     '_self' => {
                                  'rel' => undef,
                                  'href' => undef,
                                  'action' => undef
                                },
                     '_links' => []
                   },
                   {
                     'service_name' => 'ntp',
                     '_schema' => undef,
                     '_self' => {
                                  'rel' => undef,
                                  'href' => undef,
                                  'action' => undef
                                },
                     '_links' => []
                   },
                   {
                     'service_name' => 'httpd',
                     '_schema' => undef,
                     '_self' => {
                                  'rel' => undef,
                                  'href' => undef,
                                  'action' => undef
                                },
                     '_links' => []
                   },
                   {
                     'service_name' => 'rabbitmq',
                     '_schema' => undef,
                     '_self' => {
                                  'rel' => undef,
                                  'href' => undef,
                                  'action' => undef
                                },
                     '_links' => []
                   },
                   {
                     'service_name' => 'ssh',
                     '_schema' => undef,
                     '_self' => {
                                  'rel' => undef,
                                  'href' => undef,
                                  'action' => undef
                                },
                     '_links' => []
                   },
                   {
                     'service_name' => 'appmgmt',
                     '_schema' => undef,
                     '_self' => {
                                  'rel' => undef,
                                  'href' => undef,
                                  'action' => undef
                                },
                     '_links' => []
                   }
                 ]
};

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData);
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 35:  Positive test for operator on array container !!!\n\n";
   $tb->load(["35", "Positive test for operator on array contianer", "Failed"]);
   $failCount++;
} else {
   print "Test 35: Positive test for operator on array container Passed\n\n";
   $tb->load(["35", "Positive test for operator on array container", "Passed"]);
   $passCount++;
}

# Unit Test 36: Check if is_between passes with negative values
$userData = [
          {
            'abc' => [
                       {
                         'data[?]is_between' => '100-1000',
                       }
                     ]
          }
];

$serverData = [
          {
            'abc' => [
                       {
                         'data' => '90',
                       }
                     ]
          }
];
$testResult = $compareObj->CompareDataStructures($userData, $serverData);
$expectedResult = "FAILURE";
if ($testResult ne $expectedResult) {
   print "Test 36: Negative test for is_between Failed!!!\n\n";
   $tb->load(["36", "Negative test for is_between", "Failed"]);
   $failCount++;
} else {
   print "Test 36: Negative test for is_between Passed\n\n";
   $tb->load(["36", "Negative test for is_between", "Passed"]);
   $passCount++;
}

# Unit Test 37: Check if is_between passes with positive values
$userData = [
          {
            'abc' => [
                       {
                         'data[?]is_between' => '100-1000',
                       }
                     ]
          }
];

$serverData = [
          {
            'abc' => [
                       {
                         'data' => '110',
                       }
                     ]
          }
];
$testResult = $compareObj->CompareDataStructures($userData, $serverData);
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 37:  Positive test for is_between !!!\n\n";
   $tb->load(["37", "Positive test for is_between", "Failed"]);
   $failCount++;
} else {
   print "Test 37: Positive test for is_between Passed\n\n";
   $tb->load(["37", "Positive test for is_between", "Passed"]);
   $passCount++;
}

# Unit Test 38: Check if contain_once passes with undef keys in server data.
$userData = [
   {
     'adapter_ip' => ['192.168.1.12']
   },
];

$serverData = [
   {
     'adapter_ip' => undef
   },
   {
     'adapter_ip' => ['192.168.1.12']
   },
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contain_once');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 38: Positive test for \'contain_once\' with undef keys in Hash Failed!!!\n\n";
   $tb->load(["38", "Positive test for \'contain_once\' with undef keys in Hash", "Failed"]);
   $failCount++;
} else {
   print "Test 38: Positive test for \'contain_once\' with undef keys in Hash Passed\n\n";
   $tb->load(["38", "Positive test for \'contain_once\' with undef keys in Hash", "Passed"]);
   $passCount++;
}

# Unit Test 39: check resulthash status_code and reason
$userData = [
    {
        'status_code' => 'FAILURE',
        'reason[?]match' => 'Failed to authenticate to Manager',
    },
];

$serverData = [
    {
        'status_code' => 'FAILURE',
        'reason' => 'Pexpect command: \'register-node 10.110.25.12 admin ee116b844f0244ebb553f15baf9af25f0acd0df79566d853ecef0878e224d49a invalid\' failed with error: \' Failed to authenticate to Manager\\n\\ncolo-nimbus-dhcp-28-156.eng.vmware.com(config)\'',
        'error' => 'None',
        'response_data' => 'None'
    },
    {
        'status_code' => 'EINLINE',
        'reason' => undef,
        'error' => undef,
        'response_data' => undef
    },
];

$testResult = $compareObj->CompareDataStructures($userData,
                                                 $serverData,
                                                 'contains');
$expectedResult = "SUCCESS";
if ($testResult ne $expectedResult) {
   print "Test 39: Positive test for resultHash with status_code and reason Failed!!!\n\n";
   $tb->load(["39", "Positive test for resultHash with status_code and reason", "Failed"]);
   $failCount++;
} else {
   print "Test 39: Positive test for resultHash with status_code and reason Passed\n\n";
   $tb->load(["39", "Positive test for resultHash with status_code and reason", "Passed"]);
   $passCount++;
}
# Test Summary Section

my $total = $passCount+$failCount;

print $tb;
print "\n--------------Test Summary-------------------------------";
print "\nTotal Tests: $total, Pass: $passCount, Fail: $failCount";
print "\nLogs: /tmp/vdnet/verificationUnitTest.log";
print "\n---------------------------------------------------------\n";

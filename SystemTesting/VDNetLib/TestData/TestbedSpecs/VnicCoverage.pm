package VDNetLib::TestData::TestbedSpecs::VnicCoverage;

$vmxnet3WithDefaults = {
   host => {
      '[1]' => {
         'vmnic'  => {
            '[1]' => {
               driver => "bnx2x",
            },

         },
      },
   },
   vm => {
      '[-1]' =>  {
         vnic  => {
            '[-1]'   => {
               driver => "vmxnet2",
            },
         },
      },
   },
};
1;

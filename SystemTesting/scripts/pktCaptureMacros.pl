use Data::Dumper;
my @packetLen;
my $fileName;
my $line;
my @temp;
my $sum=0;
my $item;
my $avgSize;
my $fileCount;
my $file;
my $i=0;
$fileName = $ARGV[0];
$fileCount = $ARGV[1];
$testName = $ARGV[2];
my %macro_hash;
if($testName =~ /COUNT/i || $testName =~ /AVGLEN/i || $testName =~ /MIN/i || $testName =~ /MAX/i){
   $file = $fileName;
   $i=1;
   while($fileCount != 0){
      $file = $file . ".tmp";
      open(FILE, $file)||die "could not open $file";
      while($line = <FILE>){
         @temp = split(/,/,$line);
         @temp = split(/:/,$temp[2]);
         if($temp[0] =~ /\w+\s+(\d+)/){
            push(@packetLen,$1);  
         }
      }
      $file = $fileName.$i;
      $i++;
      $fileCount--;
      close(FILE);
   }
   if($testName =~ /COUNT/i){
      $macro_hash{COUNT} = scalar(@packetLen);
   }
   if($testName =~ /AVGLEN/i){
      foreach $item (@packetLen){
         $sum = $sum + $item;  
      }
      $avgSize = $sum / scalar(@packetLen);
      $macro_hash{AVGLEN} = $avgSize;
   }
   if($testName =~ /MIN/i){ 
      @sortedArray = sort {$a <=> $b} (@packetLen);
      $macro_hash{MIN} = $sortedArray[0];
   }
   if($testName =~ /MAX/i){
      @sortedArray = sort {$a <=> $b} (@packetLen);
     $macro_hash{MAX} = $sortedArray[-1];
   }
}elsif($testName =~ /CHECKSUM/i){
   $i=1;
   $count = 0;
   $file = $fileName;
   open(FH,">>","$fileName.checksum")||die "could not open/create";
   while($fileCount!=0){
      $file = $file.".tmp";
      #print "opening $file\n";
      open(FILE,$file)||die "could not open $file";
      while($line=<FILE>){
         if($testName =~ /IP/i) {
            if($line =~ /bad chksum/){
               print FH $line;
               $count++;
            }
         }
         elsif($testName =~ /TCP/i) {
            if(($line =~ /bad tcp chksum/) || ($line =~ /incorrect/)){
               print FH $line;
               $count++;
            }
         }
         elsif($testName =~ /UDP/i) {
            if($line =~ /bad udp chksum/){
               print FH $line;
               $count++;
            }
         }else{
            if(($line =~ /bad/) || ($line =~ /incorrect/)){
               print FH $line;
               $count++;
            }
         }
       }
         $file = $fileName.$i;
         $i++;
         $fileCount--;
      
         close(FILE);
      
      $macro_hash{CHECKSUM} = $count;
      close(FH);
   }
}else{
    print "INVALID_MACRO: Invalid Test Name";
    exit(-1);
}
print Dumper(\%macro_hash);
exit(0);

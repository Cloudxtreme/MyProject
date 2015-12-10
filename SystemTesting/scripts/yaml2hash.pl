#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use lib "$FindBin::Bin/../VDNetLib/Workloads/";
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use File::Basename;
use Data::Dumper;
#use Storable qw(nstore store_fd nstore_fd freeze thaw dclone);
use VDNetLib::Common::Utilities;
use VDNetLib::Common::GlobalConfig;
use YAML;
use Text::Table;
use File::Slurp;
use Storable 'dclone';
use MediaWiki::API;

# Module
sub ConvertYAMLtoHash
{
   my $src = $_[0];
   my $dest = $_[1];
   my $keysdatabaseOrig = VDNetLib::Common::Utilities::ConvertYAMLToHash($src);
   # Prepare to dump server data in a file
   my $dumper = new Data::Dumper([$keysdatabaseOrig]);
   $dumper->Indent(1);
   # If Terse(0) is used then $VAR1 also
   #  get stored in the file.
   $dumper->Terse(1);
   $dumper->Quotekeys(0);
   # Serialized data is ready
   my $dumperValue = $dumper->Dump();
   my $destTdsHandle;
   open($destTdsHandle, ">", $dest);
   print $destTdsHandle $dumperValue;
   close($destTdsHandle)
}


sub ConvertHashtoYAML
{
   my $src = $_[0];
   my $dest = $_[1];
   my $srcTdsHandle;
   open($srcTdsHandle, "<", $src);
   my $file = do { $/=undef; <$srcTdsHandle> };
   close($srcTdsHandle);
   my $hash = eval $file;
   my $yaml = YAML::Dump $hash;
   my $destTdsHandle;
   open($destTdsHandle, ">", $dest);
   print $destTdsHandle $yaml;
   close($destTdsHandle);
}

# Check file
sub CheckFile
{
    my $file = $_[0];
    my $overwrite = $_[1];
    if (-e $file) {
        if ($overwrite) {
            print "Remove target $file\n";
            unlink $file;
            return 0;
        } else {
            print "Found target $file. Use -force to overwrite.\n";
            return 1;
        }
    }
}

# Main
if(@ARGV < 1) {
    print "Usage: $0 <yaml/hash file> [-force]\n";
} else {
    my $src = $ARGV[0];
    if (! -e $src)
    {
        print "Error: Cannot find file $src\n";
        exit(1);
    }
    my $overwrite = 0;
    if ($ARGV[1] eq "-force") {
        $overwrite = 1;
    }
    my $name;
    my $path;
    my $ext;
    ($name, $path, $ext) = fileparse($src, qr/\.[^.]*/);
    if ($ext eq ".yaml") {
        my $dest = $path.$name.'.json';
        if (CheckFile($dest, $overwrite) == 0) {
            print "Converting yaml $src to hash $dest\n";
            ConvertYAMLtoHash($src, $dest);
        }
    } elsif ($ext eq ".json" || $ext eq ".hash") {
        my $dest = $path.$name.'.yaml';
        if (CheckFile($dest, $overwrite) == 0) {
            print "Converting hash $src to yaml $dest\n";
            ConvertHashtoYAML($src, $dest);
        }
    } else {
        print "Error: Unsupported file extention: $ext\n";
    }
}

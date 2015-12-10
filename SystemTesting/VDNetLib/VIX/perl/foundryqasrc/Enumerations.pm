# TODO: The logical or operator converts the results
# to integer by default. Hence, although these values
# are interpreted as float, when used for logical
# OR, the result is an int.
# Need to figure out a fix for this.
# Until then, it is safe to use the enumerations
# such that the maximum value of the enumerations is
# less than the maximum value of integer 32 bit
package perl::foundryqasrc::Enumerations;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
# Currently exporting only the tags being used
our @EXPORT = qw(TP_REG_UNREG_DONTCARE
                 TP_UNREG_ON_SETUP
                 TP_DONT_CONNECT
                 TP_UNREG_ON_SETUP
                 TP_SHOULD_NOT_OPEN_VM
                 TP_WAIT_FOR_TOOLS
                 TP_LOGIN_IN_GUEST
                 TP_TEST_SUPPORTED_ON_WS
                 TP_TEST_SUPPORTED_ON_SERVER
                 TP_SHOULD_POWEROFF_VM_ON_CLEANUP
                 TP_RESTORE_VMX_DIRECTORY
                 TP_RESTORE_VMX_FILE_ONLY
                 TP_UNREG_ON_CLEANUP
                 TP_DONT_DISCONNECT_ON_CLEANUP
                 TP_HTU_HANDLE_VALID
                 TP_HTU_HANDLE_INVALID
                 TP_HTU_HANDLE_USE_HOST
                 TP_HTU_HANDLE_USE_VM
                 TP_HTU_HANDLE_INVALID
                 TP_HTU_HANDLE_USE_HOST
                 TP_HTU_HANDLE_USE_VM
                 TP_VM_POWERON_OPTION_LAUNCH_GUI
                 TP_TEST_SUPPORTED_ON_ESX);

# Perl does not support int64 inherently.
# It would convert the data type according to the number passed.

# to upgrade the tools in guest OS
# Not used, adding as a place holder
use constant TP_UPGRADE_GUEST_TOOLS => 0;

# login to guest OS, currently used in initializetestsetup()
use constant TP_LOGIN_IN_GUEST => 2 ** 0;

# to start the tools in the guest OS, currently used in initializetestsetup()
use constant TP_WAIT_FOR_TOOLS => 2 ** 1;

use constant TP_HTU_HANDLE_VALID => 2 ** 2;

use constant TP_HTU_HANDLE_INVALID => 2 ** 3;

use constant TP_HTU_HANDLE_USE_HOST => 2 ** 4;

use constant TP_HTU_HANDLE_USE_VM => 2 ** 5;

use constant TP_SHOULD_NOT_OPEN_VM => 2 ** 6;

use constant TP_SHOULD_POWEROFF_VM_ON_CLEANUP => 2 ** 7;

use constant TP_UNREG_ON_CLEANUP => 2 ** 8;

use constant TP_UNREG_ON_SETUP => 2 ** 9;

use constant TP_REG_UNREG_DONTCARE => 2 ** 10;

use constant TP_DONT_CONNECT => 2 ** 11;

use constant TP_DONT_DISCONNECT_ON_CLEANUP => 2 ** 12;

use constant TP_TEST_NOT_IMPLEMENTED => 2 ** 13;

use constant TP_TEST_SUPPORTED_ON_WS => 2 ** 14;

use constant TP_TEST_SUPPORTED_ON_SERVER => 2 ** 15;

# Not used, adding as a place holder
use constant TP_TEST_SUPPORTED_ON_ESX => 2 ** 16;

# Not used, adding as a place holder
use constant TP_VM_POWERON_OPTION_LAUNCH_GUI => 2 ** 17;

# The client has a linux arch
# Not used, adding as a place holder
use constant TP_LNX_CLIENT => 2 ** 18;

# The server has a linux arch
# Not used, adding as a place holder
use constant TP_LNX_SERVER => 2 ** 19;

# The client has a windows arch.
# Not used, adding as a place holder
use constant TP_WIN_CLIENT => 2 ** 20;

# The server has a windows arch.
# Not used, adding as a place holder
use constant TP_WIN_SERVER => 2 ** 21;

# backup the Vm related files only i.e. *.vmx, *.vmdk in the VMX directory
# Not used, adding as a place holder
use constant TP_BACKUP_VM_RELATED_FILES => 2 ** 22;

# backup the whole directory containing the vm
# Not used, adding as a place holder
use constant TP_BACKUP_VMX_DIRECTORY => 2 ** 23;

# backup the only the vmx file
# Not used, adding as a place holder
use constant TP_BACKUP_VMX_FILE_ONLY => 2 ** 24;

# invoke callback for the testing API
# Not used, adding as a place holder
use constant TP_TEST_CALLBACK => 2 ** 25;

# call OpenEx instead of Open in initializetestsetup()
# Not used, adding as a place holder
use constant TP_SHOULD_OPEN_EX => 2 ** 26;

# Not used, adding as a place holder
use constant TP_RESTORE_VMX_DIRECTORY => 2 ** 27;

# Not used, adding as a place holder
use constant TP_RESTORE_VMX_FILE_ONLY => 2 ** 28;

# Not used, adding as a place holder
use constant TP_WIN_GUEST => 2 ** 29;

# Not used, adding as a place holder
use constant TP_LNX_GUEST => 2 ** 30;

# Not used, adding as a place holder
use constant TP_VM_MIN_MEM => 2 ** 31;

# Not used, adding as a place holder
use constant TP_VM_MAX_MEM => 2 ** 32;

# Not used, adding as a place holder
use constant TP_TEST_BLOCKED_BY_BUG_ON_ESX => 2 ** 33;


# Not used, adding as a place holder
use constant TP_USE_BACKEDUP_VM => 2 ** 34;

=cut
# Please refer to the TODO section
# Not used, adding as a place holder
use constant TP_GUEST_9X_NOT_SUPPORTED => 2 ** 35;

# Not used, adding as a place holder
use constant TP_ARCH_64_NOT_SUPPORTED => 2 ** 36;

# Not used, adding as a place holder
use constant TP_TEST_BLOCKED_BY_BUG_ON_WS => 2 ** 37;

# Not used, adding as a place holder
use constant TP_TEST_BLOCKED_BY_BUG_ON_SERVER => 2 ** 38;

# Not used, adding as a place holder
use constant TP_VMS_IN_NFS_DATASTORE => 2 ** 39;
=cut

1;
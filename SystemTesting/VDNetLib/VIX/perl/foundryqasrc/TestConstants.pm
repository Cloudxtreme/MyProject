#/* **********************************************************
# * Copyright 2009 VMware, Inc.  All rights reserved.
# * -- VMware Confidential
# * **********************************************************/

package perl::foundryqasrc::TestConstants;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(POWEROPTION TIMEOUT_WAIT_FOR_TOOLS_IN_SEC
                 GUESTADMIN
                 GUESTADMINPASS
                 DEFAULT_CREATE_SNAPSHOT_OPTION
                 DEFAULT_REMOVE_SNAPSHOT_OPTION
                 DEFAULT_REVERT_SNAPSHOT_OPTION
                 WIN_BASEDIR
                 REGULAR_NAME
                 LNX_BASEDIR
                 SIMPLE_FILE
                 WIN_DELETE_DIR_ROOT
                 LNX_DELETE_DIR_ROOT
                 WIN_NONEXISTING_DIR
                 LNX_NONEXISTING_DIR
                 LNX_DELETE_FILE_ROOT
                 WIN_DELETE_FILE_ROOT
                 NONEXISTENT_NAME
                 WIN_DIR_EXISTENCE
                 LNX_DIR_EXISTENCE
                 WIN_FILE_EXISTS_ROOT
                 LNX_FILE_EXISTS_ROOT
                 LNX_LIST_DIR_ROOT
                 WIN_LIST_DIR_ROOT
                 NAME_WITH_SPACE
                 SPEC_CHARS_NAME
                 UPPER_LOWER_CASE_NAME
                 SHAREDFOLDEROPTION
                 WS6X_CONFIG_VERSION
                 WS6X_HW_VERSION
                 WIN_CREATE_DIR_ROOT
                 LNX_CREATE_DIR_ROOT
                 WIN_PROG_PATH
                 LNX_PROG_PATH
                 PROG_NAME
                 WINDIR
                 LNXDIR
                 WIN_DIR_ROOT
                 LNX_DIR_ROOT
                 OPEN_URL_FILE_NAME
                 LNX_RENAME_FILE_ROOT
                 WIN_RENAME_FILE_ROOT
                 ORIGINAL_NAME_FOR_RENAME
                 WIN_RUN_PROG_DIR_PATH
                 LNX_RUN_PROG_DIR_PATH
                 WIN_RUNPROGRAMINGUEST_DEFAULT_PATH
                 LNX_RUNPROGRAMINGUEST_DEFAULT_PATH
                 WIN_RUN_PROG_LOCATION
                 LNX_RUN_PROG_LOCATION
                 RUN_PROG_ARGS
                 RUN_PROG_NAME
                 WIN_BAT_SCRIPT_TEXT
                 LNX_BAT_SCRIPT_TEXT
                 LNX_SH_PATH
                 LNX_PERL_PATH WIN_PERL_PATH
                 WIN_BAT_SCRIPT_OUTPUT_FILE
                 LNX_BAT_SCRIPT_OUTPUT_FILE
                 SHAREDFOLDEROPTION
                 WIN_HOSTSHAREDFOLDER
                 LNX_HOSTSHAREDFOLDER
                 WIN_OTHER_HOSTSHAREDFOLDER
                 LNX_OTHER_HOSTSHAREDFOLDER
                 WIN_NONEXISTING_DIR
                 LNX_NONEXISTING_DIR
                 WIN_GUESTSHAREDFOLDERLOC
                 LNX_GUESTSHAREDFOLDERLOC
                 P_ENABLE_SHARED_FOLDER
                 SHAREDFOLDER_FILENAME
                 WS5X_HW_VERSION
                 WS5X_CONFIG_VERSION
                 WS4X_HW_VERSION
                 WS4X_CONFIG_VERSION
                 WS65_CONFIG_VERSION
                 WS65_HW_VERSION
                 WIN_DEFAULT_PATH
                 LNX_DEFAULT_PATH
                 FOUNDRYQA_VIX_REQUESTMSG_TOOLS_UPGRADE_ONLY);

use VMware::Vix::API::Constants;

use constant POWEROPTION => VIX_VMPOWEROP_NORMAL;
use constant TIMEOUT_WAIT_FOR_TOOLS_IN_SEC => 300;
use constant GUESTADMIN => "root";
use constant GUESTADMINPASS => "vmw\@re";
use constant DEFAULT_CREATE_SNAPSHOT_OPTION => 2;
use constant DEFAULT_REMOVE_SNAPSHOT_OPTION => 0;
use constant DEFAULT_REVERT_SNAPSHOT_OPTION => VIX_VMPOWEROP_LAUNCH_GUI;
use constant LNXDIR => "/tmp";
use constant WINDIR => "c:\\";
use constant WIN_BASEDIR => "c:\\foundrytest\\copyfile\\";
use constant REGULAR_NAME => "regular";
use constant LNX_BASEDIR => "/tmp/foundrytest/copyfile/";
use constant SIMPLE_FILE => "simple.file";
use constant WIN_DELETE_DIR_ROOT => "c:\\foundrytest\\deletedir\\";
use constant LNX_DELETE_DIR_ROOT => "/tmp/foundrytest/deletedir/";
use constant LNX_DELETE_FILE_ROOT => "/tmp/foundrytest/deletefile/";
use constant WIN_DELETE_FILE_ROOT => "c:\\foundrytest\\deletefile\\";
use constant NONEXISTENT_NAME => "nonexistent";
use constant LNX_DIR_EXISTENCE => "/tmp/foundrytest/directoryexistence/";
use constant WIN_DIR_EXISTENCE => "c:\\foundrytest\\directoryexistence\\";
use constant WIN_NONEXISTING_DIR => "c:\\foundrytest\\a\\b\\c\\";
use constant LNX_NONEXISTING_DIR => "/tmp/foundrytest/a/b/c/";
use constant LNX_FILE_EXISTS_ROOT => "/tmp/foundrytest/fileexists/";
use constant WIN_FILE_EXISTS_ROOT => "c:\\foundrytest\\fileexists\\";
use constant LNX_LIST_DIR_ROOT => "/tmp/foundrytest/listdirectory/";
use constant WIN_LIST_DIR_ROOT => "c:\\foundrytest\\listdirectory\\";
use constant NAME_WITH_SPACE => "I am with spaces";
use constant SPEC_CHARS_NAME => "`~!@#$%25^&()-_=+[]%5c{};',.%2f";
use constant UPPER_LOWER_CASE_NAME => "dir WIth UppER loWer cAsE";
use constant SHAREDFOLDEROPTION => VIX_SHAREDFOLDER_WRITE_ACCESS;
use constant WS6X_CONFIG_VERSION => 8;
use constant WS6X_HW_VERSION => 6;
use constant WIN_CREATE_DIR_ROOT => "c:\\foundrytest\\createdir\\";
use constant LNX_CREATE_DIR_ROOT => "/tmp/foundrytest/createdir/";
use constant WIN_PROG_PATH => "c:\\foundrytest\\";
use constant LNX_PROG_PATH => "/tmp/foundrytest/";
use constant PROG_NAME => "guestprogramforlistprocesses";
use constant LNX_DIR_ROOT => "/tmp/foundrytest/";
use constant WIN_DIR_ROOT => "c:\\foundrytest\\";
use constant OPEN_URL_FILE_NAME => "hello_vmware_openurl1.txt";
use constant LNX_RENAME_FILE_ROOT => "/tmp/foundrytest/renamefile/";
use constant WIN_RENAME_FILE_ROOT => "c:\\foundrytest\\renamefile\\";
use constant ORIGINAL_NAME_FOR_RENAME => "for_rename";
use constant WIN_RUN_PROG_DIR_PATH => "C:\\foundrytest\\runprograminguest";
use constant LNX_RUN_PROG_DIR_PATH => "/tmp/foundrytest/runprograminguest";
use constant SLEEP_FOR_RUN_PROGRAM_TO_START => 5;
use constant WIN_RUNPROGRAMINGUEST_DEFAULT_PATH => "C:\\foundrytest\\runprograminguest.txt";
use constant LNX_RUNPROGRAMINGUEST_DEFAULT_PATH => "/tmp/foundrytest/runprograminguest.txt";
use constant WIN_RUN_PROG_LOCATION => "C:\\foundrytest\\programtoruninguest.exe";
use constant LNX_RUN_PROG_LOCATION => "/tmp/foundrytest/programtoruninguest";
use constant RUN_PROG_ARGS => " firstarg secondarg thirdarg";
use constant RUN_PROG_NAME => "programtoruninguest";
use constant WIN_BAT_SCRIPT_TEXT => "echo foundrytest is > C:\\foundrytest\\RunScriptInGuest.txt\necho testing RunScriptInGuest >> C:\\foundrytest\\RunScriptInGuest.txt";
use constant LNX_BAT_SCRIPT_TEXT => "echo foundrytest is > /home/guestadmin/RunScriptInGuest.txt\necho testing RunScriptInGuest >> /home/guestadmin/RunScriptInGuest.txt";
use constant WIN_BAT_SCRIPT_OUTPUT_FILE => "C:\\foundrytest\\RunScriptInGuest.txt";
use constant LNX_BAT_SCRIPT_OUTPUT_FILE => "/home/guestadmin/RunScriptInGuest.txt";
use constant LNX_SH_PATH => "/bin/sh";
use constant LNX_PERL_PATH => "/usr/bin/perl";
use constant WIN_PERL_PATH => "c:/perl/bin/perl.exe";
#use constant SHAREDFOLDEROPTION => VIX_SHAREDFOLDER_WRITE_ACCESS;
use constant WIN_HOSTSHAREDFOLDER => "c:\\foundrytest";
use constant LNX_HOSTSHAREDFOLDER => "/tmp/foundrytest";
use constant WIN_OTHER_HOSTSHAREDFOLDER => "c:\\otherfoundrytest";
use constant LNX_OTHER_HOSTSHAREDFOLDER => "/tmp/otherfoundrytest";
use constant WIN_GUESTSHAREDFOLDERLOC => "\\\\.host\\Shared Folders\\";
use constant LNX_GUESTSHAREDFOLDERLOC => "/mnt/hgfs/" ;
use constant P_ENABLE_SHARED_FOLDER => "EnableSharedFolder";
use constant SHAREDFOLDER_FILENAME  => "SharedFolder.txt";
use constant WS5X_HW_VERSION => 4;
use constant WS5X_CONFIG_VERSION => 8;
use constant WS65_CONFIG_VERSION => 8;
use constant WS65_HW_VERSION => 7;
use constant WIN_DEFAULT_PATH => "c:\\vms\\";
use constant LNX_DEFAULT_PATH => "/var/lib/vmware/VirtualMachines/";
# The VIX_REQUESTMSG_TOOLS_UPGRADE_ONLY has been declared in vix-perl-semipublic
# Cannot link to both public and semi-public for the same api
# Hence, declaring the constant here.
# This constant has to be changed every time Foundry changes the value
# of VIX_REQUESTMSG_TOOLS_UPGRADE_ONLY
use constant FOUNDRYQA_VIX_REQUESTMSG_TOOLS_UPGRADE_ONLY => 1;

1;

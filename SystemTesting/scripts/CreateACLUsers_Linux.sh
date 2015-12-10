#!/bin/bash
#
#script to setup users and Groups required for SDK Security ACL tests
#Users and Groups are created for Read, VMAdmin, DCAdmin, VMUser, VMPoweruser,
#VMProuser, Genericuser, NoAcess, Administrator permissions
#Permissions will not be assigned to ACL users or ACL groups in this batch script.
#
#Step 1: Any existing ACL users, Groups will be removed
#Step 2: Create ACL Users and Groups for different levels of permissions
#Step 3: Add ACL Users into the corresponding groups based on permission levels
#Permissions should be assigned after create ACL users and groups from VC client or
#using SDK changePermissions API
#
#
#Script to setup ACL Users required for SDK ACL  Tests
echo Remove any existing ACL Users
userdel adminuser
userdel readuser
userdel noaccessuser
userdel vmadminuser
userdel dcadminuser
userdel vmuser
userdel vmpoweruser
userdel vmprouser
userdel genericuser
#
echo Remove any existing ACL Groups
groupdel admingroup
groupdel readgroup
groupdel noaccessgroup
groupdel vmadmingroup
groupdel dcadmingroup
groupdel vmgroup
groupdel vmpowergroup
groupdel vmprogroup
groupdel genericgroup
#
echo Add ACL Groups
groupadd admingroup
groupadd readgroup
groupadd noaccessgroup
groupadd vmadmingroup
groupadd dcadmingroup
groupadd vmgroup
groupadd vmpowergroup
groupadd vmprogroup
groupadd genericgroup
#
echo Add ACL Users
useradd -g admingroup adminuser -p `openssl passwd -crypt apifvt1$`
useradd -g readgroup readuser -p `openssl passwd -crypt apifvt1$`
useradd -g noaccessgroup noaccessuser -p `openssl passwd -crypt apifvt1$`
useradd -g vmadmingroup vmadminuser -p `openssl passwd -crypt apifvt1$`
useradd -g dcadmingroup dcadminuser -p `openssl passwd -crypt apifvt1$`
useradd -g vmgroup vmuser -p `openssl passwd -crypt apifvt1$`
useradd -g vmpowergroup vmpoweruser -p `openssl passwd -crypt apifvt1$`
useradd -g vmprogroup vmprouser -p `openssl passwd -crypt apifvt1$`
useradd -g genericgroup genericuser -p `openssl passwd -crypt apifvt1$`
#
echo CreateACLUsers_Groups Setup completed. Make sure there is no command failures in Create and Add.

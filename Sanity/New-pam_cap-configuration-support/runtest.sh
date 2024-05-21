#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/libcap/Sanity/New-pam_cap-configuration-support
#   Description: New pam_cap configuration support in /etc/security/capability.conf is correctly recognized: @group, ^cap_foo, !cap_bar
#   Author: Martin Zeleny <mzeleny@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2020 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="libcap"
testGroup="group_1487388"
testUser1="user1_1487388"
testUser2="user2_1487388"
CAP_CONF="/etc/security/capability.conf"
PAM_D_SU="/etc/pam.d/su"


checkCapGood()
{
    rlLog "Check that user's process has cap_net_raw capability"
    rlRun -s "su - ${1} -c 'getpcaps \$\$'"
    if rlIsRHEL "<8.6"; then
        rlAssertGrep "Capabilities for.* = cap_net_raw" $rlRun_LOG -E
    else
        rlAssertGrep "cap_net_raw=i" $rlRun_LOG
    fi
    rm $rlRun_LOG

}

checkCapBad()
{
    rlLog "Check that user's process does not have cap_net_raw capability"
    rlRun -s "su - ${1} -c 'getpcaps \$\$'"
    rlAssertNotGrep "cap_net_raw" $rlRun_LOG
    rm $rlRun_LOG
}


rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlRun "groupadd ${testGroup}"
        rlRun "useradd ${testUser1} -G ${testGroup}"
        rlRun "useradd ${testUser2}"

        rlFileBackup ${PAM_D_SU}
        [ -f ${CAP_CONF} ] && rlFileBackup ${CAP_CONF}

        rlRun "sed '1i auth\trequired\tpam_cap.so' -i ${PAM_D_SU}" 0 "Configure pam_cap.so in ${PAM_D_SU}"
    rlPhaseEnd


    rlPhaseStartTest "Configure capability by username"
        rlRun "echo -e 'cap_net_raw ${testUser1}\nnone *' > ${CAP_CONF}"
        checkCapGood "${testUser1}"
        checkCapBad "${testUser2}"
    rlPhaseEnd


    rlPhaseStartTest "Configure capability by groupname with '@'"
        rlRun "echo -e 'cap_net_raw @${testGroup}\nnone *' > ${CAP_CONF}"
        checkCapGood "${testUser1}"
        checkCapBad "${testUser2}"
    rlPhaseEnd


    rlPhaseStartTest "Configure capability with '^'"
        rlRun "echo -e '^cap_net_raw ${testUser1}\nnone *' > ${CAP_CONF}"
        checkCapGood "${testUser1}"
        checkCapBad "${testUser2}"
    rlPhaseEnd


    rlPhaseStartTest "Configure capability with '!'"
        rlRun "echo -e '!cap_net_raw ${testUser1}\nnone *' > ${CAP_CONF}"
        checkCapBad "${testUser1}"
    rlPhaseEnd


    rlPhaseStartCleanup
        rlRun "userdel -r -f ${testUser1}"
        rlRun "userdel -r -f ${testUser2}"

        rlRun "groupdel ${testGroup}"
        rlFileRestore
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/libcap/Regression/Ambient-capabilities-failed-to-applied-to-non-root
#   Description: Test that ambient capabilities applies to non-root user even when correct rules are in /etc/security/capability.conf
#   Author: Martin Zeleny <mzeleny@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2022 Red Hat, Inc.
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
CAP_CONF="/etc/security/capability.conf"
PAM_D_SU="/etc/pam.d/su"
FMT="%{name}-%{version}-%{release}\n"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "rlImport --all" 0 "Import libraries" || rlDie "cannot continue"
        rlRun "utilLinuxVer=$(rpm -q util-linux --qf ${FMT})"
        rlRun "libcapVer=$(rpm -q libcap --qf ${FMT} | head -n 1)" \
            0 "Gel libcap verions - one line in case of multiple installed archs."

        if rlIsRHEL '8'; then
            rlRun "rlTestVersion ${libcapVer} '>=' 'libcap-2.48-1.el8'" \
                || rlDie "Insufficient version of ${libcapVer}"
            rlRun "rlTestVersion ${utilLinuxVer} '>=' 'util-linux-2.32.1-32.el8'" \
                || rlDie "Insufficient version of ${utilLinuxVer}"
        fi
        if rlIsRHEL '>=9'; then
            rlRun "rlTestVersion ${libcapVer} '>=' 'libcap-2.48-8.el9'" \
                || rlDie "Insufficient version of ${libcapVer}"
            rlRun "rlTestVersion ${utilLinuxVer} '>=' 'util-linux-2.37.3-1.el9'" \
                || rlDie "Insufficient version of ${utilLinuxVer}"
        fi

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlRun "testUserSetup"

        rlRun "rlFileBackup --clean --missing-ok ${CAP_CONF} ${PAM_D_SU}"
    rlPhaseEnd


    rlPhaseStartTest "Create configuration"
        cat > ${CAP_CONF} << EOF
^cap_setpcap ${testUser}
none  *
EOF
        rlRun "cat ${CAP_CONF}"

        ed ${PAM_D_SU} << EOF
1
a
auth            optional        pam_cap.so debug keepcaps defer
auth            required        pam_env.so
.
wq
EOF
        rlRun "cat ${PAM_D_SU}"
    rlPhaseEnd


    rlPhaseStartTest "Perform the test"
        rlRun -s "su - ${testUser} -c 'capsh --print'"
        rlAssertGrep "Ambient set.*cap_setpcap" $rlRun_LOG
        rm $rlRun_LOG
    rlPhaseEnd


    rlPhaseStartCleanup
        rlRun "testUserCleanup"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlRun "rlFileRestore"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

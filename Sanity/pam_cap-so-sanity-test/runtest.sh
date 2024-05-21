#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/libcap/Sanity/pam_cap-so-sanity-test
#   Description: basic functionality test for pam_cap.so module
#   Author: Karel Srot <ksrot@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2017 Red Hat, Inc.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="libcap"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
	rlRun "useradd -m pam_cap_user"
	rlRun "useradd -m pam_cap_user2"
	rlFileBackup /etc/pam.d/su
	[ -f /etc/security/capability.conf ] && rlFileBackup /etc/security/capability.conf
	rlRun "echo -e 'cap_net_raw pam_cap_user\nnone *' > /etc/security/capability.conf"
	rlRun "sed '1 s/^/auth required pam_cap.so/' -i /etc/pam.d/su" 0 "Configure pam_cap.so in /etc/pam.d/su"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun -s "su - pam_cap_user -c 'getpcaps \$\$'"
	rlAssertGrep "cap_net_raw" $rlRun_LOG
        rlRun -s "su - pam_cap_user2 -c 'getpcaps \$\$'"
	rlAssertNotGrep "cap_net_raw" $rlRun_LOG
    rlPhaseEnd

    rlPhaseStartCleanup
	rlRun "userdel --remove --force pam_cap_user"
	rlRun "userdel --remove --force pam_cap_user2"
	rlFileRestore
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

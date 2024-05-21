#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/libcap/Sanity/setcap-getcap-basic-functionality
#   Description: test basic functionality
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
	rlRun "mkdir mydir && touch file1 mydir/file2 mydir/file3"
    rlPhaseEnd

    rlPhaseStartTest "set and get capabilities"
	rlRun "setcap cap_net_admin+p file1 cap_net_raw+ei mydir/file2"
        rlRun -s "getcap file1 mydir/file2"
	rlAssertGrep "file1 [= ]*cap_net_admin[+=]p" $rlRun_LOG -E
	rlAssertGrep "mydir/file2 [= ]*cap_net_raw[+=]ei" $rlRun_LOG -E
    rlPhaseEnd
    
    rlPhaseStartTest "set capabilities via stdin"
	rlRun "echo -e 'cap_net_raw+p\ncap_net_admin+p' > input"
	rlRun -s "setcap - mydir/file3 < input"
	rlAssertGrep "Please enter caps for file \[empty line to end\]:" $rlRun_LOG
	rlRun -s "getcap mydir/file3"
        rlAssertGrep "mydir/file3 [= ]*cap_net_admin,cap_net_raw[=+]p" $rlRun_LOG -E
    rlPhaseEnd

    rlPhaseStartTest "set capabilities quietly via stdin"
	rlRun "echo -e 'cap_net_raw+p' > input"
	rlRun -s "setcap -q - mydir/file3 < input"
	rlAssertNotGrep "Please enter caps for file" $rlRun_LOG
	rlRun -s "getcap mydir/file3"
        rlAssertGrep "mydir/file3 [= ]*cap_net_raw[=+]p" $rlRun_LOG -E
    rlPhaseEnd

    rlPhaseStartTest "remove capabilities"
	rlRun "setcap -r mydir/file3"
	rlRun "getcap | grep file3" 1 "There should be no capabilities listed for file1"
    rlPhaseEnd

    rlPhaseStartTest "listing capabilities recursively"
	rlRun -s "getcap -r *"
	rlAssertGrep "file1 [= ]*cap_net_admin[=+]p" $rlRun_LOG -E
	rlAssertGrep "mydir/file2 [= ]*cap_net_raw[+=]ei" $rlRun_LOG -E
    rlPhaseEnd

    rlPhaseStartTest "listing capabilities verbosely"
	rlRun -s "getcap -v mydir/*"
	rlAssertGrep "mydir/file2 [= ]*cap_net_raw[+=]ei" $rlRun_LOG -E
	rlAssertGrep "mydir/file3\$" $rlRun_LOG -E
    rlPhaseEnd

    rlPhaseStartTest "print help"
	rlRun "setcap -h | grep 'usage: setcap'" 1
	rlRun "getcap -h | grep 'usage: getcap'" 1
    rlPhaseEnd

    rlPhaseStartTest "exit with 1 on error"
	rlRun -s "setcap foo bar" 1
	rlAssertGrep "fatal error: Invalid argument" $rlRun_LOG
	rlRun -s "getcap -f oo" 1
	rlAssertGrep "getcap: invalid option -- 'f'" $rlRun_LOG
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/libcap/Sanity/getpcaps-basic-functionality
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
        rlAssertRpm "$PACKAGE"
        if rlIsRHEL '<=7'; then
            rlRun "ping localhost &> /dev/null &"
            PID1="$!"
            rlRun "ping localhost &> /dev/null &"
            PID2="$!"
        else
            PID1="$(pidof systemd-journald)"
            PID2="$(pidof systemd-logind)"
        fi
    rlPhaseEnd

    rlPhaseStartTest
        if rlIsRHEL '<=7'; then
            rlRun -s "getpcaps ${PID1} ${PID2}"
            CAPS="cap_net_admin,cap_net_raw\+p"
        else
        rlRun -s "getpcaps --verbose ${PID1} ${PID2}"
            CAPS="cap_chown,cap_dac_override"
        fi
        rlAssertGrep "Capabilities for .${PID1}.* ${CAPS}" "$rlRun_LOG" -E
        rlAssertGrep "Capabilities for .${PID2}.* ${CAPS}" "$rlRun_LOG" -E
    rlPhaseEnd

    rlPhaseStartCleanup
        if rlIsRHEL '<=7'; then
            rlRun "kill -9 ${PID1}"
            rlRun "kill -9 ${PID2}"
        fi
    rlPhaseEnd

    rlJournalPrintText
rlJournalEnd

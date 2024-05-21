#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/libcap/Sanity/capsh-basic-functionality
#   Description: tests basic functionality
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
        rlRun "useradd -m libcap_tester"
    rlPhaseEnd

    rlPhaseStartTest "Remove  the  listed  capabilities  from the prevailing bounding set"
        rlRun -s "capsh --drop=cap_net_raw -- -c 'getpcaps \$\$'"
        if rlIsRHEL "<8.6"; then
            rlAssertNotGrep "cap_net_raw" $rlRun_LOG
        else
            rlAssertGrep "cap_net_raw-ep" $rlRun_LOG
            # https://unix.stackexchange.com/questions/592911/how-does-ping-work-on-fedora-without-setuid-and-capabilities
            old_value="$(sysctl net.ipv4.ping_group_range | sed -E 's/net.ipv4.ping_group_range = //')"
            rlRun "sysctl net.ipv4.ping_group_range=\"1 0\""
            rlRun "ping localhost -c 1"
        fi
        rlRun -s "capsh --drop=cap_net_raw -- -c 'ping localhost -c 1'" 2,126 "Ping without cap_net_raw shoud fail"
        rlAssertGrep "Operation not permitted" $rlRun_LOG
        if ! rlIsRHEL "<8.6"; then
            rlRun "sysctl net.ipv4.ping_group_range=\"${old_value}\""
        fi
    rlPhaseEnd

    rlPhaseStartTest "Set the prevailing process capabilities"
        rlRun -s "capsh --caps=cap_chown+p --print"
        rlAssertGrep "Current: [= ]*cap_chown[=+]p" $rlRun_LOG -E
    rlPhaseEnd

    rlPhaseStartTest "Set the inheritable set of capabilities"
        rlRun -s "capsh --inh=cap_chown --print"
        if rlIsRHEL "<8.6"; then
            rlAssertGrep "Current: = cap_chown+eip" $rlRun_LOG
        else
            rlAssertGrep "Current: =ep cap_chown+i" $rlRun_LOG
        fi
        rlRun -s "capsh --inh=cap_chown -- -c 'getpcaps \$\$' 2>&1"
        if rlIsRHEL "<8.6"; then
            rlAssertGrep ": = cap_chown+eip" $rlRun_LOG
        else
            rlAssertGrep ": =ep cap_chown+i" $rlRun_LOG
        fi
    rlPhaseEnd

    rlPhaseStartTest "Assume the identity of the user nobody"
        USERID=`id -u nobody`
        GROUPID=`id -g nobody`
        rlRun -s "capsh --user=nobody -- -c 'id'"
        rlAssertGrep "uid=$USERID(nobody) gid=$GROUPID(nobody) groups=$GROUPID(nobody)" $rlRun_LOG
    rlPhaseEnd

    rlPhaseStartTest "Force all uid values to equal to nobody"
        rlRun -s "capsh --uid=$USERID -- -c 'id'"
        rlAssertGrep "uid=$USERID(nobody) gid=0(root) groups=0(root)" $rlRun_LOG
    rlPhaseEnd

    rlPhaseStartTest "Force all gid values to equal to nobody"
        rlRun -s "capsh --gid=$GROUPID -- -c 'id'"
        rlAssertGrep "uid=0(root) gid=$GROUPID(nobody)" $rlRun_LOG
    rlPhaseEnd

    rlPhaseStartTest "Set the supplementary groups"
        GROUP2ID=`id -g daemon`
        rlRun -s "capsh --groups=${GROUPID},${GROUP2ID} -- -c id"
        rlAssertGrep "uid=0(root) gid=0(root) groups=0(root),${GROUP2ID}(daemon),${GROUPID}(nobody)" $rlRun_LOG
    rlPhaseEnd

    # Since RHEL-9, logic is different and this phase is not applicable
    if rlIsRHEL "<8.6"; then
    rlPhaseStartTest "Permit the process to retain its capabilities after a setuid"
        CURRENT=`capsh --print | grep 'Current:' | cut -d '+' -f 1`
        rlRun -s "capsh --keep=0 --uid=$USERID --print"
        rlAssertGrep 'Current: =$' $rlRun_LOG -E
        rlRun -s "capsh --keep=1 --uid=$USERID --print"
        rlAssertGrep "$CURRENT" $rlRun_LOG
    rlPhaseEnd
    fi
    
    # Since RHEL-9, current caps are not listed when there are all of them.
    if rlIsRHEL "<8.6"; then
    rlPhaseStartTest "Decode capabilities"
        rlRun "CODE=$( cat /proc/$$/status | awk '/CapEff/ { print $2 }' )"
        rlRun "DECODE=$( capsh --decode=$CODE | cut -d '=' -f 2 )"
        rlRun "capsh --print | grep 'Current: = $DECODE'"
    rlPhaseEnd
    fi

    rlPhaseStartTest "Verify the existence of a capability on the system"
        rlRun "capsh --supports=cap_net_raw"
        rlRun -s "capsh --supports=cap_foo_bar" 1
        rlAssertGrep "cap\[cap_foo_bar\] not recognized by library" $rlRun_LOG
    rlPhaseEnd

    rlPhaseStartTest "Verify exit code for unsupported option"
        rlRun "capsh --foo bar" 1
    rlPhaseEnd

    rlPhaseStartTest "Run as a regular user"
        USERID=`id -u libcap_tester`
        rlRun -s "su - libcap_tester -c 'capsh --print'"
        rlAssertGrep "Current: =\$" $rlRun_LOG -E
        rlAssertGrep "uid=$USERID(libcap_tester)" $rlRun_LOG
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "userdel --remove --force libcap_tester"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

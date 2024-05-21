#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/libcap/Regression/bz722694-capsh-does-not-chdir-after-chroot
#   Description: Checks if capsh does chdir to root after chroot
#   Author: Miroslav Vadkerti <mvadkert@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2011 Red Hat, Inc. All rights reserved.
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

# Include rhts environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="libcap"
TMP=$(mktemp)

# run passed argument in chrooted capsh and exit
# $1 - path to chroot
# $2 - cmd to run
function chroot_capsh() {
    expect -c "
        spawn capsh --chroot=$1 --
        expect {bash} { send -- $2\r }
        expect {bash} { send -- exit\r }
        expect eof 
    " 
}

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "TmpDir=$(mktemp -d)" 0 "Creating tmp directory"
        rlIsRHEL 3 4 5 6 || {
            rlRun "make -f /usr/share/selinux/devel/Makefile"
            rlRun "semodule -i bz722694.pp"
        }
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest
        # create file that should not be readable from the chrooted environment
        rlRun "echo FOO > passwd" 0 "Creating the foo test file"
        # create chroot environment
        rlRun "mkdir chroot"
        # install chroot environment
        rlRun "yum --nogpgcheck --releasever=/ -y --installroot=$(pwd)/chroot install coreutils bash --nogpgcheck"
        # run expect and print current directory in chrooted environment (expected /)
        rlRun "chroot_capsh $(pwd)/chroot pwd | tr -d '\r' | tee $TMP"
        # check for correct results
        rlAssertGrep "/\$" $TMP -E
        rlAssertNotGrep "^${TmpDir}\$" $TMP -E
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlIsRHEL 3 4 5 6 || {
            rlRun "semodule -r bz722694"
	    rlRun "rm -r bz722694.{pp,if,fc} tmp"
        }
        rlRun "rm -r $TmpDir $TMP" 0 "Removing tmp dir/file"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

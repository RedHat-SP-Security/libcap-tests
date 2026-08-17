#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartSetup "Setup"
        rlAssertRpm "libcap"
    rlPhaseEnd

    rlPhaseStartTest "Verify capsh --print output for full capabilities"
        # For a root user, the default capabilities should be full.
        # The output should now contain 'all' instead of a long list of individual capabilities.
        rlRun "capsh --print"
        rlAssertGrep "Current: all=ep" "$rlRun_LOG" "Check for 'all=ep' in Current capabilities"
        rlAssertGrep "Bounding set: all" "$rlRun_LOG" "Check for 'all' in Bounding set"
    rlPhaseEnd

    rlPhaseStartTest "Verify capsh --print output for empty ambient set"
        # The ambient set is typically empty for a root user.
        # The output should now explicitly say 'none'.
        rlRun "capsh --print"
        rlAssertGrep "Ambient set: none" "$rlRun_LOG" "Check for 'none' in Ambient set"
    rlPhaseEnd

    rlPhaseStartTest "Verify capsh --print output for a non-root user (no capabilities)"
        rlRun "useradd capsh_test_user"
        rlRun "su - capsh_test_user -c 'capsh --print'"
        rlAssertGrep "Current: =" "$rlRun_LOG" "Current capabilities should be empty for non-root user"
        rlRun "userdel -r capsh_test_user"
    rlPhaseEnd

    rlPhaseStartCleanup "Cleanup"
        # No cleanup needed in this case
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

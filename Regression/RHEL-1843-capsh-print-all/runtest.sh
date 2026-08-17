#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartSetup "Setup"
        rlAssertRpm "libcap"
    rlPhaseEnd

    rlPhaseStartTest "Test capsh --print output for full capabilities"
        # Run as root to ensure all capabilities are initially set
        rlRun "capsh --print"
        rlAssertGrep "Current: all=ep" "$rlRun_LOG" "Check for 'all' in Current capabilities"
        rlAssertGrep "Bounding set: all" "$rlRun_LOG" "Check for 'all' in Bounding set"
    rlPhaseEnd

    rlPhaseStartTest "Test capsh --print output for empty capabilities"
        # Switch to a non-root user to have empty capabilities
        rlRun "su - nobody -s /bin/bash -c 'capsh --print'"
        rlAssertGrep "Current: =" "$rlRun_LOG" "Check for empty Current capabilities"
        rlAssertNotGrep "all" "$rlRun_LOG" "Ensure 'all' is not present for empty capabilities"
    rlPhaseEnd

    rlPhaseStartCleanup "Cleanup"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

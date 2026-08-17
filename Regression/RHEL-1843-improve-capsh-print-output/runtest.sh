#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartSetup "Setup"
        rlAssertRpm "libcap"
    rlPhaseEnd

    rlPhaseStartTest "Test capsh --print output with full capabilities"
        # Run capsh --print and capture the output
        rlRun "capsh --print"

        # Verify that "Current" shows "all=ep"
        rlAssertGrep "Current: all=ep" "$rlRun_LOG" "Check for 'Current: all=ep'"

        # Verify that "Bounding set" shows "all"
        rlAssertGrep "Bounding set: all" "$rlRun_LOG" "Check for 'Bounding set: all'"

        # Verify that "Ambient set" shows "none"
        rlAssertGrep "Ambient set: none" "$rlRun_LOG" "Check for 'Ambient set: none'"
    rlPhaseEnd

    rlPhaseStartCleanup "Cleanup"
        # No cleanup needed
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

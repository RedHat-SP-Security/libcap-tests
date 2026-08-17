#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartSetup "Setup"
        rlAssertRpm "libcap"
    rlPhaseEnd

    rlPhaseStartTest "Verify capsh --print output with all capabilities"
        # Run capsh --print and capture the output
        rlRun "capsh --print > capsh_output.txt" 0 "Run capsh --print"

        # Verify 'Current: all=ep'
        rlAssertGrep "Current: all=ep" capsh_output.txt "Check for 'Current: all=ep'"

        # Verify 'Bounding set: all'
        rlAssertGrep "Bounding set: all" capsh_output.txt "Check for 'Bounding set: all'"

        # Verify 'Ambient set: none'
        rlAssertGrep "Ambient set: none" capsh_output.txt "Check for 'Ambient set: none'"
    rlPhaseEnd

    rlPhaseStartCleanup "Cleanup"
        rlRun "rm -f capsh_output.txt"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

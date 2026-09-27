# Case 02 — EtherCAT State Transition Blocked by Distributed Clock Synchronization

## Context

A multi-axis EtherCAT system was commanded to move subdevices from PRE-OP through SAFE-OP to OP. The application-side state-change request reported completion, but several drives did not reach the requested final state.

## Symptom

Some EtherCAT subdevices remained in PRE-OP while others reached OP. The state-change function reported that the request had completed without exposing a direct application error.

## Evidence

System logs showed that the PRE-OP -> SAFE-OP transition failed for affected devices during Distributed Clock synchronization. The failure was associated with static drift compensation / synchronization-window checks before the device could continue toward OP.

This created an important distinction:

- the API request itself had completed,
- but the physical EtherCAT state transition had not completed successfully for every slave.

## Investigation

The diagnosis separated the function-block result from the actual device state.

The following checks were used:

1. Read the requested state from the application.
2. Read the actual EtherCAT state of each subdevice.
3. Inspect system logs around the transition timestamp.
4. Compare successful axes with axes that remained in PRE-OP.
5. Correlate the failed transition with Distributed Clock synchronization messages.

## Root Cause

The affected slaves were prevented from entering SAFE-OP because Distributed Clock synchronization had not met the required timing condition. Since SAFE-OP was never reached, OP was also impossible.

## Resolution

The control logic was changed conceptually so that a completed state-change request was not treated as proof of a successful final state.

The robust pattern became:

```text
Request state transition
        |
        v
Wait for command completion
        |
        v
Read actual state of every slave
        |
        +--> Requested state reached -> Continue
        |
        +--> State not reached -> Inspect DC / timing diagnostics
```

## Verification

Verification required both:

- command completion at the API level, and
- confirmation that each required subdevice actually reached the requested EtherCAT state.

## Engineering Lessons

- Command acceptance and physical state achievement are different conditions.
- Fieldbus state transitions should always be verified through actual-state feedback.
- PRE-OP -> SAFE-OP failures often deserve immediate timing/DC investigation before application-level motion debugging.
- Diagnostic APIs are more useful when paired with explicit timeout and final-state validation.

# Case 13 — EtherCAT State-Change Command Completed but Requested State Was Not Reached

## Context

An EtherCAT control application used a function block to request a subdevice state transition. The application needed deterministic supervision of the fieldbus state because motion startup depended on every required device reaching the expected EtherCAT state.

## Symptom

The state-change function block indicated completion without reporting an application-level error, while the affected EtherCAT device had not actually reached the requested state.

This created a misleading condition: command execution appeared successful at the API level, but the physical communication state was still different from the requested state.

## Evidence

The investigation compared three independent pieces of information:

- the state requested by the application,
- the command function block's `Done` / `Error` result,
- the actual EtherCAT state reported for the subdevice.

The actual-state feedback showed that command completion could occur even when the requested state was not ultimately achieved. System diagnostics then provided the lower-level reason for the failed transition.

## Investigation

The original assumption was that `Done = TRUE` meant "the device is now in the requested state." That assumption was tested directly instead of being embedded into the startup sequence.

The diagnostic sequence became:

1. Issue the state-change request once.
2. Wait until the command function block finishes.
3. Read the actual EtherCAT state independently.
4. Compare actual state with requested state.
5. If they differ, inspect the EtherCAT diagnostic reason rather than treating the command as successful.
6. Apply a supervision timeout so startup cannot wait indefinitely.

This separated **command lifecycle semantics** from **plant/fieldbus state feedback**.

## Root Cause

The application interpreted completion of the asynchronous command as confirmation that the target state had been reached. In reality, command completion and final device-state confirmation are separate conditions.

The underlying reason why a particular transition fails can vary — synchronization, configuration, communication, or device errors — so it must be diagnosed separately from the API semantics.

## Resolution

The startup logic was redesigned around explicit state verification:

```text
State request edge
      |
      v
Command Busy
      |
      v
Command completed
      |
      v
Read actual EtherCAT state
      |
      +--> Actual = Requested -> startup may continue
      |
      +--> Actual != Requested -> diagnostic / timeout path
```

For cyclic supervision, actual-state monitoring was treated as feedback that should be refreshed independently of the one-shot state-change command.

## Verification

The revised logic was validated by checking that startup only advanced when both conditions were true:

1. the state-change command had completed, and
2. the actual subdevice state matched the requested state.

A failed transition therefore remained visible to the application instead of being masked by the command's completion flag.

## Engineering Lessons

- `Done` should be interpreted according to the API contract, not assumed to mean that the physical target condition is true.
- Asynchronous command status and actual device feedback belong to different layers of control logic.
- Critical state transitions should always be followed by explicit read-back verification.
- Startup sequences need a timeout and diagnostic path for "command completed, target not reached."
- Level-style cyclic state monitoring is often more useful for supervision than repeatedly retriggering an edge-based command interface.

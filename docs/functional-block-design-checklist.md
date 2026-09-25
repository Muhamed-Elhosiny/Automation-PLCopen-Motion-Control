# PLCopen Function Block Design Checklist

A practical review checklist for designing reusable motion-control function blocks in IEC 61131-3 Structured Text. The goal is predictable behavior, clear diagnostics, and safe integration into cyclic PLC applications.

> This guide is vendor-neutral and focuses on software design patterns rather than a specific controller or drive implementation.

## 1. Define the Contract First

Before writing the implementation, define what the block promises to the caller.

For every function block, document:

- command inputs and their trigger semantics;
- configuration inputs and valid ranges;
- `Busy`, `Done`, `Error`, and status behavior;
- what happens if a new command arrives while the block is active;
- what condition terminates the operation;
- whether an abort or reset is supported;
- whether outputs remain valid after completion.

A motion block is easier to integrate when its external behavior is unambiguous.

## 2. Command Trigger Semantics

A common source of PLC bugs is unclear handling of `Execute`.

For edge-triggered commands, distinguish between:

```text
Execute = FALSE -> idle
Execute rising edge -> accept command
Busy = TRUE -> operation active
Done = TRUE -> operation completed
Execute = FALSE -> acknowledge completion and return to idle
```

The implementation should avoid repeatedly restarting an operation while `Execute` remains TRUE.

For continuously active functions such as power enable or cyclic monitoring, level-triggered behavior may be more appropriate. The choice should be explicit in the interface documentation.

## 3. Validate Inputs Before Starting

Reject invalid commands before changing the internal state.

Typical validation includes:

- velocity within configured limits;
- acceleration and deceleration greater than zero;
- valid axis reference;
- supported operating mode;
- drive communication available;
- axis not already in an incompatible operation;
- target position within configured software limits.

A useful pattern is:

```text
Command edge
   |
   v
Validate inputs
   |
   +-- invalid --> Error
   |
   v
Start operation
```

Early validation makes failures deterministic and easier to diagnose.

## 4. Separate Command, State, and Feedback

Avoid mixing user commands directly with low-level drive outputs.

A reusable design separates three concerns:

```text
Application Command
        |
        v
Motion Function Block
        |
        v
Axis / CiA 402 Abstraction
        |
        v
Process Data / Drive
```

The function block should decide *what operation is required*. The axis layer should decide *how that operation is represented for the connected drive*.

This separation improves portability and testability.

## 5. Use an Explicit Internal State Machine

Complex command logic is easier to review when represented by named states rather than many interacting Boolean conditions.

Example:

```text
IDLE
  -> VALIDATE
  -> PREPARE
  -> EXECUTE
  -> VERIFY
  -> COMPLETE

Any active state
  -> ERROR
```

Each state should have one clear responsibility and a defined transition condition.

For Structured Text, a `CASE` statement generally makes this flow easier to inspect during online debugging.

## 6. Verify Feedback, Not Only Command Acceptance

Writing a command does not prove that the physical or logical state was reached.

Examples:

- requesting `Operation Enabled` does not prove the drive reached it;
- writing an operating mode does not prove the mode display matches;
- sending a target velocity does not prove the axis is moving;
- requesting an EtherCAT state does not prove every device reached that state.

Where practical, completion should be based on feedback.

```text
Request -> Observe -> Verify -> Complete
```

This pattern is especially important for asynchronous communication and multi-axis systems.

## 7. Define Busy / Done / Error Behavior

The three outputs should never leave the caller guessing about the current operation.

Recommended behavior:

| State | Busy | Done | Error |
|---|---:|---:|---:|
| Idle | FALSE | FALSE | FALSE |
| Executing | TRUE | FALSE | FALSE |
| Completed | FALSE | TRUE | FALSE |
| Failed | FALSE | FALSE | TRUE |

Avoid ambiguous combinations unless the interface explicitly defines them.

Also define when `Done` and `Error` are cleared. A common pattern is to retain the result until the command input returns to FALSE.

## 8. Provide Actionable Diagnostics

A Boolean `Error` output alone is rarely sufficient during commissioning.

Prefer additional information such as:

```text
Error       : BOOL
ErrorID     : UDINT
ErrorSource : ENUM
Status      : ENUM
```

Useful error categories can include:

- invalid parameter;
- communication unavailable;
- axis not ready;
- drive fault;
- command timeout;
- operation aborted;
- feedback mismatch.

The objective is to tell the engineer where to investigate next.

## 9. Add Timeout Supervision

Any state that waits for external feedback can potentially wait forever.

Examples include waiting for:

- a drive-state transition;
- an SDO response;
- motion completion;
- homing completion;
- communication recovery.

A timeout converts an infinite wait into a diagnosable failure.

```text
IF WaitingForFeedback AND TimerExpired THEN
    Error := TRUE;
    ErrorID := ERR_TIMEOUT;
    State := ERROR;
END_IF;
```

The timeout value should be configurable when system behavior can vary significantly.

## 10. Handle Abort and Reset Deliberately

Do not treat abort, stop, and reset as interchangeable concepts.

A robust design defines:

- how an active operation is cancelled;
- whether deceleration is controlled;
- how a drive fault is reset;
- whether the original command must return to FALSE before retry;
- which internal states and timers are cleared.

After reset, the block should return to a known state rather than resuming from an uncertain intermediate step.

## 11. Keep Scaling Outside the Motion Decision Logic

Engineering units and drive-native units should be clearly separated.

For example:

```text
Application: rpm, mm, deg
        |
        v
Scaling / Conversion
        |
        v
Drive units: increments, counts/s, device-specific values
```

This keeps the motion logic readable and prevents scaling constants from being scattered throughout the state machine.

## 12. Design for Cyclic Execution

PLC function blocks execute repeatedly. The implementation must therefore be safe when called every task cycle.

Check that:

- initialization is not repeated unintentionally;
- one-shot actions occur only once per transition;
- timers are reset correctly;
- output values are assigned deterministically;
- previous-cycle state is intentionally retained;
- no blocking wait loops are used.

A state should normally progress over multiple PLC cycles rather than waiting synchronously for hardware.

## 13. Multi-Axis Considerations

When the same block is instantiated for multiple axes, avoid hidden shared state.

Each instance should own its:

- state machine;
- timers;
- command-edge memory;
- diagnostic data;
- axis-specific scaling or configuration.

System-level coordination should be implemented above the individual axis blocks.

For example:

```text
Axis 1 Ready --+
Axis 2 Ready --+
Axis 3 Ready --+--> AllAxesReady --> Start coordinated operation
...            |
Axis N Ready --+
```

This prevents one axis implementation from implicitly controlling another.

## 14. Test the Negative Paths

Testing only successful movement is insufficient.

A reusable block should also be tested with:

- invalid parameters;
- drive not enabled;
- communication interrupted;
- command issued while busy;
- timeout condition;
- drive fault during execution;
- reset after failure;
- repeated command cycles;
- application restart.

These tests often reveal more about software quality than the nominal motion test.

## 15. Code Review Checklist

Before considering a motion function block reusable, verify:

- [ ] Interface semantics are documented.
- [ ] Rising-edge vs level-triggered behavior is explicit.
- [ ] Inputs are validated before execution.
- [ ] Internal states have clear responsibilities.
- [ ] Completion is based on appropriate feedback.
- [ ] `Busy`, `Done`, and `Error` are deterministic.
- [ ] Diagnostic information identifies the failure category.
- [ ] External waits have timeout supervision.
- [ ] Abort and reset behavior are defined.
- [ ] Scaling is separated from control logic.
- [ ] The implementation is safe under cyclic execution.
- [ ] Instances do not depend on hidden shared state.
- [ ] Negative-path tests have been performed.

## Engineering Takeaway

A good motion-control function block is more than a wrapper around a drive command. It is a small deterministic component with a defined contract, explicit state transitions, feedback verification, timeout handling, and useful diagnostics.

Designing function blocks this way makes commissioning faster, fault investigation more systematic, and the same application architecture easier to scale from one axis to a larger multi-axis machine.
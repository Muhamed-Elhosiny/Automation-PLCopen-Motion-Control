# Structured Text Patterns for Motion-Control Applications

This page collects vendor-neutral Structured Text (ST) design patterns that make PLC motion applications easier to commission, diagnose, and maintain. The examples are intentionally generic and contain no proprietary project code.

## 1. Separate Command, State, and Feedback

A robust motion application should distinguish between:

- **Command** — what the application requests.
- **State** — which step the application is currently executing.
- **Feedback** — what the drive or motion function block confirms.

This avoids assuming that a command has succeeded simply because it was issued.

```iecst
CASE eState OF
    STATE_IDLE:
        IF xStart THEN
            eState := STATE_ENABLE;
        END_IF

    STATE_ENABLE:
        xEnableRequest := TRUE;

        IF xAxisEnabled THEN
            eState := STATE_READY;
        END_IF

    STATE_READY:
        xMotionAllowed := TRUE;
END_CASE
```

The important principle is that transitions depend on **confirmed feedback**, not only elapsed time.

## 2. Rising-Edge Commands

Many PLCopen-style function blocks expect an action on a rising edge of `Execute`. Holding `Execute := TRUE` indefinitely can make command sequencing difficult to understand.

A common pattern is:

```iecst
rtExecute(CLK := xCommand);

fbMove(
    Execute := rtExecute.Q,
    Position := lrTargetPosition,
    Velocity := lrVelocity
);
```

For application-level state machines, the command pulse can also be generated explicitly when entering a state.

## 3. Busy / Done / Error Handling

Treat `Busy`, `Done`, and `Error` as part of the command lifecycle.

```iecst
IF fbCommand.Error THEN
    eState := STATE_ERROR;
ELSIF fbCommand.Done THEN
    eState := STATE_NEXT;
END_IF
```

A useful rule is:

> Never advance a sequence only because a function block was called. Advance when the expected completion condition has been verified.

For communication or fieldbus operations, `Done` may indicate completion of the software request rather than confirmation of the final physical device state. When necessary, verify the actual device state separately.

## 4. Timeout Supervision

A state should not wait forever for hardware feedback.

```iecst
tStateTimeout(
    IN := (eState = STATE_ENABLE),
    PT := T#3S
);

IF tStateTimeout.Q THEN
    eState := STATE_ERROR;
    eError := ERR_ENABLE_TIMEOUT;
END_IF
```

Timeouts turn an indefinite startup problem into a diagnosable fault.

## 5. Explicit Error State

Centralizing failure handling keeps normal motion logic readable.

```iecst
STATE_ERROR:
    xMotionAllowed := FALSE;
    xEnableRequest := FALSE;

    IF xReset THEN
        eError := ERR_NONE;
        eState := STATE_IDLE;
    END_IF
```

Store the reason for entering the error state instead of exposing only a generic error flag.

Useful diagnostic information includes:

- axis number,
- failed initialization step,
- drive state,
- operating mode,
- function-block error ID,
- timeout source.

## 6. Multi-Axis Readiness Aggregation

For coordinated startup, calculate readiness for each axis and then derive a system-level condition.

```iecst
xAllAxesReady := TRUE;

FOR i := 1 TO AXIS_COUNT DO
    xAxisReady[i] :=
        xCommunicationOk[i]
        AND xModeConfirmed[i]
        AND xDriveEnabled[i];

    xAllAxesReady := xAllAxesReady AND xAxisReady[i];
END_FOR
```

Motion can then be gated with one clear condition:

```iecst
xStartProfile := xOperatorStart AND xAllAxesReady;
```

This scales better than long chains of individual Boolean expressions.

## 7. Keep Scaling Separate from Motion Logic

Raw drive units should be converted in a dedicated layer rather than scattered throughout the motion sequence.

```iecst
lrEngineeringVelocity := DINT_TO_REAL(diRawVelocity) / lrVelocityScale;
```

Benefits include:

- easier commissioning,
- simpler unit verification,
- fewer conversion mistakes,
- reusable motion logic across different feedback devices.

## 8. Recommended Program Structure

For cyclic motion-control code, a predictable execution order makes debugging easier:

1. Read inputs and process feedback.
2. Detect command edges.
3. Evaluate errors and timeouts.
4. Execute the application state machine.
5. Call communication and motion function blocks.
6. Write outputs / process data.
7. Update diagnostic and status flags.

The exact implementation depends on the PLC runtime, but keeping the order explicit helps prevent hidden dependencies.

## 9. Avoid Hidden State Transitions

Avoid changing the same state variable from many unrelated sections of the program. Prefer one clearly identifiable state-transition section.

This makes online debugging much easier because the engineer can answer:

- Why did the state change?
- Which condition caused it?
- What feedback was present at that moment?

## 10. Commission One Axis Before Scaling Up

A reusable development workflow is:

```text
Communication
    ↓
One axis enabled
    ↓
One axis moves correctly
    ↓
Validate scaling
    ↓
Validate fault/reset behavior
    ↓
Add additional axes
    ↓
Validate system-level readiness
    ↓
Run real-time performance tests
```

This reduces the number of simultaneous variables during troubleshooting.

## Engineering Takeaway

Good motion-control software is not only about issuing motion commands. It is about making every transition **observable, verifiable, bounded by time, and diagnosable**.

A well-structured ST application therefore combines:

- explicit state machines,
- feedback-driven transitions,
- edge-controlled commands,
- timeout supervision,
- centralized error handling,
- clear engineering-unit scaling,
- per-axis diagnostics,
- system-level readiness aggregation.

These patterns are applicable to many PLCopen and EtherCAT motion systems without depending on a particular PLC or servo-drive vendor.

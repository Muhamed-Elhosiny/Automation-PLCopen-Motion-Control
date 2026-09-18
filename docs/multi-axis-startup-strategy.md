# Multi-Axis Startup Strategy

## Purpose

This document describes a vendor-neutral strategy for bringing multiple EtherCAT servo axes from communication startup to a motion-ready state. The focus is deterministic sequencing, explicit feedback checks, fault containment, and maintainability rather than device-specific implementation details.

The approach is suitable for PLCopen-style motion applications using CiA 402 drives and is intentionally written without proprietary source code or company-specific configuration data.

## Why Multi-Axis Startup Needs a Strategy

A single servo axis can often be commissioned with a simple enable sequence. With many axes, the same approach becomes fragile because each drive can progress at a different rate. Communication startup, mode selection, feedback validity, brake handling, and CiA 402 state transitions may complete at different times.

A robust application therefore treats startup as a supervised process rather than a fixed delay followed by a global enable command.

## Recommended Startup Phases

### Phase 1 — Communication Ready

Before enabling motion, verify that the fieldbus topology is healthy and that all required devices are available.

Typical checks include:

- expected EtherCAT devices are present
- required slaves reached the intended EtherCAT state
- cyclic process data is valid
- no communication fault is active
- application-to-process-image mapping is initialized

Motion commands remain inhibited during this phase.

### Phase 2 — Drive Identification and Feedback Validation

For every configured axis, validate the minimum information required for safe application startup.

Examples:

- drive is reachable
- Statusword is updating
- actual position or velocity feedback is plausible
- configured scaling is valid
- required encoder or resolver feedback is available

This separates communication problems from motion-control problems early in the diagnostic process.

### Phase 3 — Operating Mode Confirmation

The application requests the required CiA 402 operating mode and waits for the drive to confirm it.

A useful principle is:

```text
Requested mode != confirmed mode  ->  axis not ready
Requested mode == confirmed mode  ->  continue startup
```

For a multi-axis machine, a global `ModesReady` condition can be generated from the individual axis confirmations.

```text
ModesReady = Axis1ModeReady
          AND Axis2ModeReady
          AND ...
          AND AxisNModeReady
```

The motion profile should not start until the required axes satisfy this condition.

## Phase 4 — CiA 402 Enable Sequence

Each axis progresses through the CiA 402 state machine based on Statusword feedback. The application issues the next Controlword command only after the expected previous state has been confirmed.

Conceptually:

```text
Switch On Disabled
        |
        v
Ready to Switch On
        |
        v
Switched On
        |
        v
Operation Enabled
```

The important engineering rule is that transitions are **feedback-driven**, not purely time-driven.

A timer may still be used as a timeout for diagnostics, but it should not be the primary proof that a transition succeeded.

## Phase 5 — Per-Axis Ready Evaluation

Each axis should expose a clear readiness result to the application layer.

A generic definition could be:

```text
AxisReady = CommunicationOK
        AND FeedbackValid
        AND ModeConfirmed
        AND OperationEnabled
        AND NOT FaultActive
```

This creates a clean boundary between low-level drive handling and higher-level machine logic.

## Phase 6 — Global Motion Permission

For coordinated or simultaneous operation, combine the required per-axis states into one global permission.

```text
AllRequiredAxesReady = Axis1Ready
                   AND Axis2Ready
                   AND ...
                   AND AxisNReady
```

Only then should the application release motion-profile execution.

This prevents a situation where several axes start moving while another required axis is still initializing.

## Parallel vs. Sequential Initialization

### Parallel Initialization

All drives are processed during the same PLC cycles.

**Advantages**

- fast startup
- scales naturally with cyclic state-machine logic
- suitable when communication and drive resources support concurrent requests

**Risks**

- simultaneous acyclic requests can increase bus or device load
- failures can be harder to isolate if diagnostics are weak

### Sequential Initialization

Axes are initialized one after another.

**Advantages**

- easier fault isolation
- predictable acyclic communication load
- useful during commissioning and troubleshooting

**Trade-off**

- longer total startup time

A practical architecture can support both: parallel operation for normal startup and a sequential diagnostic mode for commissioning.

## Avoid Fixed Startup Delays

A common first implementation is:

```text
request configuration
wait 2 seconds
continue
```

This can appear reliable during early tests but becomes sensitive to device count, network load, startup timing, and drive response time.

A stronger implementation uses:

```text
request configuration
wait for confirmation
if confirmed -> continue
if timeout   -> report diagnostic
```

The timer now detects a failure instead of defining success.

## Fault Handling

A multi-axis system should preserve enough information to identify which axis blocked startup and why.

Useful diagnostic information includes:

- axis number
- EtherCAT communication state
- CiA 402 drive state
- requested operating mode
- confirmed operating mode
- timeout stage
- drive fault indication

Instead of only exposing `StartupFailed`, expose a stage-specific result such as:

```text
Axis 7
Startup stage: Mode Confirmation
Requested mode: valid
Confirmed mode: not received
Result: timeout
```

This greatly reduces commissioning time.

## Recovery Strategy

A recovery path should avoid restarting healthy components unnecessarily.

Typical sequence:

1. inhibit motion
2. identify the affected axis
3. acknowledge/reset the relevant fault when permitted
4. re-evaluate communication and feedback
5. repeat the failed startup stage
6. restore global motion permission only when readiness conditions are satisfied again

Whether all axes or only the affected axis must be reinitialized depends on the machine's functional and safety requirements.

## Scaling to 12 Axes and Beyond

Repeated code for every axis quickly becomes difficult to maintain. A scalable implementation should keep the same logical interface for each drive and aggregate status systematically.

The architecture can be viewed as:

```text
Machine/Application Logic
          |
          v
Global Motion Permission
          |
          v
Axis Readiness Aggregation
          |
   +------+------+------+
   |      |      |      |
 Axis1  Axis2  Axis3  ... AxisN
   |      |      |          |
   +------+------|----------+
          |
          v
      EtherCAT
```

This separation makes it easier to add axes without redesigning the complete startup logic.

## Verification Checklist

Before allowing automatic motion, verify:

- [ ] expected EtherCAT topology is available
- [ ] cyclic process data is valid
- [ ] feedback values are plausible
- [ ] scaling is configured correctly
- [ ] requested operating mode is confirmed
- [ ] required drives reached Operation Enabled
- [ ] no required axis reports a fault
- [ ] global readiness condition is true
- [ ] motion commands are initially zero or otherwise controlled
- [ ] fault recovery has been tested

## Engineering Takeaway

The central principle of reliable multi-axis startup is simple:

> **Advance from observed state, not from assumed timing.**

A feedback-driven startup sequence is easier to diagnose, more deterministic, and more scalable than a collection of fixed delays. It also creates a clean foundation for PLCopen motion commands because the application receives an explicit indication that the drive layer is ready before motion execution begins.

---

*Portfolio note: This document describes general engineering methodology. It contains no proprietary source code, credentials, internal network information, customer data, or confidential device configuration.*
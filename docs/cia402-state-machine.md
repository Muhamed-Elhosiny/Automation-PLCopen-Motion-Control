# CiA 402 Drive State Machine — Practical Engineering Guide

## Purpose

This page documents a vendor-neutral approach to understanding, commissioning, and troubleshooting servo drives that follow the CiA 402 drive profile over EtherCAT.

The goal is not to reproduce a manufacturer implementation. Instead, it shows the engineering reasoning used to move a drive safely from startup to motion-ready operation and to diagnose a drive that does not reach the expected state.

## Why the State Machine Matters

A servo drive can exchange process data correctly and still refuse motion if its internal drive state is not ready. For this reason, motion commissioning should treat these as separate checkpoints:

1. EtherCAT communication state
2. CiA 402 drive state
3. Selected operating mode
4. Motion command path

A green EtherCAT network therefore does not automatically mean that an axis is ready to move.

## Typical Startup Path

A practical startup sequence can be viewed as:

```text
Power On
   |
   v
Switch On Disabled
   |
   | Shutdown command
   v
Ready to Switch On
   |
   | Switch On command
   v
Switched On
   |
   | Enable Operation command
   v
Operation Enabled
   |
   v
Motion permitted
```

If a fault is present, the sequence must first pass through fault handling before normal enabling can continue.

## Controlword and Statusword

CiA 402 commonly uses two process objects as the main interface between controller and drive:

- **Controlword (0x6040):** commands state transitions.
- **Statusword (0x6041):** reports the current drive state and relevant status information.

The important engineering principle is to avoid assuming that a command succeeded simply because it was written. Every transition should be confirmed using the returned status.

A robust control sequence therefore follows this pattern:

```text
Write requested transition
        |
        v
Read / evaluate Statusword
        |
        +---- expected state reached? ---- Yes ---> continue
        |
        No
        |
        v
Hold sequence and diagnose
```

## State-Decoding Strategy

The raw Statusword contains several bit fields. Application code should decode the relevant bits into a readable drive state before motion logic is executed.

A useful software architecture is:

```text
Raw Statusword
      |
      v
State Decoder
      |
      v
Drive State Enum
      |
      +--> Startup sequencer
      +--> Diagnostics
      +--> Motion interlocks
      +--> Logging
```

This keeps low-level protocol interpretation separate from the higher-level motion application.

## Recommended Enable Sequence

A deterministic implementation should advance only after the previous state has been confirmed.

```text
STATE 0: Wait for communication ready

STATE 10: Request Ready to Switch On
          Wait for confirmation

STATE 20: Request Switched On
          Wait for confirmation

STATE 30: Request Operation Enabled
          Wait for confirmation

STATE 40: Verify operating mode
          Verify axis feedback
          Permit motion commands
```

This approach is preferable to sending several state commands without checking intermediate results because it provides a clear diagnostic point when startup fails.

## Operating Mode Is a Separate Check

Reaching **Operation Enabled** does not by itself prove that the drive is configured for the intended motion mode.

Before enabling a trajectory or velocity profile, verify both:

```text
CiA 402 state = Operation Enabled
AND
Displayed operating mode = Requested operating mode
```

Only when both conditions are true should higher-level motion logic be released.

This becomes especially important in multi-axis systems, where one incorrectly initialized drive can otherwise produce inconsistent machine behavior.

## Multi-Axis Startup Strategy

For several servo axes, each drive should maintain its own state and diagnostic information.

Conceptually:

```text
Axis 1 -> State decoder -> Enable sequencer -> Ready
Axis 2 -> State decoder -> Enable sequencer -> Ready
Axis 3 -> State decoder -> Enable sequencer -> Ready
...
Axis N -> State decoder -> Enable sequencer -> Ready
                         |
                         v
                  AllAxesReady
                         |
                         v
                  Start motion profile
```

A global motion command should normally be gated by an aggregate readiness condition rather than by a fixed startup delay.

## Why Fixed Delays Are Weak

A timer-based sequence may appear to work during one test but become unreliable when:

- the number of EtherCAT devices changes,
- a drive needs additional startup time,
- an SDO transfer is delayed,
- the network is recovering from an error,
- one axis has a different hardware configuration.

State-based progression is therefore more deterministic than relying only on elapsed time.

## Troubleshooting: Drive Does Not Reach Operation Enabled

When an axis stops during startup, diagnose it layer by layer.

### 1. Verify EtherCAT State

Confirm that the slave has reached the expected EtherCAT communication state. A CiA 402 problem should not be diagnosed before the communication layer is healthy.

### 2. Inspect the Statusword

Decode the returned state instead of looking only at the outgoing Controlword.

Questions to answer:

- Which CiA 402 state is actually active?
- Did the previous transition complete?
- Is a fault bit present?
- Is the drive waiting for an external condition?

### 3. Check Controlword Progression

Confirm that the application is not repeatedly overwriting the Controlword or skipping a required intermediate state.

### 4. Check Drive Interlocks

Depending on the system, enabling may depend on conditions such as:

- safety release,
- brake handling,
- power-stage availability,
- valid feedback device,
- valid motor configuration.

These should be diagnosed separately from EtherCAT communication.

### 5. Verify the Operating Mode

Check that the requested mode has actually been accepted by the drive before starting motion.

### 6. Check Motion Setpoints

Once the drive is Operation Enabled, confirm that the target value changes and reaches the mapped process data.

This separates a **drive-state problem** from a **motion-command problem**.

## Fault Recovery Pattern

Fault handling should also be state driven.

```text
Fault detected
      |
      v
Stop motion requests
      |
      v
Capture diagnostic information
      |
      v
Issue fault reset when permitted
      |
      v
Confirm fault cleared
      |
      v
Restart normal enable sequence
```

Capturing diagnostic information before resetting is valuable because the original error context can disappear after recovery.

## Logging Recommendations

For commissioning, a compact per-axis log should include at least:

```text
Axis ID
EtherCAT state
CiA 402 decoded state
Controlword
Statusword
Requested operating mode
Displayed operating mode
Target value
Actual value
Error / fault status
```

This makes intermittent startup failures significantly easier to reproduce and compare.

## Engineering Takeaway

Reliable servo startup is not simply a sequence of writes. It is a closed-loop handshake between the controller and each drive.

The most useful design principles are:

- separate EtherCAT state from drive state,
- confirm every important transition,
- decode status into readable states,
- verify the operating mode independently,
- gate motion on confirmed readiness,
- use per-axis diagnostics in multi-axis systems,
- capture fault context before reset,
- prefer state-based logic over arbitrary startup delays.

These principles make the motion application easier to scale, troubleshoot, and maintain across different EtherCAT servo systems.

---

*Portfolio note: This document describes generic CiA 402 engineering concepts and a vendor-neutral commissioning methodology. It intentionally contains no proprietary implementation code, internal network information, customer data, or confidential device configuration.*
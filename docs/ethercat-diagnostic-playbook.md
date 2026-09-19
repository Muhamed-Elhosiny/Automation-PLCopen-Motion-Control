# EtherCAT Diagnostic Playbook

## Purpose

This page presents a vendor-neutral troubleshooting workflow for multi-axis EtherCAT motion systems. It is intended as an engineering playbook for commissioning and fault isolation rather than a collection of device-specific commands.

The central idea is simple: diagnose the system layer by layer instead of changing several parameters at once.

---

## 1. Diagnostic Layers

A motion problem can originate at different levels:

1. **Physical layer** — cabling, power, connectors, link status.
2. **EtherCAT network layer** — slave discovery and AL states.
3. **Process-data layer** — PDO mapping, Working Counter and cyclic data.
4. **Drive layer** — CiA 402 state and faults.
5. **Motion-mode layer** — requested and displayed operating mode.
6. **Application layer** — command generation, scaling, interlocks and sequencing.

Checking these layers in this order reduces unnecessary software changes when the real problem is lower in the stack.

---

## 2. Start With the Physical System

Before debugging software, verify:

- controller and drive power,
- EtherCAT link/activity indication,
- cable order and topology,
- motor and feedback connections,
- safety or hardware-enable conditions,
- expected number of connected slaves.

A software diagnosis is unreliable if the physical topology is unstable.

---

## 3. Verify Slave Discovery

Compare the configured network with the detected network.

Check:

- slave count,
- slave order,
- identity information,
- device description consistency,
- expected physical position.

### Typical symptom

The network does not reach the requested state even though most devices appear correctly configured.

### Engineering approach

Identify the first device where configured and detected information diverge. Problems later in the chain can be secondary effects of an earlier mismatch.

---

## 4. Check EtherCAT AL States

A typical startup progression is:

```text
INIT -> PRE-OP -> SAFE-OP -> OP
```

Do not treat `OP` as the only useful diagnostic value. The state at which progression stops provides information about the failure.

### If a device remains in INIT

Investigate discovery, identity, communication and initialization configuration.

### If a device remains in PRE-OP

Investigate startup parameterization and configuration transfers.

### If a device reaches SAFE-OP but not OP

Investigate process-data validity, synchronization and cyclic communication.

### If all devices reach OP but the motor does not move

Continue with drive-state and application diagnostics. EtherCAT `OP` does **not** mean that the drive is motion-enabled.

---

## 5. Verify Cyclic Process Data

Once the EtherCAT network is operational, inspect whether cyclic data is actually changing.

Useful signals include:

- Controlword,
- Statusword,
- target velocity or position,
- actual velocity or position,
- requested mode,
- displayed mode,
- drive error information.

A particularly useful technique is to follow one command through the complete signal path:

```text
Application command
       |
       v
Motion function block
       |
       v
Scaled target value
       |
       v
PDO output
       |
       v
Servo drive
       |
       v
PDO feedback
       |
       v
Application feedback
```

The first point where the expected value disappears usually identifies the responsible layer.

---

## 6. Separate EtherCAT State From Drive State

Two independent state machines are involved:

```text
EtherCAT AL state          CiA 402 drive state
-----------------          -------------------
INIT                       Switch On Disabled
PRE-OP                     Ready to Switch On
SAFE-OP                    Switched On
OP                         Operation Enabled
```

These columns are not equivalent mappings.

For example, a slave can be in EtherCAT `OP` while its servo drive is still `Switch On Disabled`.

This distinction prevents a common commissioning mistake: investigating the fieldbus when the network is already healthy and the remaining issue is inside the drive state machine.

---

## 7. Verify CiA 402 Enable Progression

For a drive that is communicating but not moving, inspect Statusword feedback after every state request.

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

Do not advance only because a command was transmitted. Advance when the corresponding feedback confirms the transition.

For multi-axis systems, maintain readiness information per axis so that one failing drive can be identified without hiding the state of the remaining axes.

---

## 8. Confirm the Operating Mode

Motion commands should be released only after the requested operating mode is confirmed by drive feedback.

Recommended logic:

```text
Request mode
    |
    v
Read displayed mode
    |
    +-- mismatch --> keep motion inhibited
    |
    +-- match -----> continue startup
```

For a multi-axis system, a global start condition can be derived from all required axes:

```text
AllAxesReady =
    Axis1Ready AND
    Axis2Ready AND
    ...
    AxisNReady
```

This prevents partially initialized systems from beginning coordinated motion.

---

## 9. When Target Values Are Correct but Motion Is Missing

If the drive is enabled and the correct mode is confirmed, inspect:

- whether the target reaches the process image,
- scaling and engineering units,
- direction/sign conventions,
- motion interlocks,
- software limits,
- brake handling,
- command execution edges,
- actual feedback response.

Avoid immediately increasing the target command. A stationary motor can indicate an enable or scaling problem rather than an insufficient command.

---

## 10. Intermittent Startup Failures

Intermittent failures require a different approach from deterministic failures.

Capture the same diagnostic variables on every startup:

```text
Timestamp
Slave state
Drive state
Requested mode
Displayed mode
Error flag
Error code
Initialization step
```

Then compare successful and unsuccessful runs.

This turns an apparently random problem into a state-transition comparison.

### Parallel vs. sequential initialization

If failures appear only when many axes initialize simultaneously, compare:

1. parallel initialization of all axes,
2. controlled sequential initialization.

The comparison can reveal timing sensitivity or resource contention without assuming either strategy is inherently correct.

---

## 11. Real-Time Performance Checks

After functional commissioning, verify that the system remains deterministic under load.

Observe:

- configured task period,
- average execution time,
- maximum execution time,
- cycle jitter,
- EtherCAT communication errors,
- CPU load,
- behavior while multiple axes are moving.

Test progressively:

```text
Network operational
      -> drives enabled
      -> one axis moving
      -> several axes moving
      -> full multi-axis motion
```

A system that works while idle but becomes unstable during motion may have a timing or workload issue rather than a motion-command problem.

---

## 12. Minimal Diagnostic Snapshot

For each axis, a compact diagnostic structure should expose at least:

```text
EtherCAT state
CiA 402 state
Controlword
Statusword
Requested mode
Displayed mode
Target value
Actual value
Error status
Error code
```

For the controller, additionally record:

```text
Task cycle time
Maximum runtime
Jitter
CPU load
EtherCAT error counters
```

This creates a repeatable commissioning baseline and makes later regression testing much easier.

---

## 13. Troubleshooting Decision Tree

```text
Motor does not move
       |
       v
Is slave detected?
  |            |
 No           Yes
  |            |
Physical /    Is EtherCAT OP?
identity       |          |
checks        No         Yes
               |          |
          AL-state        Is drive Operation Enabled?
          diagnosis       |                 |
                         No                Yes
                          |                 |
                     CiA 402          Is mode confirmed?
                     diagnosis          |          |
                                      No          Yes
                                       |           |
                                  Mode setup   Trace target -> PDO -> drive
```

The value of this tree is not that every failure fits one branch perfectly. Its purpose is to keep troubleshooting structured and prevent unrelated configuration changes.

---

## Engineering Principle

A robust commissioning process should answer three questions at every layer:

1. **What command did I send?**
2. **What feedback did I receive?**
3. **What condition allows the next state?**

When those three items are observable, even a large multi-axis EtherCAT system becomes much easier to diagnose systematically.

---

## Portfolio Note

This document intentionally uses generic architecture and vendor-neutral examples. It demonstrates the diagnostic methodology used for industrial motion-control commissioning without exposing proprietary source code, internal network information, customer data, or confidential implementation details.
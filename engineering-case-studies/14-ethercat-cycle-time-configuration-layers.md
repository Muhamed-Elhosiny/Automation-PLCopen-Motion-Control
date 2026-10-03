# Case 14 — Diagnosing Multiple Cycle-Time Settings in a Real-Time EtherCAT System

## Context

A multi-axis EtherCAT motion system used a 1 ms cyclic PLC task and a 1 ms EtherCAT communication cycle. During performance and stability testing, several configuration interfaces exposed values labeled as cycle time, including the application task configuration, EtherCAT configuration, controller/runtime settings, and a separate system I/O cycle.

The engineering challenge was to determine which timing parameters belonged to the motion-control path and which belonged to independent subsystems, rather than assuming that every value labeled "cycle time" had to be identical.

## Symptom

Multiple cycle-time values were visible in different configuration interfaces. This created uncertainty about whether mismatched values represented an error and whether an unrelated system I/O cycle could explain EtherCAT instability.

The risk was that changing every timing parameter to the same value could hide the real scheduling relationship or introduce new behavior without addressing the actual problem.

## Evidence

The timing investigation separated the system into layers:

- cyclic PLC application task,
- EtherCAT master/process-data exchange,
- motion-control execution inside the PLC task,
- independent system I/O or service cycles,
- operating-system scheduling and communication services.

The motion application was already instrumented to measure cyclic execution behavior. Measurements showed an application cycle close to the intended 1 ms period while separate stress tests demonstrated that system-wide CPU pressure could still disturb EtherCAT communication.

This was important evidence: a nominal 1 ms application cycle does not prove that every lower-level communication service always receives sufficient scheduling time.

## Investigation

The investigation used a configuration-ownership approach instead of changing values immediately.

### 1. Identify the owner of each timing parameter

For every visible cycle-time setting, determine which subsystem consumes it:

```text
PLC task period
    -> determines how often application logic executes

EtherCAT cycle
    -> determines cyclic fieldbus/process-data exchange

System I/O/service cycle
    -> belongs to its own subsystem unless explicitly coupled

OS/runtime scheduling
    -> determines whether cyclic services receive CPU time when required
```

### 2. Trace the motion data path

The relevant path was treated as:

```text
Application task
      |
      v
Motion logic / process-image update
      |
      v
EtherCAT cyclic exchange
      |
      v
Servo drives
```

Only timing parameters that participate in this path should be assumed to have a direct relationship to motion communication.

### 3. Verify timing relationships, not just equal numbers

A correct configuration is not defined by making every displayed cycle time numerically equal. The important questions are:

- Is the application task deterministic enough for the required control rate?
- Is process data updated at the expected point relative to the EtherCAT cycle?
- Are task and fieldbus periods intentionally synchronized or related by a supported ratio?
- Are unrelated I/O services being mistaken for the EtherCAT cycle?
- Do runtime logs show missed deadlines, frame timeouts, or task overruns?

### 4. Correlate configuration with measurements

Configuration values were evaluated together with measured cycle statistics and communication logs. This avoided treating a configuration screenshot as proof of actual real-time behavior.

## Root Cause / Engineering Conclusion

No single "global cycle time" exists simply because several configuration pages use similar terminology. The settings belong to different scheduling and communication layers.

For the motion path, the PLC task period and EtherCAT process-data cycle are directly relevant and must be configured with a deliberate timing relationship. A separate system I/O cycle should not be changed merely to match them unless documentation or architecture confirms that it participates in the same data path.

The investigation also reinforced that matching nominal periods alone cannot guarantee real-time stability. CPU scheduling pressure, communication-service latency, and deadline misses must be evaluated independently.

## Resolution

The configuration was handled by subsystem ownership:

1. Preserve the intended PLC task period.
2. Preserve the intended EtherCAT communication period.
3. Confirm their relationship through runtime configuration and measurements.
4. Leave unrelated subsystem cycles unchanged unless there is evidence that they affect the motion path.
5. Use cycle statistics and EtherCAT logs to validate actual timing behavior under load.

This avoided unnecessary configuration changes and kept troubleshooting focused on the components that actually participate in cyclic motion communication.

## Verification

A timing configuration is considered validated when the following evidence agrees:

- configured PLC task period,
- configured EtherCAT cycle,
- measured cyclic execution statistics,
- stable process-data exchange,
- expected EtherCAT slave states,
- absence of task-overrun or frame-timeout symptoms during the defined test condition.

Stress testing should then be repeated because a system that is correct at idle may still violate real-time deadlines under CPU pressure.

## Engineering Lessons

- Similar labels in different configuration interfaces do not imply the same scheduler or subsystem.
- Trace ownership and the actual data path before changing timing parameters.
- PLC task timing, EtherCAT cycle timing, and OS scheduling are related but distinct engineering concerns.
- Nominal cycle-time equality is not proof of deterministic execution.
- Real-time validation requires measurements and logs, not configuration values alone.
- Unrelated subsystem parameters should not be changed without evidence; controlled experiments preserve diagnostic clarity.

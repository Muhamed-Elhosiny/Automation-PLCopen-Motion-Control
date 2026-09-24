# Intermittent Fault Investigation in Motion-Control Systems

Intermittent failures are among the most difficult problems in industrial automation because the system may operate correctly for hours and then fail only once. A useful investigation therefore needs more than a single error message: it needs reproducibility, synchronized evidence, controlled experiments, and a clear separation between symptom and root cause.

This guide presents a vendor-neutral workflow for investigating intermittent faults in PLC, EtherCAT, and multi-axis servo applications.

## 1. Define the Symptom Precisely

Avoid descriptions such as:

> The drive sometimes stops.

Instead, record observable facts:

- Which axis or device was affected?
- Was motion active when the event occurred?
- Did the fieldbus remain operational?
- Did the drive leave `Operation Enabled`?
- Did the PLC task continue running?
- Was an application function block in `Busy`, `Done`, or `Error`?
- Was the failure temporary or did it require recovery?

A precise symptom statement makes later comparisons possible.

## 2. Build an Evidence Timeline

For every occurrence, reconstruct the event across several layers.

| Layer | Evidence to Capture |
|---|---|
| Application | state-machine state, command status, error ID |
| Motion | commanded and actual position/velocity |
| Drive | CiA 402 state, statusword, fault information |
| EtherCAT | slave state, working-counter or communication errors |
| Real-time task | cycle time, maximum runtime, jitter |
| System | CPU load and relevant system logs |

The important point is correlation. A fieldbus warning that happened several seconds after the axis stopped may be a consequence rather than the original cause.

## 3. Establish a Known-Good Baseline

Before stressing the system, record a configuration that operates reliably.

Example baseline:

```text
Controller task: cyclic
Motion axes: enabled
Command profile: repetitive forward/reverse motion
Communication: operational
Test duration: defined
Observed failures: 0
```

The baseline gives every later experiment a reference point.

## 4. Change One Variable at a Time

Intermittent problems become difficult to interpret when several parameters change simultaneously.

Useful controlled variations include:

- task period
- number of active axes
- stationary vs moving axes
- communication load
- initialization strategy
- parallel vs sequential service communication
- additional CPU workload
- test duration

Example experiment matrix:

| Test | Axes | Motion | Added Load | Initialization | Result |
|---|---:|---|---|---|---|
| A | 1 | No | No | Sequential | Pass |
| B | Multiple | No | No | Sequential | Pass |
| C | Multiple | Yes | No | Sequential | Pass/Fail |
| D | Multiple | Yes | Yes | Sequential | Pass/Fail |
| E | Multiple | Yes | Yes | Parallel | Pass/Fail |

The objective is not merely to reproduce the fault. It is to discover which condition changes its probability.

## 5. Separate Trigger, Failure, and Recovery

Treat these as three different questions.

### Trigger

What condition existed immediately before the event?

Examples:

- increased execution time
- simultaneous service requests
- state transition
- motion command edge
- communication disturbance

### Failure

What was the first component that deviated from normal behavior?

Examples:

- application timeout
- drive state transition failure
- missed cyclic communication
- task overrun

### Recovery

What restored operation?

Examples:

- automatic retry
- fault reset
- re-enable sequence
- fieldbus state transition
- controller restart

Recovery behavior is useful evidence, but it should not be confused with the root cause.

## 6. Use Positive and Negative Evidence

Good debugging records both what failed and what remained correct.

Example:

```text
Observed:
- Axis stopped responding to the command.
- PLC application continued executing.
- Other axes remained operational.
- No global EtherCAT state loss was observed.
```

The last three observations eliminate entire categories of possible causes.

## 7. Verify Requested State Against Actual State

A completed command does not always prove that the physical device reached the expected state.

For important transitions, verify feedback explicitly:

```text
Request state
    ↓
Command accepted
    ↓
Read actual state
    ↓
Expected state reached?
    ├─ Yes → continue
    └─ No  → capture diagnostics and stop sequence
```

This principle applies to:

- EtherCAT state transitions
- CiA 402 drive states
- operating modes
- homing
- motion commands

## 8. Capture Data Before Resetting

A reset can destroy valuable diagnostic information.

Recommended order after a failure:

1. Freeze or save the trace.
2. Record application state and error codes.
3. Record drive state and status information.
4. Capture fieldbus diagnostics.
5. Capture real-time timing statistics.
6. Save relevant logs.
7. Only then perform recovery.

## 9. Reproduction Quality

A strong reproduction procedure should specify:

```text
Preconditions
→ startup sequence
→ operating state
→ workload
→ motion profile
→ expected behavior
→ observed failure
→ approximate reproduction frequency
```

For example, `3 failures in 20 runs` is much more useful than `fails sometimes`.

## 10. Long-Duration Testing

For rare failures, duration matters.

Record at least:

- start and end time
- total cycles or repetitions
- number of failures
- time to first failure
- minimum/maximum/average cycle time
- maximum observed execution time
- communication error count

A successful short test does not necessarily disprove an intermittent problem.

## 11. Root-Cause Confidence

Classify conclusions according to evidence.

### Confirmed

Changing or correcting one identified condition repeatedly removes the failure and restoring that condition reproduces it.

### Strong correlation

The condition consistently appears with the failure, but causality has not yet been demonstrated.

### Hypothesis

The explanation is technically plausible but still requires an experiment.

This distinction prevents assumptions from becoming undocumented "facts" during debugging.

## 12. Practical Investigation Flow

```text
Intermittent failure
        │
        ▼
Define exact symptom
        │
        ▼
Capture synchronized evidence
        │
        ▼
Establish known-good baseline
        │
        ▼
Reproduce under controlled conditions
        │
        ▼
Change one variable at a time
        │
        ▼
Identify first abnormal event
        │
        ▼
Form hypothesis
        │
        ▼
Design experiment that can disprove it
        │
        ▼
Repeat and quantify result
        │
        ▼
Document conclusion and recovery
```

## Engineering Principle

The goal of troubleshooting is not to collect the largest number of logs. It is to create a chain of evidence that explains **what happened first, under which conditions, and whether the explanation survives repeated controlled testing**.

That approach turns an intermittent automation problem from an anecdotal failure into a reproducible engineering investigation.

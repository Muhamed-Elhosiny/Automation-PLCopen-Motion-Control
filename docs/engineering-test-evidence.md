# Engineering Test Evidence for Motion-Control Systems

A motion-control test is much more valuable when the result can be reproduced, reviewed, and traced back to objective evidence. This guide describes a vendor-neutral way to document PLC, EtherCAT, and multi-axis servo tests without exposing proprietary project data.

## 1. Why test evidence matters

A statement such as "the axes ran for one hour" is useful, but incomplete. A professional engineering record should also answer:

- What configuration was tested?
- What was the expected behavior?
- What was actually observed?
- Which measurements support the conclusion?
- Can another engineer reproduce the test?
- If a failure occurred, at what layer did it originate?

The objective is not to collect as many logs as possible. The objective is to preserve enough evidence to support an engineering conclusion.

## 2. Recommended evidence package

For each significant test, keep a compact evidence package containing:

1. **Test identifier** — short unique name or number.
2. **Purpose** — what question the test is intended to answer.
3. **Configuration** — controller cycle, fieldbus cycle, number of axes, operating mode, and relevant application state.
4. **Preconditions** — conditions that must be true before execution.
5. **Procedure** — reproducible sequence of actions.
6. **Expected result** — objective pass condition.
7. **Observed result** — what actually happened.
8. **Measurements** — timing, jitter, error counters, drive states, or other relevant signals.
9. **Evidence references** — log names, screenshots, traces, or exported measurements.
10. **Conclusion** — pass, fail, or investigation required, with the reason.

## 3. Example test record

| Field | Example |
|---|---|
| Test ID | RT-MOTION-01 |
| Purpose | Verify cyclic motion under sustained controller load |
| Axes | Multi-axis configuration |
| Control mode | Cyclic synchronous velocity |
| PLC cycle | 1 ms |
| Test duration | 60 min |
| Expected | Continuous motion with no fieldbus or drive fault |
| Evidence | Cycle statistics + fieldbus log + drive-state trace |
| Result | Record measured outcome |

Values in a public portfolio should remain generic unless the underlying measurements are explicitly approved for publication.

## 4. Capture evidence at multiple layers

Motion failures are easier to diagnose when evidence is collected from several layers at the same time.

### Application layer

Record:

- motion state-machine state,
- command activation,
- PLCopen `Busy`, `Done`, and `Error`,
- application error IDs,
- readiness/interlock conditions.

### Drive layer

Record:

- CiA 402 state,
- Statusword,
- active operating mode,
- actual velocity or position,
- drive fault information.

### EtherCAT layer

Record:

- network state,
- working-counter or communication errors,
- state-transition failures,
- distributed-clock or synchronization diagnostics where applicable.

### Real-time layer

Record:

- task cycle time,
- minimum and maximum execution/cycle values,
- average cycle time,
- jitter,
- CPU/load information where available.

A single screenshot rarely proves the root cause. Correlating these layers produces much stronger evidence.

## 5. Preserve timestamps

Timestamps are essential when several logs must be correlated.

For example:

```text
15:39:00  Load test started
15:47:32  Application debugging connection lost
15:47:32  EtherCAT communication remained operational
15:47:33  Drive states sampled
15:49:00  Test stopped manually
```

This makes it possible to distinguish events that happened at the same time from events that merely appeared related.

Whenever possible, keep all diagnostic sources synchronized to the same time base.

## 6. Separate symptom from root cause

An engineering report should distinguish observation from interpretation.

Poor conclusion:

> The motor stopped because EtherCAT failed.

Better structure:

```text
Observation:
Axis motion stopped at 14:52:18.

Evidence:
- Application state changed to ERROR.
- Drive remained communication-ready.
- No corresponding fieldbus error was recorded.

Conclusion:
The available evidence points to the application layer; no EtherCAT failure was observed during the event.
```

This prevents an early assumption from becoming an unsupported root-cause statement.

## 7. Reproducibility matrix

Intermittent failures should be tested systematically.

| Run | Load | Cycle | Motion | Duration | Failure | Time to failure |
|---:|---:|---:|---|---:|---|---:|
| 1 | baseline | 1 ms | enabled | 30 min | no | — |
| 2 | medium | 1 ms | moving | 60 min | yes/no | record |
| 3 | high | 1 ms | moving | 60 min | yes/no | record |

Repeated runs help distinguish deterministic defects from sporadic behavior.

## 8. Change one variable at a time

When investigating a failure, change one controlled variable between test runs whenever practical:

```text
Run A: baseline configuration
Run B: same configuration + increased CPU load
Run C: same load + different task cycle
Run D: same task cycle + sequential initialization
```

If many parameters change simultaneously, the result becomes difficult to interpret.

## 9. Positive and negative evidence

Both are important.

**Positive evidence** confirms that something happened:

- a drive entered Fault,
- a timeout was raised,
- a fieldbus state transition failed.

**Negative evidence** records that a monitored subsystem showed no failure during the same interval:

- no communication error was logged,
- the drive remained Operation Enabled,
- cycle statistics stayed within the expected range.

Negative evidence should be phrased carefully: absence of a recorded error is not proof that every possible failure mechanism was absent.

## 10. Long-duration test checklist

Before starting:

- reset diagnostic counters,
- record software/test configuration,
- confirm all axes are ready,
- confirm logging is active,
- record initial cycle statistics.

During the test:

- avoid changing unrelated parameters,
- preserve timestamps,
- record important operator actions,
- capture the first failure before resetting anything.

After the test:

- export logs before restarting components,
- save timing statistics,
- record final drive and network states,
- document whether the result was reproducible.

## 11. Evidence naming convention

Consistent filenames make later analysis easier:

```text
YYYY-MM-DD_<test-id>_<evidence-type>_<run>.<ext>
```

Example:

```text
2026-09-23_RT-MOTION-01_cycle-statistics_run02.csv
2026-09-23_RT-MOTION-01_fieldbus-log_run02.txt
2026-09-23_RT-MOTION-01_state-trace_run02.csv
```

Avoid credentials, internal addresses, serial numbers, customer names, or confidential product identifiers in public filenames and exported logs.

## 12. Portfolio-safe reporting

A public engineering portfolio should demonstrate methodology rather than expose employer information. Good public material includes:

- generic test architecture,
- measurement methodology,
- anonymized results,
- diagnostic reasoning,
- reusable checklists,
- vendor-neutral example code.

Before publishing real logs or screenshots, remove or replace internal hostnames, IP addresses, serial numbers, credentials, customer data, proprietary source code, and confidential project names.

## 13. Engineering principle

> A reproducible failure with synchronized evidence is more useful than a failure description without context.

Good test documentation turns commissioning experience into traceable engineering knowledge and makes communication between application, firmware, fieldbus, and real-time teams much more effective.

# Real-Time Motion Test Methodology

## Purpose

A motion-control application can appear to work correctly while still having timing, communication, or scalability problems that only become visible under sustained load. This guide presents a vendor-neutral methodology for validating a cyclic PLC/EtherCAT motion application before treating a multi-axis test as stable.

The focus is not a particular controller or drive. The goal is to demonstrate a repeatable engineering process that separates functional motion testing from real-time performance validation.

## 1. Define the Test Objective First

Before collecting measurements, define what the test is intended to prove. Typical objectives include:

- all configured axes remain operational for the complete test duration;
- cyclic communication remains stable while axes are moving;
- PLC task execution stays within its timing budget;
- increasing axis count does not introduce unacceptable jitter or overruns;
- faults can be correlated with controller, fieldbus, or drive diagnostics.

A useful test has a pass/fail criterion before it starts. Without one, a five-minute trace can produce many numbers without answering whether the system is actually acceptable.

## 2. Establish a Baseline

Start with the communication network operational but without commanded motion. Record a baseline for:

- configured PLC task period;
- actual cycle-time minimum, maximum, and average;
- peak-to-peak jitter;
- CPU load;
- EtherCAT state of every device;
- communication error counters;
- application error and warning status.

This baseline provides the reference needed to distinguish load-related effects from behavior that already exists at idle.

## 3. Increase Load in Controlled Steps

Do not jump directly from idle to the maximum number of moving axes when investigating performance.

A useful progression is:

```text
Network operational, axes idle
        |
        v
One axis moving
        |
        v
Small axis group moving
        |
        v
Half of configured axes moving
        |
        v
All axes moving
        |
        v
Sustained full-load test
```

At every step, capture the same measurement set. This makes the result comparable and helps identify the load level at which behavior changes.

## 4. Separate Three Different Timing Questions

### 4.1 Cycle accuracy

For a nominal task period `T_nominal`, calculate the deviation of the measured average:

```text
Average deviation = T_average - T_nominal
```

The average indicates whether the cyclic task is centered near its intended period, but it does not describe worst-case behavior.

### 4.2 Jitter

A simple peak-to-peak measure is:

```text
Jitter_pp = T_max - T_min
```

This is useful for comparing otherwise identical tests. A single jitter number should not be interpreted without also considering the task deadline and the individual minimum and maximum values.

### 4.3 Execution-time margin

Cycle period and code execution time are not the same quantity. When execution-time measurement is available, calculate the remaining timing margin:

```text
Timing margin = Task period - Worst-case execution time
```

The worst-case execution time is often more important for overload analysis than the average execution time.

## 5. Correlate Motion and Communication Data

If an axis stops unexpectedly, do not treat the motor stop itself as the root cause. Capture evidence from multiple layers around the same time.

### Application layer

Check:

- command state;
- PLCopen FB `Busy`, `Done`, `Error`, and `ErrorID`;
- application state-machine state;
- enable/interlock status;
- requested velocity or position.

### Drive layer

Check:

- CiA 402 state;
- Statusword;
- operating mode display;
- drive fault code;
- actual velocity and position.

### EtherCAT layer

Check:

- device state (`INIT`, `PRE-OP`, `SAFE-OP`, `OP`);
- working-counter or communication errors when available;
- lost-link or frame-error counters;
- distributed-clock/synchronization diagnostics when used.

### Controller layer

Check:

- CPU load;
- task overrun/deadline diagnostics;
- cycle-time statistics;
- system logs near the event timestamp.

The most useful evidence is the combination of these layers, not any single value.

## 6. Use Timestamps

A performance trace becomes significantly more useful when measurements and logs can be aligned in time.

For an unexpected event, record at least:

```text
Event timestamp
Axis number
Application state
Motion FB state/error
Drive state/error
EtherCAT state/error
CPU/task diagnostics
```

This turns an observation such as "an axis stopped during the test" into a reproducible diagnostic case.

## 7. Test Duration

Short tests are useful during commissioning, but sustained tests are required for intermittent failures.

A practical strategy is:

1. short functional test to confirm correct direction and scaling;
2. several-minute performance test after each configuration change;
3. longer soak test after the system is functionally stable;
4. repeat the same test after significant software, cycle-time, or topology changes.

The duration should be chosen based on the failure being investigated. If a fault historically occurs only after several minutes, a ten-second test cannot provide meaningful evidence that it has been solved.

## 8. Keep a Reproducible Test Record

For every important run, save a compact test record:

| Field | Example description |
|---|---|
| Software revision | Commit/build identifier |
| PLC task period | Configured cyclic period |
| EtherCAT cycle | Configured bus period |
| Axis count | Enabled / moving axes |
| Motion profile | Velocity or position pattern |
| Test duration | Actual measurement duration |
| CPU load | Average / relevant peak |
| Cycle time | Min / max / average |
| Jitter | Peak-to-peak |
| Bus errors | Counter before / after |
| Result | Pass / fail with reason |

This is more valuable than screenshots without context because another engineer can repeat the same test.

## 9. Suggested Pass/Fail Structure

Avoid universal timing limits unless the system specification defines them. Instead, derive acceptance criteria from the application's requirements.

Example structure:

```text
PASS if:
- all required axes remain operational;
- no unexpected drive faults occur;
- no EtherCAT state loss occurs;
- no task deadline/overrun occurs;
- measured timing remains inside the project-specific limit.

FAIL if any required criterion is violated.
```

The limits should come from the actual machine and control requirements, not from an arbitrary percentage copied from another project.

## 10. Diagnostic Decision Flow

```text
Unexpected motion stop
        |
        v
Did the application remove the command?
   | yes                | no
   v                    v
Inspect sequence     Is drive still
and interlocks       Operation Enabled?
                         |
                 +-------+-------+
                 |               |
                no              yes
                 |               |
                 v               v
          Inspect CiA 402    Check setpoint,
          and drive fault    PDO data and scaling
                 |
                 v
       Did EtherCAT leave OP?
                 |
          +------+------+
          |             |
         yes            no
          |             |
          v             v
   Inspect bus/DC    Inspect drive and
   and task timing   application diagnostics
```

The key principle is to identify the first layer whose state changed unexpectedly.

## 11. What a Strong Performance Report Should Show

A concise engineering report should answer five questions:

1. **What configuration was tested?**
2. **What workload was applied?**
3. **What was measured?**
4. **Did the system satisfy the defined criteria?**
5. **If not, which evidence identifies the failing layer?**

This structure makes performance testing useful for debugging, regression testing, and technical communication.

## Engineering Takeaway

Reliable multi-axis motion testing is not simply proving that several motors rotate simultaneously. A stronger validation method combines functional behavior, real-time task timing, fieldbus diagnostics, drive state, and reproducible test conditions.

That approach makes intermittent problems easier to isolate and provides evidence that a control system remains deterministic as workload increases.

---

*This document is intentionally vendor-neutral and contains no proprietary controller code, network addresses, credentials, or customer-specific information.*
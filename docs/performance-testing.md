# Performance Testing

## Purpose

This page documents performance measurements for a multi-axis EtherCAT motion-control setup using a 1 ms cyclic task. The objective is to evaluate whether the control application can maintain a stable real-time cycle while the number of enabled and moving servo axes is increased.

The focus is not only on average execution time, but also on timing stability, jitter, scalability, and the effect of motion activity on the cyclic task.

---

## Test Setup

### Control System

- Industrial controller running a real-time cyclic application
- EtherCAT communication
- Servo drives using CiA 402
- PLCopen-style motion-control function blocks
- Control task cycle: **1 ms**
- EtherCAT cycle: **1 ms**

### Test Strategy

The system was tested progressively so that timing behavior could be compared under different levels of load.

1. EtherCAT operational, servo axes not enabled
2. Servo axes enabled without motion
3. Five axes moving
4. Ten axes moving
5. Twelve axes moving

The main timing values observed during the tests were:

- Average cycle time
- Minimum cycle time
- Maximum cycle time
- Jitter
- CPU load
- EtherCAT communication errors

---

## Reference Measurements

During the multi-axis test campaign, the cyclic task remained close to its configured 1 ms period.

| Test Condition | Approx. Average Cycle Time | Observed Jitter |
|---|---:|---:|
| 5 axes moving | ~999.7 µs | ~80–85 µs |
| Multi-axis motion load | ~999.7 µs | ~80 µs |

The measured average remained very close to the configured **1000 µs** cycle period.

These measurements were used as practical indicators of timing stability during commissioning rather than as formal hard-real-time certification data.

---

## Progressive Load Test

### Test 1 — EtherCAT Operational, Axes Disabled

**Objective**  
Establish a baseline measurement with the EtherCAT network in Operational state but without enabling the servo axes.

**Checks**

- EtherCAT remains in OP state
- No unexpected communication errors
- Task period remains close to 1 ms
- Baseline minimum and maximum cycle values are recorded

This test provides a reference for comparing the additional workload introduced by drive enabling and motion execution.

---

### Test 2 — Servo Axes Enabled, No Motion

**Objective**  
Determine whether enabling the servo drives and running the CiA 402 control logic introduces a significant change in cyclic execution time.

**Additional application load includes:**

- CiA 402 state evaluation
- Control-word generation
- Status-word evaluation
- PLCopen function-block logic
- Process-data exchange with the drives

The result should be compared with the disabled-axis baseline before introducing motion commands.

---

### Test 3 — Five Axes Moving

**Objective**  
Evaluate real-time behavior under simultaneous multi-axis motion.

The motion-control application executes cyclic calculations for multiple active servo axes while process data is exchanged through EtherCAT every millisecond.

A representative measured average cycle time was approximately:

```text
999.7 µs
```

with jitter in the range of approximately:

```text
80–85 µs
```

The important observation was that the task continued to execute close to the configured 1 ms period while multiple drives were moving.

---

### Test 4 — Ten Axes Moving

**Objective**  
Increase the application and communication load and verify that the timing behavior remains stable as the number of active axes grows.

The following items should be checked during this stage:

- Average task cycle
- Worst-case cycle time
- Jitter increase compared with five axes
- EtherCAT Working Counter / communication errors
- Motion consistency
- CPU utilization

A stable result at this stage demonstrates that the architecture scales beyond a small laboratory configuration.

---

### Test 5 — Twelve Axes Moving

**Objective**  
Validate the complete multi-axis configuration under the highest tested motion load.

At this stage, all twelve servo axes participate in the cyclic motion-control application.

The main acceptance criteria are:

- All EtherCAT slaves remain in OP state
- No cyclic communication faults
- No motion interruptions caused by task overruns
- Cycle time remains close to 1 ms
- Jitter remains within an acceptable range for the application

The test demonstrated that the application could operate a **12-axis EtherCAT servo system with a 1 ms control cycle** while maintaining an average cycle time close to the configured period.

---

## What Jitter Means in This Test

For a nominal 1 ms task, the ideal execution interval would be exactly:

```text
1000 µs
```

In practice, small variations occur between individual cycles.

A simplified definition used during the test is:

```text
Jitter = Maximum Cycle Time - Minimum Cycle Time
```

For example, if the measured cycle interval varies around the 1 ms target, the jitter value helps quantify the spread between the fastest and slowest observed cycles.

Jitter is important in motion-control systems because excessive timing variation can affect deterministic process-data exchange and the consistency of control calculations.

---

## Engineering Interpretation

The most useful result from this test was not simply that the average value was close to 1 ms. The progressive-load approach helped verify that the system remained stable as additional servo axes were enabled and moved.

This is important because a motion-control application adds several types of load simultaneously:

- EtherCAT process-data exchange
- CiA 402 state-machine processing
- PLCopen motion logic
- Velocity and position calculations
- Error and diagnostic handling
- Multi-axis application logic

A system that performs well with one axis does not automatically guarantee the same behavior with twelve axes. Progressive testing therefore provides a more realistic assessment of scalability.

---

## Practical Debugging Method

When cycle-time behavior becomes unstable, the following sequence is useful:

1. Test the cyclic task with EtherCAT disconnected or inactive if possible.
2. Bring EtherCAT to OP without enabling the axes.
3. Enable the drives without issuing motion commands.
4. Move a small number of axes.
5. Increase the active-axis count step by step.
6. Compare minimum, maximum, average, and jitter values after every step.
7. Check EtherCAT errors and CPU load whenever a timing increase appears.

This method helps isolate whether timing degradation is caused mainly by:

- Application code
- Drive-state processing
- Motion calculations
- EtherCAT communication
- Operating-system scheduling
- Other background services

---

## Result Summary

The performance test demonstrated the following engineering points:

- A **1 ms cyclic motion-control task** was achieved in the tested configuration.
- The average cycle remained close to **999.7 µs** during motion testing.
- Measured jitter was approximately **80–85 µs** in representative tests.
- The system was tested progressively from idle conditions to multi-axis motion.
- The complete configuration included up to **12 servo axes**.
- Timing, EtherCAT status, and motion behavior were evaluated together rather than treating cycle time as an isolated number.

---

## Portfolio Note

The values shown here are engineering measurements from a commissioning and performance-evaluation workflow. Product-specific confidential information, internal network data, customer information, and proprietary source code are intentionally excluded from this public portfolio documentation.

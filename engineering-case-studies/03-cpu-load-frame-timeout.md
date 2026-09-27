# Case 03 — EtherCAT Communication Failure Under High CPU Load

## Context

A 12-axis EtherCAT motion system was running cyclic control with a 1 ms task. The objective was to validate system behavior under increasing CPU load while the axes were operating.

## Symptom

With an external CPU load generator active, the system remained stable at lower load levels but reproducibly failed at higher load levels. During failure, all axes stopped and multiple EtherCAT slaves dropped from OP toward SAFE-OP.

The same effect was not reproduced simply by adding computational loops inside the PLC application, which suggested that the location and scheduling behavior of the CPU load mattered.

## Evidence

Observed diagnostics included:

- EtherCAT frame receive/busy timeouts,
- mailbox retry exhaustion,
- multiple slave state regressions from OP,
- AL status code `0x001B`,
- SDO emergency/error activity,
- application task overrun messages in some runs,
- repeated failures at approximately 60%, 70%, and 80% externally generated CPU load,
- substantially better stability at lower external load.

The PLC application's own measured code execution time remained relatively small compared with the 1 ms task period, indicating that raw application-code execution time alone did not explain the failure.

## Investigation

The investigation compared several conditions:

1. Motion running without artificial CPU stress.
2. Motion running with increasing external CPU load.
3. PLC-side computational loops without the external load generator.
4. Real-time service scheduling adjustments.
5. EtherCAT state, frame timeout, mailbox, and task-runtime logs around the exact failure window.

This comparison was important because it separated **application workload** from **system-wide CPU scheduling pressure**.

## Root Cause / Engineering Conclusion

The evidence strongly indicated a real-time scheduling/resource-contention problem affecting the EtherCAT communication path under heavy external CPU load. The failure was associated with communication timing degradation rather than simply with the average execution time of the motion program.

A real-time scheduling adjustment for a synchronization service was tested, but the problem remained reproducible in later stress tests. Therefore, the scheduling change was treated as a mitigation attempt rather than incorrectly documented as a confirmed final fix.

## Resolution Strategy

The practical engineering response was to:

- establish a stable baseline,
- define reproducible CPU-load thresholds,
- capture synchronized application and EtherCAT logs,
- compare external versus PLC-generated CPU load,
- test real-time scheduling changes,
- document the remaining failure after mitigation,
- escalate with a reproducible test case and complete evidence.

## Verification

The issue was considered reproducible only when the same sequence could be observed across repeated runs:

```text
CPU pressure rises
      -> EtherCAT timing/communication errors
      -> slave state degradation
      -> motion stops
```

Longer low-load runs were also used as negative evidence to avoid claiming that every CPU-load condition produced the failure.

## Engineering Lessons

- Average PLC execution time is not sufficient to prove real-time system margin.
- System-wide CPU pressure can affect communication services and IRQ/scheduling behavior even when application code appears fast.
- External stress and application-generated stress are not automatically equivalent.
- A mitigation should not be labeled a root-cause fix unless repeated verification proves it.
- Precise time-window logging is essential for intermittent real-time communication failures.

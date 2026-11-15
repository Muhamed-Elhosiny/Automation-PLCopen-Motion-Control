# Multi-Axis EtherCAT Commissioning — Evidence-Based Release Gates

## Scope

A commissioning and validation checklist for a 12-axis EtherCAT servo test system using CiA 402 drives and a PLCopen-style motion-control interface. The documented test configuration operated in cyclic synchronous velocity (CSV, mode 9). This guide describes engineering acceptance criteria; it is **not** a claim that every gate has been passed on every controller or configuration.

## Release-gate matrix

| Gate | Required evidence | Acceptance criterion | Failure disposition |
| --- | --- | --- | --- |
| G1 — Topology and identity | Enumerated slave count, configured order, device identity and revision | Observed devices match the intended configuration; no unexpected substitution or ordering change | Hold commissioning; reconcile topology and device descriptions |
| G2 — Network state | Per-slave EtherCAT state, transition logs and diagnostic codes | All required slaves reach OP and remain there for the defined observation interval | Record the failing transition and AL code before retrying |
| G3 — Distributed Clocks | Synchronization diagnostics and transition outcomes | DC synchronization permits stable OP; no unresolved drift-related transition error | Isolate DC configuration and timing before motion enable |
| G4 — PDO and units | Process-image mapping, encoder resolution, direction and scaling read-back | Each axis has verified input/output mapping and consistent engineering units | Disable motion on affected axis; correct mapping or scaling |
| G5 — Drive mode and enable | 0x6060 command, 0x6061 mode display, statusword and controlword trace | CSV mode is confirmed by read-back; CiA 402 operation-enabled state is reached | Do not infer readiness from a successful write alone |
| G6 — Command lifecycle | Execute-edge, Busy, Done, Error and interruption observations | Each function block reports coherent lifecycle transitions without stale completion or conflicting commands | Record transition sequence and reproduce with a single axis |
| G7 — Motion direction and limits | Low-speed jog trace, feedback direction, configured motion limits | Actual motion direction and scaling agree with commanded behavior; stop behavior verified | Stop testing and correct the axis configuration |
| G8 — Timing baseline | Task cycle, EtherCAT processing time, jitter distribution and outlier context | Measurements meet **project-defined** limits under the stated workload | Do not substitute an average for worst-case timing evidence |
| G9 — Loaded stability | CPU-load scenario, task mode, frame timeout counters, slave states and stop outcome | No communication collapse or uncommanded loss of OP during the defined test | Mark failed; retain trace and avoid claiming load qualification |
| G10 — Recovery | Fault/state transition logs, reset sequence and post-recovery read-back | Recovery follows the defined safe procedure and state/mode are revalidated before motion | Keep affected axes inhibited pending diagnosis |

## Evidence record for each test

Record the controller model, firmware/software versions when shareable, axis count, task mode (event-triggered or cyclic), task period, EtherCAT cycle configuration, load generation method, duration, command profile, measured timing, state transitions, and test verdict. Keep timestamps aligned across PLC diagnostics and EtherCAT logs. Store only sanitized excerpts in public documentation.

A gate verdict should be one of **Pass**, **Fail**, **Not run**, or **Blocked**. A proposed test is never recorded as Pass. A successful state-change request is not equivalent to confirming the requested slave state; verify feedback separately.

## Findings that constrain release claims

In recorded 12-axis load testing, communication timeouts and multiple OP-to-SAFEOP transitions occurred under combined load-generation and motion workloads at approximately 60%, 70%, and 80% CPU load. A scheduling-priority mitigation did not eliminate the reproduced failure. These observations mean that **loaded-stability qualification cannot be claimed** for those conditions. The evidence supports a reproducible failure pattern, not a confirmed single root cause.

Debugger attachment also produced an isolated large cycle-time outlier in earlier measurements. Mark instrumentation events explicitly rather than merging them uncritically into steady-state timing statistics. Controller-to-controller processing-time comparisons should use equivalent task periods, workloads, and measurement boundaries.

## Engineering decision rule

Release a configuration for the **defined test scope** only when every applicable gate has recorded evidence and a Pass verdict, with no unresolved safety- or communication-critical failure. A bench-level Pass does not imply production or customer-site qualification. When a gate fails, preserve the failure evidence, isolate the variable, implement a documented correction, and rerun the affected gate plus relevant regression checks.

## Related material

- [Real-Time Motion Test Methodology](real-time-motion-test-methodology.md)
- [EtherCAT Diagnostic Playbook](ethercat-diagnostic-playbook.md)
- [PLCopen Motion Command Lifecycle Acceptance Matrix](plcopen-motion-command-lifecycle-acceptance-matrix.md)
- [Communication Failure Under High CPU Load](../engineering-case-studies/03-cpu-load-frame-timeout.md)
- [State-Change Request Versus Feedback](../engineering-case-studies/13-ethercat-state-feedback-semantics.md)

This document contains no proprietary code, internal addresses, credentials, or unpublished vendor implementation details.

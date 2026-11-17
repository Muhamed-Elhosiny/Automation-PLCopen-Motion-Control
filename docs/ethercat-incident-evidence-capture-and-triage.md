# EtherCAT Incident Evidence Capture and Triage

## Purpose

A repeatable incident record for multi-axis EtherCAT commissioning and real-time motion validation. The objective is to preserve the **first observable failure**, correlate controller and fieldbus evidence, and separate confirmed findings from hypotheses before changing configuration.

This is an engineering procedure, not a claim that every check below has been executed on a particular system.

## Capture before recovery

1. Record the controller model, firmware/runtime versions, application revision, bus topology revision, active drive operating mode, and task configuration. Exclude credentials, internal addresses, customer identifiers, and proprietary configuration exports.
2. Record the time of the **first** frame timeout or abnormal slave transition, with timezone and clock synchronization status. Preserve the original log chronology.
3. Capture master state, affected slave indices and identity metadata, each slave's actual EtherCAT state, and any available AL status code. Distinguish an individual slave failure from simultaneous transitions.
4. Capture the CiA 402 statusword and mode display for representative axes, plus controlword and command mode when permitted. An enabled drive is not proof of valid cyclic communication.
5. Record cycle period, observed execution-time distribution, missed deadlines, controller load, and whether additional load-generating applications were active.
6. Capture relevant mailbox retry, SDO abort, emergency, and distributed-clock diagnostics, with exact error codes where publishable.
7. Preserve a bounded log window **before and after** the first failure. Redact sensitive data without rewriting error codes or the order of events.

## Triage sequence

| Evidence pattern | Investigation direction | Interpretation boundary |
| --- | --- | --- |
| Repeated frame receive/busy timeouts precede multiple OP-to-SAFEOP transitions | Correlate task scheduling, communication deadlines, and competing CPU activity | Load correlation does not by itself prove a scheduler root cause |
| PREOP-to-SAFEOP fails with DC drift diagnostics | Inspect DC configuration, reference clock, sync settings, and timing | Do not equate a DC startup failure with a later runtime frame timeout |
| A slave reports an identity mismatch | Compare physical device identity with ESI/ENI expectations | Do not treat an ESI edit as proof until identity and state are read back |
| A state-setting function reports Done while actual state remains unchanged | Read back the slave's actual state and AL code | API completion and state attainment are separate outcomes |
| Motion stops but EtherCAT slaves remain OP | Check CiA 402 status, mode display, command validity, and motion interlocks | Avoid attributing every stopped axis to a fieldbus failure |

## Controlled reproduction matrix

Record each run as a separate row, with **one deliberate variable change** wherever possible.

| Field | Required record |
| --- | --- |
| Test ID / timestamp | Unique run ID and local time |
| Hardware / topology | Controller model and axis count |
| EtherCAT configuration | Cycle period, DC settings, expected slave states |
| PLC execution | Task trigger type, period, priority if known |
| Workload | Motion activity and concurrent load source |
| Observations | First fault time, frame timeouts, state transitions, AL codes |
| Outcome | Passed, failed, inconclusive, or not run |
| Recovery | Steps performed and state verified afterward |

A baseline with motion but without additional synthetic load is valuable when comparing against combined motion-plus-load conditions. A single stable run is not a general stability guarantee; define duration and repetition criteria before interpreting a pass.

## Evidence classification

- **Confirmed observation:** directly measured or logged, including exact failure order and operating conditions.
- **Reproduced correlation:** repeated association between a controlled condition and a failure; causal mechanism may remain open.
- **Hypothesis:** plausible explanation awaiting a discriminating test.
- **Mitigation:** configuration or procedural change attempted; record whether it changed the observed outcome.
- **Verified resolution:** a change followed by defined repeat tests showing the original failure no longer reproduces under the tested conditions.

## Engineering example: multi-axis communication under load

In a 12-axis EtherCAT validation setup, combined motion and additional CPU load was associated with repeated frame timeouts, mailbox retries, and several slaves leaving OP for SAFEOP. Failures were observed at several high-load operating points. A scheduling-priority adjustment was tested without eliminating the failure. The **confirmed conclusion** is reproducible communication degradation under those combined conditions; the underlying scheduling or resource-contention mechanism was **not conclusively isolated**.

This example illustrates why unsuccessful mitigations and negative-control runs belong in the incident record. It does not establish production deployment, universal load thresholds, or a validated fix.

## Release decision

Do not close an incident solely because a command returns Done, a slave briefly reaches OP, or the axes restart after a reset. Require state read-back, stable cyclic operation, repeatable motion behavior, and explicit test conditions. If the original failure remains reproducible, record the release gate as **not met**.

## Related material

- [EtherCAT diagnostic playbook](ethercat-diagnostic-playbook.md)
- [Real-time motion test methodology](real-time-motion-test-methodology.md)
- [CPU-load communication failure case](../engineering-case-studies/03-cpu-load-frame-timeout.md)
- [State-command feedback semantics case](../engineering-case-studies/13-ethercat-state-feedback-semantics.md)

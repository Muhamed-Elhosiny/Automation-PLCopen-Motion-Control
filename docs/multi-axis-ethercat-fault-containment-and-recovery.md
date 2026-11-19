# Multi-Axis EtherCAT Fault Containment and Recovery

## Engineering context

A 12-axis EtherCAT servo test system operating in cyclic synchronous velocity (CSV, CiA 402 mode 9) experienced communication loss during combined motion and synthetic CPU-load tests. Frame receive/busy timeouts preceded mailbox retries, multiple slaves leaving OP for SAFEOP, and loss of coordinated axis motion. The observations establish a reproducible **system-level failure mode**, not a proven scheduler, network, or drive root cause.

This document defines a **proposed recovery and validation protocol** for an engineering test system. It is not evidence that automatic recovery has been implemented, validated, or approved for machine operation.

## Fault boundaries and response priorities

1. **Safety functions remain independent.** Emergency stop, safe torque off, guards, and any required mechanical braking must be designed and validated through the applicable machine-safety process. EtherCAT state or PLC logic alone must not be treated as a safety function.
2. **Treat loss of communication as loss of command authority.** Do not infer that a last transmitted velocity command is zero or that an axis has stopped; obtain independent safe-state evidence where required.
3. **Inhibit new motion requests globally.** Latch a system fault when a required axis leaves OP, valid cyclic feedback is lost, or the application detects an unacceptable communication timeout.
4. **Record the first failure before reset.** Capture monotonic timestamps, task period, CPU load, master/slave states, AL status, frame and mailbox errors, and relevant drive statuswords without publishing confidential identifiers.
5. **Do not automatically re-enable drives.** Require a controlled recovery decision after verifying topology, communication stability, drive faults, and safe mechanical conditions.

## Proposed state model

| System state | Entry condition | Permitted actions | Exit gate |
| --- | --- | --- | --- |
| READY | All required slaves OP; feedback fresh; drives in expected mode; safety prerequisites satisfied | Accept explicitly authorized motion commands | Any fault moves to FAULT_LATCHED |
| FAULT_LATCHED | Loss of OP, feedback freshness, or communication integrity | Inhibit commands; preserve evidence; initiate independently engineered safe response | Operator/commissioning acknowledgment |
| DIAGNOSE | Motion inhibited; evidence retained | Inspect master logs, slave AL codes, DC status, topology, and drive faults | Fault source understood sufficiently to justify a recovery attempt |
| REINITIALIZE | Authorized recovery; physical conditions verified | Restore communication and drive configuration in a controlled order | Required slaves OP and stable; mode and feedback read back |
| REQUALIFY | Communications restored; no automatic motion | Verify statusword, actual velocity/position, mode display, command zeroing, and observation window | Explicit authorization for READY |

State names are illustrative architectural requirements, not existing PLC function-block identifiers.

## Commissioning acceptance checks

| Check | Evidence required | Pass criterion |
| --- | --- | --- |
| Loss-of-OP detection | Timestamped master state and application fault transition | Global motion inhibit asserted on the specified fault condition |
| Stale feedback | Sequence/timestamp trace across cyclic task and process image | Stale feedback cannot satisfy motion-ready gates |
| Command reset | Logged command outputs before and after recovery | No retained nonzero motion demand is applied on re-enable |
| Mode read-back | Requested 0x6060 and displayed 0x6061 | Expected mode 9 confirmed for each required axis |
| CiA 402 enable | Statusword and controlword trace | Explicit controlled state progression; no unintended restart |
| Fault persistence | Logs retained across reset sequence | Original failure evidence remains available |
| Load regression | Repeated combined motion/load trials at relevant task periods | No unexplained OP-to-SAFEOP transition during the defined acceptance window |

Record actual results as PASS, FAIL, or NOT TESTED; do not treat this checklist as completed verification.

## Evidence from the test campaign

- Observed: communication frame timeouts and mailbox retries occurred before multiple slaves transitioned from OP to SAFEOP; the 12 axes stopped.
- Observed: the failure was reproducible under several combined CPU-load and motion conditions, including nominal 60%, 70%, and 80% load trials.
- Observed: a scheduling-priority mitigation was tried without eliminating the failure.
- Not established: a definitive root cause, a validated safe stopping time, or a successful automated restart sequence.

## Engineering judgment

Recovery should be designed as a **separate, gated operation**, not an implicit consequence of a master reconnect or a cleared fault bit. A returned OP state alone is insufficient: PDO freshness, CiA 402 status, operating-mode read-back, motion-command clearing, and independent safety prerequisites must also be checked.

## Validation status

**Protocol proposed; implementation and acceptance testing not claimed.** The underlying communication-failure observations were obtained on the engineering test system. Any deployment requires machine-specific hazard analysis, acceptance criteria, and documented test evidence.

## Related material

- [EtherCAT incident evidence capture and triage](ethercat-incident-evidence-capture-and-triage.md)
- [Real-time controller performance comparison](real-time-controller-performance-comparison.md)
- [CPU-load communication failure case study](../engineering-case-studies/03-cpu-load-frame-timeout.md)

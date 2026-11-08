# Parameterized Multi-Axis Motion Architecture — Integration Contract

## Engineering Scope

A reusable PLCopen-style motion-control implementation was developed around a shared axis reference and per-axis function-block instances. The test configuration expanded from five to twelve servo axes over EtherCAT. This document captures an integration contract for scaling the architecture without copying axis-specific logic. It is an architecture note, not a claim of production qualification.

## Architecture Boundary

- **Axis reference:** `AXIS_REF_BACHMANN` carries the exchange between PLC logic and the axis-management layer (`AxisManagerToPlc` and `PlcToAxisManager`).
- **Process-image adapter:** `FB_M100_ProcessImageAccess` maps the cyclic EtherCAT process image to per-axis PDO data. Keep bus mapping separate from motion-command decisions.
- **Motion function blocks:** `MC_Power`, `MC_Reset`, `MC_Stop`, `MC_Home`, `MC_MoveVelocity`, `MC_MoveAbsolute`, `MC_MoveRelative`, and `MC_MoveContinuousAbsolute` operate through the axis abstraction.
- **Drive state control:** CiA 402 statusword and controlword handling governs enabling and motion-state transitions. The operating-mode command and mode display must be checked separately.
- **Trajectory layer:** Profile parameters (velocity, acceleration, deceleration, jerk and cycle time where applicable) are explicit inputs rather than implicit defaults.

## Per-Axis Configuration Contract

Each additional axis requires a new axis instance and verified parameters; the shared function-block implementation should remain unchanged.

| Parameter / interface | Integration requirement | Verification evidence |
| --- | --- | --- |
| EtherCAT slave and PDO binding | Map the intended physical axis to its input/output process data | Topology and process-image cross-check |
| Encoder resolution and engineering-unit scaling | Configure counts-to-units conversion consistently for position and velocity | Controlled travel and feedback comparison |
| Operating mode | Request the selected CiA 402 mode and check the reported mode | `0x6060` command vs. `0x6061` display |
| Motion limits | Set valid velocity, acceleration, deceleration and jerk parameters | Accepted command and measured response |
| Statusword interpretation | Evaluate enable, fault, target-reached and homing-related conditions | Recorded status transitions |
| Command lifecycle | Handle Execute edges and mutually exclusive axis commands | Busy/Done/Error/CommandAborted sequence |

## Integration Sequence

1. Identify the physical slave and verify topology before binding an axis instance.
2. Verify PDO directions, data types and scaling; do not assume identical encoder resolution across drives.
3. Validate the CiA 402 enable sequence and mode feedback with motion inhibited.
4. Commission one axis at conservative motion limits and record position/velocity feedback.
5. Add axes one at a time using instances and configuration only; check for swapped bindings and unintended simultaneous commands.
6. Repeat cyclic-load and stop/fault-recovery checks at the intended task period. Successful single-axis motion does not establish twelve-axis real-time stability.

## Observed Implementation vs. Acceptance Criteria

**Observed engineering implementation:** A shared PLC motion abstraction and process-image mapping were implemented, and a twelve-axis EtherCAT test stand was exercised. A velocity-command rejection was previously addressed by supplying valid trajectory parameters. Heavy-load tests also exposed EtherCAT communication failures in some combined-load scenarios.

**Acceptance criteria requiring explicit evidence per configuration:** Correct axis-to-slave mapping, calibrated scaling, safe enable/disable behavior, command arbitration, repeatable stop/fault recovery, and timing stability under concurrent load. No claim is made that all criteria have been passed for every axis or CPU.

## Engineering Judgment

Parameterization reduces duplicated logic, but it does not remove commissioning risk. The critical boundary is between reusable motion behavior and axis-specific physical facts: PDO assignment, feedback scaling, limits and drive capabilities. A new axis is an instance-and-parameter change **only after** those facts are independently verified.

## Related Engineering Records

See `engineering-case-studies/08-multi-axis-scaling-mismatch.md`, `engineering-case-studies/11-csv-invalid-trajectory-parameters.md`, and `engineering-case-studies/03-cpu-load-frame-timeout.md` for supporting troubleshooting context.

## Publication Boundary

No proprietary code, internal addresses, customer information, or unpublished vendor implementation details are included.

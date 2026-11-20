# Multi-Axis Motion Interface and Parameterization

## Engineering scope

A PLC motion-control implementation was structured around reusable function blocks and a per-axis reference interface for an EtherCAT servo test system expanded from five to twelve axes. The architectural objective was to add an axis through another instance and axis-specific parameters, rather than duplicating motion logic.

This document records the interface boundaries and the engineering checks needed to scale the implementation. It does not claim a production deployment or certify functional safety.

## Architecture and responsibility boundaries

| Layer | Responsibility | Key contract |
| --- | --- | --- |
| EtherCAT process image | Exchange cyclic input/output PDO values | Read actual feedback and write command values using the configured mapping |
| Process-image adapter | Map task process-image fields into axis PDO structures | Keep direction, data types, and update cadence explicit |
| Axis reference | Exchange axis state and requests between PLC and axis-management logic | Separate `AxisManagerToPlc` feedback from `PlcToAxisManager` commands |
| CiA 402 control | Sequence drive state and operating mode | Gate motion on statusword feedback and verified mode display |
| Motion function blocks | Interpret application commands and generate motion requests | Preserve Execute-edge, Busy, Done, Error, and command-arbitration semantics |
| Profile generation | Calculate trajectory-related setpoints | Use the actual configured cycle time and validated limits |

The implementation includes motion blocks for power, reset, stop, homing, absolute/relative positioning, continuous absolute movement, and velocity motion. The names describe functional scope, not a claim of conformance testing against every PLCopen edge case.

## Per-axis configuration contract

Each axis instance should have a documented, independently reviewed configuration record:

- EtherCAT device identity, PDO mapping, and expected operating mode
- Encoder resolution and position/velocity unit conversion
- Sign conventions and direction of travel
- Velocity, acceleration, deceleration, and jerk limits
- Task period and profile-generator cycle time
- Homing method and reference validity
- Permissible state transitions and stop behavior

Never assume identical encoder scaling or mechanics simply because two drives share a type. A configuration change should be reviewed independently of the shared function-block implementation.

## Command and feedback lifecycle

1. Capture a new motion request on its defined Execute edge.
2. Check axis enable state, fault status, mode display, and parameter validity.
3. Accept or reject the request deterministically; avoid issuing conflicting commands to one axis.
4. While motion is active, use live feedback to distinguish an accepted request from completed physical motion.
5. Assert completion only when the relevant command conditions and target-reached feedback are satisfied; reset completion according to the function-block interface contract.
6. On stop, fault, or communication loss, suppress stale commands and require an explicit recovery path before further movement.

The target-reached gate is particularly important: command dispatch and motion completion are not equivalent events.

## Commissioning and regression checks

| Check | Evidence to capture | Acceptance principle |
| --- | --- | --- |
| New axis instance | Instance configuration and mapped PDO channels | No changes required to existing axis algorithms |
| Axis scaling | Commanded versus reported position/velocity | Correct magnitude and sign for each axis |
| Enable sequence | Controlword/statusword transition trace | Operation-enabled state confirmed before motion |
| Mode selection | Requested mode and mode display | Motion issued only after mode confirmation |
| Motion lifecycle | Execute, Busy, Done, Error, TargetReached trace | No premature completion or duplicate triggering |
| Cycle-time alignment | Task and profile periods | No unreviewed period mismatch |
| Multi-axis isolation | Per-axis faults and commands | A command or fault on one axis does not unintentionally drive another |

These are acceptance criteria to apply, not a statement that all tests have already passed.

## Observed engineering lessons

During implementation, an initially rejected velocity command was corrected by supplying valid acceleration, deceleration, and jerk parameters. Completion handling also required explicit target-reached gating, and the motion-profile cycle-time setting was adjusted during vibration investigation. These observations demonstrate why per-axis configuration and command-state contracts must be tested together.

## Boundaries

The available project record supports the described architecture, twelve-axis test setup, function-block scope, and the cited debugging observations. It does not establish production qualification, validated safety functions, or complete regression coverage. Proprietary source, internal addresses, and confidential vendor implementation details are intentionally excluded.

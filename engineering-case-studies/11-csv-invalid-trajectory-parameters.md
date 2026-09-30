# Case 11 — Cyclic Velocity Command Rejected by Invalid Trajectory Parameters

## Context

A servo axis was being commissioned for cyclic velocity operation through an EtherCAT/CiA 402 motion-control application. Communication, drive state handling, and the requested operating mode were already available, but the first motion command still failed.

## Symptom

On the first execution of the velocity command, the drive entered a fault instead of accelerating the motor. The diagnostic message indicated an invalid velocity value or invalid trajectory-generator input.

This initially looked like a velocity-command problem because the fault appeared exactly when motion was requested.

## Evidence

The investigation established several useful facts:

- EtherCAT communication was active.
- The axis could progress through the drive-enable sequence.
- The intended velocity operating mode could be selected.
- The fault appeared specifically when the motion command was executed.
- The motion profile parameters had not all been initialized before the first execute request.
- After valid acceleration, deceleration, and jerk limits were assigned and the drive was reset, the same motion path operated correctly.

## Investigation

The debugging sequence deliberately moved outward from the reported velocity error instead of assuming the target velocity itself was invalid.

1. Confirm the EtherCAT slave remained reachable.
2. Confirm the CiA 402 state before motion execution.
3. Confirm the requested operating mode and active-mode feedback.
4. Inspect the target velocity value and its scaling.
5. Inspect every parameter consumed by the trajectory generator.
6. Initialize acceleration, deceleration, and jerk limits explicitly.
7. Reset the drive fault and repeat the same command.

The key observation was that a trajectory generator evaluates a complete motion profile. A numerically valid target velocity does not guarantee that the overall trajectory input set is valid.

## Root Cause

The motion command was executed before all required trajectory/profile parameters had been initialized to valid values. The resulting invalid profile input caused the drive-side trajectory generator to reject the command and enter a fault state.

## Resolution

The startup and command sequence was changed so that profile parameters are initialized before the execute edge is permitted:

```text
Initialize motion limits
    - acceleration
    - deceleration
    - jerk
          |
          v
Validate command inputs
          |
          v
Confirm drive ready + operating mode
          |
          v
Execute velocity command
```

After correcting the parameters, the existing fault was cleared through the normal reset path before motion was attempted again.

## Verification

The correction was verified by repeating the original motion command after initialization. The axis accelerated and rotated without reproducing the trajectory-generator fault.

The verification also checked that the parameters were assigned before every first execution after application startup, rather than relying on values left over from an earlier online session.

## Engineering Lessons

- A drive error mentioning velocity does not necessarily mean the target velocity is the defective input.
- Motion commands should validate the complete parameter set consumed by the trajectory generator.
- Acceleration, deceleration, jerk, scaling, limits, and operating mode are part of the command preconditions, not optional tuning details.
- First-cycle commissioning faults often expose uninitialized application state that may remain hidden during later online tests.
- A robust motion function block should prevent `Execute` from reaching the drive until required parameters pass validation.

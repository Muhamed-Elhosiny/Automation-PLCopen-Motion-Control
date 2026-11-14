# PLCopen Motion Command Lifecycle — Acceptance Matrix

## Scope
Engineering verification plan for a multi-axis PLC motion implementation using PLCopen-style function blocks and a CiA 402 EtherCAT drive interface. The implementation includes power, reset, stop, homing, velocity, absolute/relative positioning, and continuous-position commands. This document defines **proposed acceptance checks**, not a claim that every check has passed.

## Interface and state contract
- **Execute edge:** capture a new motion request on a rising edge; document whether the block permits re-triggering while active.
- **Busy / Done / Error:** make completion and failure mutually interpretable; a command acknowledgement must not be confused with drive-level completion.
- **Command arbitration:** define which block owns the axis command at each instant; prevent simultaneous writers from silently overriding controlword or target PDOs.
- **Power prerequisite:** verify CiA 402 state and operation-enabled feedback before accepting a motion command.
- **Unit conversion:** explicitly specify encoder resolution, position units, velocity units, and acceleration/deceleration scaling per axis.
- **Safe interruption:** Stop and fault transitions must inhibit new motion and require an explicit, verified re-arm path.

## Acceptance matrix

| ID | Stimulus | Expected observable result | Evidence to capture |
| --- | --- | --- | --- |
| LC-01 | Hold Execute TRUE for multiple scans | One command initiation, no unintended restart | Execute, Busy, command counter, target PDO |
| LC-02 | Pulse Execute while drive not operation-enabled | Defined rejection or queued behavior; never implicit unsafe motion | Statusword, Error/ErrorID, command state |
| LC-03 | Start velocity motion with valid Acc/Dec/Jerk | Valid command reaches drive and observed motion follows commanded direction | Target/actual velocity, statusword |
| LC-04 | Request zero or invalid trajectory parameters | Deterministic validation outcome, no stale command reuse | Inputs, Error/ErrorID, target PDO |
| LC-05 | Issue Stop during active velocity motion | Controlled deceleration and motion inhibition according to specified stop semantics | Target/actual velocity, Stop state |
| LC-06 | Re-arm after Stop | No spontaneous restart from a previously held Execute; explicit new request required | Execute edges, command owner, target PDO |
| LC-07 | Issue a new absolute/relative move after TargetReached | One new target accepted with correct unit conversion | Target position, actual position, statusword |
| LC-08 | Trigger drive fault during active command | Motion block reports failure and relinquishes command ownership | Fault bit, Error/ErrorID, controlword |
| LC-09 | Reset fault and re-enable | Drive state verified before a new command; Reset completion alone does not imply motion readiness | Statusword progression, Reset outputs |
| LC-10 | Repeat command on multiple configured axes | Independent axis references and scaling; no cross-axis PDO writes | Per-axis target/actual PDO trace |

## Test execution
1. Record firmware, EtherCAT cycle, PLC task cycle, axis mapping, and motion-block revision before each run.
2. Capture timestamped PLC command inputs/outputs alongside CiA 402 statusword, controlword, operation mode, target and actual values.
3. Run each test from a documented initial state; reset latches and capture both passing and failing traces.
4. Repeat under nominal load before introducing additional CPU load. Keep communication-stability testing separate from motion-semantic acceptance.
5. Mark each row **Pass**, **Fail**, or **Not executed** only after reviewing the recorded trace. Never infer pass from an FB's Done flag alone.

## Evidence boundary
Earlier engineering work identified invalid velocity inputs resolved by supplying acceleration/deceleration/jerk, Execute-edge handling refinements, and TargetReached gating improvements. Those observations motivate this matrix; they do **not** establish that all lifecycle tests have been executed or passed.

## Engineering judgment
A reusable multi-axis motion interface needs an explicit command lifecycle contract as much as correct trajectory calculations. Separate command acceptance, drive state, physical motion, and verified completion so faults remain diagnosable and future axes can be commissioned by parameterization rather than control-flow changes.

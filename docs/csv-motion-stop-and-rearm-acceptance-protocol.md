# Cyclic Synchronous Velocity: Stop and Re-Arm Acceptance Protocol

## Scope and engineering basis

This protocol defines evidence requirements for stopping and restarting a CiA 402 axis commanded in Cyclic Synchronous Velocity (CSV, mode 9) through a PLCopen-style motion interface. The motion-control implementation includes `MC_Power`, `MC_Stop`, `MC_MoveVelocity`, axis-reference command/status exchange, and EtherCAT process-image mapping. The checks below are **proposed acceptance tests**, not a claim that all tests have passed.

## Control boundaries

- **Application:** motion-command ownership, Execute edge handling, Stop latch, requested velocity, and re-arm decision.
- **CiA 402 drive:** statusword, operation-enabled indication, actual velocity, and fault state.
- **EtherCAT transport:** cyclic output freshness and communication state. A PLC function block reporting completion does not by itself prove a drive-state transition.
- **Safety:** application Stop is not a substitute for a safety-rated stop or STO. Test in a guarded setup with appropriate limits and independent emergency-stop provisions.

## Required evidence

Capture synchronized timestamps or cycle indices for: `MC_MoveVelocity.Execute`, `MC_Stop.Execute`, `MC_Stop.Busy/Done/Error`, target velocity, actual velocity, drive statusword, operating-mode display, EtherCAT slave state, and any motion-command arbitration state. Record task period and configured deceleration. Where stopping distance matters, also record actual position.

## Acceptance matrix

| ID | Test condition | Required observation |
| --- | --- | --- |
| SV-01 | Stable positive velocity, then Stop rising edge | Stop takes ownership; velocity command follows the defined deceleration path; no competing move command overrides it. |
| SV-02 | Stable negative velocity, then Stop | Equivalent stopping behavior in the reverse direction; no sign-dependent bypass. |
| SV-03 | MoveVelocity Execute held high while Stop is active | No implicit restart while Stop retains ownership. |
| SV-04 | New MoveVelocity edge while Stop is active | Command is rejected, deferred, or explicitly blocked according to documented arbitration rules; never silently applied. |
| SV-05 | Stop remains asserted after actual velocity reaches zero | Zero-velocity state remains controlled; a stale move request cannot restart the axis. |
| SV-06 | Stop released after a complete stop | Restart requires a fresh, eligible command edge and valid drive/communication state. |
| SV-07 | Stop during acceleration | Transition to the stop profile remains bounded by configured limits; no intermediate command spike. |
| SV-08 | EtherCAT communication loss during stop | Mark result as a transport fault; do not treat `Done` or a frozen actual-velocity sample as proof of a completed stop. |
| SV-09 | Drive fault during stop | Fault handling takes precedence; restarting requires explicit recovery and a fresh command. |

## Procedure

1. Verify drive operating mode 9, scaling, velocity sign, task period, and process-image ownership before motion.
2. Establish a repeatable, low-risk speed and record a baseline of target and actual velocity.
3. Execute each matrix condition separately. Preserve raw traces and note configuration and firmware identifiers when publishable.
4. Check command ownership cycle by cycle: a Stop request must prevent competing motion FBs from writing an effective nonzero target.
5. Evaluate stop completion against **actual motion evidence** and drive feedback, not just FB outputs. Define a velocity tolerance and stable-sample count before testing; avoid claiming an exact-zero encoder value.
6. Re-arm with a fresh Execute edge only after Stop is released and all enable/communication prerequisites are satisfied.
7. Record pass/fail, deviations, trace references, and any untested conditions.

## Interpretation and limits

A completed `MC_Stop` handshake, a zero target-velocity value, and a stationary axis are three different observations. They should be correlated, not substituted for one another. A successful stop under nominal operation does not establish safe behavior under network loss or drive faults. Acceptance criteria for stop time and distance must be derived from the specific mechanical setup; no universal limit is asserted here.

## Engineering outcome

This protocol makes stop-command priority, stale-command suppression, and explicit re-arm behavior independently verifiable. It complements fault-recovery testing by focusing on **nominal CSV stop arbitration and restart semantics** rather than presenting unexecuted tests as measured results.

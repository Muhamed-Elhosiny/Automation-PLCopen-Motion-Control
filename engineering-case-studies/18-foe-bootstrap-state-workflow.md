# FoE Bootstrap State-Control Workflow and Operator Diagnostics

## Context

A File over EtherCAT (FoE) commissioning workflow required the EtherCAT slave to enter BOOTSTRAP (BOOT) for a file-transfer operation. The engineering interface exposed normal state controls but did not offer BOOT as a selectable target.

## Symptom

The intended transfer preparation could not be completed solely through the normal state-selection interface. Attempting to reach BOOT directly from OP was not a valid transition for the tested workflow.

## Evidence

- BOOT was not exposed among the selectable states in the tested user interface.
- The tested procedure required the slave to be placed in INIT before requesting BOOT.
- A controller-side command-line path was available to request the transition.
- The interface did not guide the operator through the prerequisite transition.

These observations describe the tested integration, not a universal limitation of every EtherCAT master or device.

## Investigation

The commissioning sequence was separated into (1) slave state preparation, (2) FoE file transfer, and (3) post-transfer recovery. The diagnostic focus was on actual slave state, legal transitions, and transfer preconditions rather than treating an unavailable BOOT control as a file-transfer failure.

The expected operational sequence was:

`Current state → INIT → BOOT → FoE transfer → application-appropriate recovery`

Any transition should be confirmed by reading the actual slave state before the next step. Recovery to a previous state is conditional on device behavior and the transfer outcome; it should not be assumed to be universally automatic or safe.

## Root Cause or Engineering Conclusion

**Confirmed interface limitation in the tested setup:** the state-control UI did not expose BOOT, even though the FoE workflow needed a BOOT transition.

**Engineering conclusion:** state preparation and file transfer were insufficiently integrated in the operator workflow. This is an interface/workflow gap; it is not evidence of a FoE protocol defect.

No claim is made that the underlying master's state machine was defective.

## Resolution

The tested operational workaround was to use the controller-side state-control path, placing the slave in INIT before requesting BOOT.

A proposed interface improvement is to expose BOOT with explicit transition prerequisites, actual-state confirmation, and actionable failure diagnostics. A guided FoE workflow could perform the sequence with operator visibility, timeouts, and controlled recovery.

These interface improvements are recommendations, not implemented changes.

## Verification

The available observations support the state-transition prerequisite and the missing UI control. A complete end-to-end automated UI workflow was **not** implemented or verified.

A future acceptance test should record actual state after each request, transfer completion/error status, bytes transferred, and final slave state. It should also exercise invalid starting states, transfer failure, and recovery behavior.

## Engineering Lessons

- Model FoE commissioning as a state-dependent workflow, not a standalone file operation.
- Separate a missing UI affordance from a failure in the underlying EtherCAT state machine.
- Confirm actual state after each asynchronous transition; command completion alone is insufficient.
- Explain invalid transitions before issuing them, and provide diagnostics when a prerequisite fails.
- Distinguish a validated command-line workaround from an unimplemented operator-interface improvement.

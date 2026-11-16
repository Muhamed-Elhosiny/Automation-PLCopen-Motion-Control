# Case 22 — Motion Command Completion Gated by Target-Reached Feedback

## Context
A PLCopen-style motion layer coordinated velocity and position commands across CiA 402 EtherCAT servo axes. The application tracked function-block command state separately from cyclic drive feedback.

## Symptom
During implementation and commissioning, command completion and subsequent command acceptance required refinement around the drive's `TargetReached` indication. Execute-edge handling also needed improvement to prevent ambiguous command lifecycle behavior.

## Evidence
- The implementation used a CiA 402 statusword and application-side motion function blocks.
- Engineering revisions explicitly improved `TargetReached` gating and rising-edge handling of `Execute`.
- The recorded engineering history does not contain a complete before/after trace proving a particular statusword timing sequence or an exact number of unintended retriggers.

## Investigation
The investigation focused on separating three events that are easy to conflate:
1. An `Execute` rising edge requests a command.
2. The command is accepted and remains active while drive feedback evolves.
3. The requested terminal condition is observed and the block reports completion.

For position moves, the terminal condition should be evaluated against the relevant CiA 402 feedback and application tolerances, not merely the scan in which the target was written. A persistent `Execute=TRUE` must not be interpreted as repeated new requests. Feedback that predates the current command must not be mistaken for completion of that command.

## Root Cause or Engineering Conclusion
**Confirmed engineering conclusion:** command acceptance, command execution, and confirmed completion require distinct state transitions. The implementation was refined to gate completion on target-reached feedback and to handle `Execute` edges explicitly.

**Not established:** a unique low-level root cause, such as stale PDO sampling, a specific drive firmware behavior, or an exact race between PLC and EtherCAT cycles. Those explanations would require synchronized traces and must remain hypotheses.

## Resolution
The motion-block logic was revised to handle `Execute` as a request edge and to incorporate `TargetReached` into the completion path. The command lifecycle should maintain a clear active-command state and avoid using an old completion indication as proof of a new move.

No proprietary function-block implementation or vendor-specific internals are reproduced here.

## Verification
The historical record confirms that the logic was improved; it does **not** establish a fully executed regression suite for all axes and operating conditions.

Recommended regression evidence:
- Hold `Execute` high over multiple scans and verify a single initiation.
- Issue two successive position moves and confirm the second cannot finish from the previous move's terminal indication.
- Capture `Execute`, `Busy`, `Done`, target and actual position, statusword, and command ownership on a common timeline.
- Interrupt a move with Stop or a drive fault and confirm no false `Done` or automatic restart.
- Repeat on independent axes to exclude shared-state and PDO-mapping interference.

## Engineering Lessons
- PLCopen-style `Done` semantics should represent the specified command terminal condition, not just successful output writing.
- Rising-edge detection and completion feedback are separate requirements.
- Statusword bits must be interpreted in the context of the current command and drive mode.
- Preserve evidence boundaries: an implementation correction is not proof that every proposed acceptance test passed.
- A traceable command lifecycle makes multi-axis commissioning and future regression testing substantially more reliable.

## Related Engineering Documentation
- [PLCopen Motion Command Lifecycle — Acceptance Matrix](../docs/plcopen-motion-command-lifecycle-acceptance-matrix.md)
- [Case 11 — Invalid Trajectory Parameters](11-csv-invalid-trajectory-parameters.md)

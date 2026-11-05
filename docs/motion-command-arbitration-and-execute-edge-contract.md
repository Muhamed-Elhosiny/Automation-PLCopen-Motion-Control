# Motion Command Arbitration and Execute-Edge Contract

## Engineering Context

A PLCopen-style motion-control interface was implemented around an EtherCAT CiA 402 drive integration. The implementation included power, reset, stop, homing, velocity, absolute, relative, and continuous-position commands. Drive control was coordinated with statusword feedback and cyclic process-image exchange.

This note records an architectural contract derived from implementation and debugging work. It is a **design and verification guideline**, not a claim that every scenario below has been validated on hardware.

## Integration Risk

Multiple motion function blocks can request control of the same axis. Without an explicit ownership policy, a level-held `Execute` input or a second command can repeatedly initialize a trajectory, overwrite a target, or compete with an active stop or homing sequence. A drive reporting *Operation Enabled* does not by itself establish that a particular motion request has been accepted or completed.

## Command Ownership

Use one axis-level coordinator to arbitrate requests and write the final drive-facing command outputs.

| Priority | Request | Required behavior |
| --- | --- | --- |
| 1 | Fault / disable | Inhibit motion requests; follow the drive's documented fault and shutdown behavior. |
| 2 | Stop | Supersede normal motion requests; maintain the stop contract until its completion condition is met. |
| 3 | Homing | Require an eligible drive state; prevent conflicting position or velocity commands while active. |
| 4 | Position / velocity | Admit one motion command at a time, subject to an explicit replacement or abort policy. |

Priority order is a proposed coordination rule; it must be checked against the selected PLCopen interface contract and drive behavior. A safety-rated stop must not be represented as equivalent to a software motion stop.

## Execute-Edge Contract

1. Detect a rising edge of `Execute` at the function-block boundary.
2. On admission, latch the target, direction, velocity, acceleration, deceleration, and other relevant parameters.
3. Keep the command active independently of whether `Execute` remains high, according to the selected FB contract.
4. Reject or explicitly arbitrate new commands while an incompatible command owns the axis.
5. Report `Busy`, `Done`, `Error`, and `CommandAborted` from the FB's defined lifecycle, not from a single raw statusword bit.
6. Require a fresh edge for a new request; do not retrigger motion every PLC scan while `Execute` stays high.

These rules describe a robust interface pattern; exact output reset timing and buffering behavior depend on the chosen PLCopen semantics.

## Drive Feedback and Completion

The coordinator must distinguish:
- **Request admission:** the FB accepted a new command.
- **Drive readiness:** the CiA 402 state indicates operation is enabled.
- **Motion progress:** actual position/velocity and relevant statusword feedback reflect execution.
- **Completion:** the command-specific end condition is met, with any required tolerance, standstill, or target-reached gating.

The generic CiA 402 `Target reached` indication must not be interpreted as universal proof that a newly issued command completed. Evaluate it in the context of the selected operation mode and the command's transition history.

## Validation Matrix

| Test | Stimulus | Expected observable result |
| --- | --- | --- |
| Held execute | Keep `Execute=TRUE` for multiple scans | One admission; no repeated target initialization. |
| New edge | Deassert then assert `Execute` | One new request when the axis is eligible. |
| Conflicting commands | Request velocity and absolute move concurrently | Deterministic ownership or explicit rejection. |
| Stop during motion | Assert stop while a move is active | Normal motion command relinquishes ownership; stop status is reported consistently. |
| Drive fault | Inject or observe a drive fault during motion | Motion command exits its active lifecycle with appropriate diagnostic feedback. |
| Premature target-reached | Observe a stale target-reached bit at admission | No immediate false `Done` for the new move. |
| Parameter change mid-move | Change target while `Execute` remains high | Latched command parameters remain stable unless an explicit update policy exists. |

Record the PLC task period, operation mode, statusword/controlword traces, actual values, and FB output transitions for each test. This table specifies **tests to perform**, not previously verified pass results.

## Engineering Conclusion

An axis-level ownership model and explicit execute-edge semantics make motion behavior deterministic and simplify fault diagnosis. During earlier implementation work, execute-edge handling and target-reached gating required refinement; the broader arbitration and regression matrix above is an engineering recommendation rather than an independently demonstrated resolution.

## Engineering Lessons

- Separate function-block request state from CiA 402 drive state.
- Make command replacement, stop precedence, and parameter latching explicit.
- Gate completion on command-specific evidence, not a stale status indication.
- Verify behavior across multiple PLC scans and during interrupted motion.
- Keep safety functions separate from standard motion-control logic.

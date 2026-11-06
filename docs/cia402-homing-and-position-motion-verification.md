# CiA 402 Homing and Position-Motion Verification Protocol

## Scope

This engineering verification protocol covers the transition from an enabled CiA 402 axis to a reproducible reference position and subsequently to commanded position moves. It is intended for a multi-axis EtherCAT test system with PLCopen-style motion function blocks. It describes **acceptance criteria and proposed tests**, not a claim that every test below has been executed.

## Control and Feedback Boundaries

A successful EtherCAT OP state does not prove that a drive is ready to move. Verify each layer independently:

1. **Communication:** EtherCAT slave in OP; expected PDO layout and valid cyclic feedback.
2. **Drive state:** CiA 402 statusword indicates Operation Enabled, with no active fault.
3. **Operating mode:** requested mode (0x6060) and displayed mode (0x6061) agree; do not infer the mode from the command alone.
4. **Reference validity:** the application knows whether the axis has a valid home/reference position. A previously stored software flag is not sufficient after a power cycle unless its retention and revalidation semantics are defined.
5. **Motion execution:** feedback position and velocity evolve consistently with the requested trajectory, and the completion condition belongs to the active command.

## Homing Verification

| Test | Stimulus | Evidence to record | Acceptance criterion |
| --- | --- | --- | --- |
| H01 | Request homing with drive enabled and supported homing mode selected | 0x6060/0x6061, statusword, actual position, homing FB outputs | Homing starts only after mode/state prerequisites are satisfied |
| H02 | Complete a normal reference run | Homing status indications, final position, FB Done/Busy/Error | Completion is confirmed by drive feedback and application reference validity |
| H03 | Attempt an absolute move before valid homing | Motion request, application interlock, drive response | Request is rejected or deliberately handled according to documented axis policy |
| H04 | Trigger stop or fault during homing in a controlled safe setup | Statusword, stop/fault transition, reference-valid flag | No false Done or retained reference-valid indication after an invalidating event |
| H05 | Restart the controller or drive | Retained state, drive feedback, position reference | Reference validity is restored only if the configured system can substantiate it |

**Safety boundary:** Homing direction, switch polarity, travel limits, mechanical clearance, and stop behavior must be checked before enabling motion. Fault injection must not rely on deliberately unsafe mechanical travel.

## Position-Motion Verification

| Test | Stimulus | Evidence to record | Acceptance criterion |
| --- | --- | --- | --- |
| P01 | Execute one absolute move from a known reference | Start/target/actual position, FB state, statusword | One rising edge starts one command; completion corresponds to the active target |
| P02 | Execute a relative move | Position before/after, requested displacement | Actual displacement is consistent with the requested engineering units and configured scaling |
| P03 | Issue repeated scans with Execute held TRUE | FB states and target changes | No unintended retrigger without a documented new-command condition |
| P04 | Request a second motion while one is active | Command ownership, Busy/Done/CommandAborted, feedback | Arbitration and interruption behavior match the documented FB contract |
| P05 | Apply a controlled stop during motion | Deceleration trace, final velocity, FB outputs | Axis reaches the defined stopped state without reporting the interrupted target as completed |
| P06 | Command an invalid or out-of-range target | Error output, drive diagnostic, actual motion | Invalid request is rejected before hazardous motion; error is actionable |

## Trace and Evidence Package

For each test capture the axis identifier, drive firmware/configuration revision, PDO mapping revision, task cycle, operating mode, encoder resolution, engineering-unit scaling, command parameters, timestamps, FB output transitions, statusword, actual position/velocity, and result. Use anonymized identifiers and exclude internal network details.

Record **command accepted**, **motion observed**, **target reached**, and **FB Done** as separate observations. A target-reached statusword bit may require command-context and transition checks; it must not be treated as proof that a newly issued command completed merely because the bit was already set.

## Engineering Conclusions and Limits

The commissioning experience underlying this portfolio established the importance of CiA 402 state gating, explicit operating-mode read-back, trajectory parameter validation, and Execute-edge handling. The tables above extend those findings into a repeatable **proposed verification protocol**. They are not measured pass results, and no drive-specific homing method, positional tolerance, or safety performance level is asserted.

## Release Gate

A position axis should be marked commissioned only when the applicable tests have recorded evidence, deviations are dispositioned, reference-valid semantics are defined across resets, and the machine-level safety review is complete. Maintain per-axis records rather than assuming that a successful test on one drive validates all axes.

# CiA 402 Fault Recovery and Motion-Command Inhibition — Verification Contract

## Scope and evidence boundary

This engineering verification contract covers recovery of a multi-axis EtherCAT motion controller after a drive fault, a communication-state loss, or an interrupted motion command. The implemented control architecture uses PLCopen-style motion function blocks, a shared axis reference, process-image mapping, and CiA 402 status/controlword interpretation. The checks below are **proposed acceptance tests**, not a claim that every fault-injection scenario has already passed.

## Safety boundary

A PLC motion function block is not a safety function. Emergency stop, safe torque off, guarding, and personnel protection require separately engineered and validated safety measures. Run fault-injection tests only on a secured stand with appropriate independent safeguards.

## Command and state contract

1. Decode the actual drive state from the CiA 402 statusword; do not infer readiness from a previously issued controlword.
2. Inhibit all new motion requests unless the axis is in the required operational state and the fieldbus process data are valid.
3. When a fault is detected, invalidate pending motion completion and prevent stale `Execute` levels from automatically restarting the axis.
4. Treat `MC_Reset` as a fault-reset request, not proof that the fault has cleared. Confirm the resulting drive state through fresh status feedback.
5. Require a deliberate, new command edge after recovery; a pre-fault command must not resume solely because the drive returns to Operation Enabled.
6. Keep `Busy`, `Done`, `Error`, and `CommandAborted` mutually consistent with the observed state and the function block's defined interface contract.
7. Do not declare motion complete from a single statusword Target Reached bit without checking that it belongs to the active command and that command-specific conditions are satisfied.

## Acceptance matrix

| Test | Stimulus | Required evidence | Acceptance criterion |
| --- | --- | --- | --- |
| FR-01 | Inject a recoverable drive fault while idle | Statusword transition, fault indication, motion outputs | No new motion command accepted during fault |
| FR-02 | Inject a recoverable fault during active movement | Command lifecycle, axis feedback, output setpoints | Active command is terminated consistently; no false `Done` |
| FR-03 | Keep `Execute` high through fault and reset | Edge history, FB outputs, target setpoints | No unintended restart on return to ready state |
| FR-04 | Issue reset while fault remains active | Reset request and subsequent statusword samples | Reset completion is not confused with confirmed drive recovery |
| FR-05 | Lose EtherCAT operational communication | Slave state, process-data validity, FB state | Motion commands inhibited while feedback is invalid |
| FR-06 | Restore communication after state loss | Fresh statusword, mode feedback, command history | State and operating mode revalidated before new motion |
| FR-07 | Attempt conflicting motion commands during recovery | Arbitration trace and FB output transitions | Only a permitted command can acquire control |
| FR-08 | Re-enable and issue a new valid motion command | Fresh rising edge, actual position/velocity | Recovery permits controlled motion only after all preconditions hold |

## Trace capture

For each test, record a monotonic timestamp, task cycle, EtherCAT slave state, CiA 402 statusword and controlword, actual operating mode, motion FB `Execute/Busy/Done/Error/CommandAborted`, commanded and actual position/velocity, and the event that initiated recovery. Correlate transitions by cycle rather than relying solely on human-readable log timestamps.

## Interpretation and limits

Observed communication breakdown under CPU stress demonstrates why fieldbus validity must be part of motion-command gating; it does **not** by itself prove any specific drive fault-reset behavior. Similarly, an API reporting that a state-change request completed does not prove the slave reached the requested state. Both conditions require independent readback.

This contract specifies expected behavior for future validation. Test results, fault codes, drive-specific reset constraints, and measured recovery times must be attached only after reproducible execution.

## Engineering lessons

- Separate **request accepted**, **drive state confirmed**, and **motion permitted** into independently observable conditions.
- A fault reset is not a motion restart authorization.
- Clear stale command ownership and require a fresh operator or supervisory intent after recovery.
- Correlate process-data health with function-block lifecycle to avoid false success indications.

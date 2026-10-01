# Case 12 — Drive Enabled but No Motion: Isolating a Physical Connection Fault

## Context

During commissioning of a CiA 402 servo axis over EtherCAT, the communication stack was operational and the drive had progressed through the enable sequence. The intended cyclic operating mode was active, process data was being exchanged, and motion commands were being issued.

## Symptom

The axis did not move even though the software-visible conditions suggested that motion should have been possible. This created a typical commissioning trap: continuing to debug control logic after the software and fieldbus layers were already largely healthy.

## Evidence

The investigation established several positive conditions before changing the application:

- EtherCAT communication was active.
- The drive reached the expected enabled CiA 402 state.
- The requested operating mode was active.
- Cyclic command data was present.
- No software-side condition clearly explained the absence of mechanical motion.

Because the command path and state feedback were coherent, attention shifted from the application toward the physical motor/drive connection.

## Investigation

The fault was isolated layer by layer rather than by changing multiple parameters at once:

1. Confirm EtherCAT communication and slave state.
2. Confirm CiA 402 enable state from the statusword.
3. Confirm the active operating mode.
4. Confirm that the application is producing the expected target command.
5. Check for drive faults or interlocks.
6. Inspect the physical motor connection and reseat the connector.
7. Repeat the same motion command without changing the control logic.

This sequence was important because it preserved the known-good software state while testing the next layer in the signal chain.

## Root Cause

The motor connection was not seated reliably. The software, EtherCAT communication, and motion command path were functioning, but the physical connection prevented the commanded motion from reaching the motor correctly.

## Resolution

The motor connector was reseated and the axis was tested again using the same application configuration and motion command.

No compensating software change was required.

## Verification

After reseating the connector:

- the drive remained in the expected enabled state,
- the operating mode remained unchanged,
- the same cyclic command was applied,
- the motor rotated as expected.

Keeping the software conditions unchanged was a useful part of the verification because it isolated the physical connection as the effective correction.

## Engineering Lessons

- An enabled drive state does not prove that the complete electromechanical path is healthy.
- Once communication, state machine, mode, and target data have been verified, hardware connections should be checked before rewriting working control logic.
- Troubleshooting is faster when the system is divided into layers: application -> process data -> drive state -> power/interface -> motor/mechanics.
- Change one variable at a time. Repeating the identical command after a physical correction provides stronger root-cause evidence than changing hardware and software simultaneously.
- Positive evidence is valuable: proving that several layers are working narrows the fault domain just as effectively as finding an explicit error message.

# Case 09 — EtherCAT Topology and Slave-Count Mismatch

## Context

During commissioning of a multi-device EtherCAT network, the controller configuration and the physically detected bus topology did not agree. The network was expected to transition to operational state as a complete system, but cyclic communication remained unhealthy.

## Symptom

The EtherCAT master reported a mismatch between the configured and detected number of slaves. The network showed symptoms such as:

- failure to bring the complete topology into OP,
- degraded working-counter results,
- repeated state-transition failures,
- communication diagnostics indicating that the expected process-data exchange was incomplete.

## Evidence

The most useful evidence was the disagreement between two independent views of the system:

1. the topology expected by the engineering configuration, and
2. the topology actually detected on the EtherCAT bus.

Working-counter diagnostics also indicated that fewer process-data exchanges were being acknowledged than the configuration expected.

This was a topology/configuration problem rather than a motion-command problem, so debugging higher-level PLCopen commands would not have addressed the failure.

## Investigation

The investigation followed the bus from the communication layer upward:

1. Count the slaves detected by the EtherCAT master.
2. Compare the detected count with the configured topology.
3. Identify the unexpected, missing, or duplicated device position.
4. Verify device identity information and configuration files.
5. Check the physical chain and device order.
6. Re-scan or correct the engineering configuration.
7. Re-test INIT -> PRE-OP -> SAFE-OP -> OP transitions.
8. Confirm that the working counter reaches the expected value after the topology is corrected.

This order avoided wasting time on drive parameters before the fieldbus topology itself was valid.

## Root Cause

The configured EtherCAT topology did not match the physical network. Because the master expected a different set of process-data participants, the cyclic frame acknowledgements could not match the configured working counter and the complete network could not operate normally.

## Resolution

The physical slave chain and engineering configuration were reconciled so that the expected slave count, device identities, and ordering matched the actual network.

After correcting the mismatch, the network was transitioned through the EtherCAT states again and the process-data communication was revalidated.

## Verification

The correction was accepted only after all of the following were true:

- configured slave count matched the detected count,
- device order and identities were correct,
- all required slaves reached OP,
- the working counter matched the expected cyclic communication,
- no repeated topology/state-transition errors remained during operation.

## Engineering Lessons

- Always validate the physical EtherCAT topology before debugging application-level motion behavior.
- A working-counter mismatch is valuable evidence that the cyclic frame is not being acknowledged by the expected set of slaves.
- Slave count, device identity, and physical order should be treated as commissioning prerequisites.
- A fieldbus problem should be isolated at the lowest failing layer: topology first, state machine second, process data third, motion logic last.

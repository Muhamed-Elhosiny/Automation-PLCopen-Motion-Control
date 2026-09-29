# Case 10 — EtherCAT Vendor-ID / ESI Identity Mismatch

## Context

An EtherCAT network contained an I/O coupler whose physical identity did not match the vendor identity expected by the engineering configuration. The network could discover the hardware, but the controller could not complete normal startup into the operational state.

## Symptom

The EtherCAT network repeatedly failed during startup even though cabling and physical device presence appeared correct. State transitions stalled before full operation, and configuration-related communication errors appeared during initialization.

## Evidence

The investigation established a mismatch between two independent sources of device identity:

- the identity reported by the physical EtherCAT slave, and
- the identity declared by the selected EtherCAT Slave Information (ESI) description.

This was a stronger diagnostic signal than the higher-level state-transition errors because EtherCAT masters use identity information to validate that the configured device matches the hardware found at the expected topology position.

## Investigation

The diagnostic sequence was deliberately performed below the motion-control layer:

1. Confirm that the physical slave was detected on the EtherCAT bus.
2. Read or inspect the slave identity reported by the network.
3. Compare Vendor ID, Product Code, and revision information with the selected ESI entry.
4. Check whether multiple ESI variants existed for the same hardware family.
5. Replace the mismatched description with the variant matching the physical device identity.
6. Rebuild/apply the EtherCAT configuration.
7. Repeat INIT -> PRE-OP -> SAFE-OP -> OP startup and inspect the resulting slave states.

This avoided wasting time debugging PDO mappings or motion commands while the master/slave identity contract was still invalid.

## Root Cause

The selected ESI device description expected a different Vendor ID from the identity reported by the physical EtherCAT coupler. The configuration therefore described a device that was logically different from the slave present on the network.

The root cause was a device-description identity mismatch, not a servo-control or application-code problem.

## Resolution

The EtherCAT configuration was changed to use an ESI variant whose identity information matched the physical device.

After the correct device description was selected, the configuration was reapplied and the state-transition sequence was repeated.

## Verification

The resolution was considered verified only after:

- the configured identity matched the detected slave identity,
- the expected slave count and topology were present,
- the affected device progressed through the EtherCAT state machine,
- the network reached OP without the previous identity-related startup failure,
- cyclic process-data communication could then be validated separately.

## Engineering Lessons

- Device presence on the EtherCAT bus does not prove that the engineering description matches the hardware.
- Vendor ID, Product Code, and revision are first-class commissioning data and should be checked early when startup fails.
- ESI files from the same device family can contain identity variants; selecting by product name alone is not always sufficient.
- Diagnose EtherCAT startup bottom-up: physical presence -> identity -> topology -> state machine -> PDO/process data -> application motion.
- A configuration fix should be verified by the resulting bus state, not merely by the absence of an engineering-tool warning.

# Case 04 — Shared Process-Image Resource Conflict

## Context

A Linux-based industrial controller was running an EtherCAT application while engineering/runtime components were also active. Diagnostic access to EtherCAT resources unexpectedly failed even though the physical network was present.

## Symptom

Direct EtherCAT diagnostic commands could not access the expected process-image resources. The system reported conflicts around already existing shared-memory / process-image objects.

## Evidence

The controller already had active runtime services using the EtherCAT process image. Additional access attempts encountered existing shared resources rather than a missing network.

Related investigations also exposed how configuration changes can leave stale process-image variable names or duplicated mappings when objects are renamed or reconfigured.

## Investigation

The investigation focused on ownership of the EtherCAT/process-image resources:

1. Identify which runtime/service currently owns the EtherCAT instance.
2. Check active PLC/runtime processes.
3. Check whether a second engineering/runtime component is attempting to access the same shared resources.
4. Compare configured process-image names against currently exported/shared objects.
5. Restart or isolate services only when required for a controlled diagnostic test.

## Root Cause

The problem was caused by competing access to shared EtherCAT/process-image resources. The communication stack was already active and publishing shared resources, so a second access path could not simply assume exclusive control.

## Resolution

The diagnostic workflow was changed so that resource ownership was checked before accessing EtherCAT directly. For isolated tests, competing runtimes were stopped or deactivated in a controlled way before repeating the diagnostic command.

Configuration changes involving process-image names were also validated against the currently active shared objects to avoid stale/duplicate mappings.

## Verification

Successful verification required:

- one clearly identified owner of the EtherCAT runtime,
- expected shared process-image resources,
- no duplicate/stale variable mapping,
- successful diagnostic access after isolating competing services when necessary.

## Engineering Lessons

- On Linux-based controllers, fieldbus access may be mediated through shared-memory resources rather than direct exclusive hardware ownership.
- Before diagnosing a fieldbus stack as "broken," verify which service currently owns it.
- Runtime isolation is a useful diagnostic technique, but should be performed deliberately rather than by randomly stopping services.
- Renaming process-image objects requires validation of the exported/shared representation, not only the engineering configuration.

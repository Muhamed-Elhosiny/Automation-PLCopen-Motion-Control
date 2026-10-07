# FoE Local File Path and Filesystem Permission Boundaries

## Context

A File over EtherCAT (FoE) validation setup transferred a file between an EtherCAT master application and a slave device. The transfer API required a local filesystem path on the controller in addition to the remote FoE filename.

During validation, one local directory worked reliably while another path produced a permission-related failure. The engineering question was whether FoE itself restricts the usable controller directories, or whether the restriction belongs to the controller operating system and the process executing the EtherCAT application.

## Symptom

A FoE transfer succeeded when the local file was placed in an application-owned data directory, but an attempted transfer using another filesystem location encountered an access problem.

This could easily be misinterpreted as an EtherCAT or FoE protocol restriction on local file locations.

## Evidence

- FoE communication required both a remote filename and a local file path.
- The transfer worked with a known writable application data directory.
- A different local location produced a filesystem-access problem.
- The failure occurred on the controller side before a local file could be used normally by the transfer workflow.

No evidence showed that the FoE protocol itself defines a mandatory Linux directory for local files.

## Investigation

The investigation separated two independent concerns:

1. **FoE protocol scope** — transfer of file data over EtherCAT between master and slave.
2. **Local filesystem scope** — whether the EtherCAT application process can create, read, overwrite, or remove the selected local file.

A local path is interpreted by the controller operating system. Its usability therefore depends on factors such as directory permissions, mount state, application sandboxing, ownership, and runtime policy.

Running an EtherCAT master with elevated privileges does not make an arbitrary filesystem path part of the FoE protocol contract. Conversely, a successful transfer from one directory does not prove that every controller path is supported or appropriate for application use.

## Root Cause or Engineering Conclusion

**Engineering conclusion:** the observed path dependency was a local filesystem/runtime-access issue, not evidence of a FoE protocol limitation.

The validated application data directory should therefore be treated as the supported path for the tested integration unless additional directories are explicitly validated and documented.

The exact reason the alternate location was denied was not proven from the available evidence, so it is intentionally not presented as a confirmed root cause.

## Resolution

The FoE workflow was standardized on a known writable application data directory rather than exposing arbitrary filesystem locations to users.

For an engineering interface intended for repeatable use, the recommended approach is to define and document a supported local storage location and validate access before initiating the FoE transfer.

## Verification

Verification consists of:

- creating or opening the local file in the supported directory,
- executing the FoE transfer,
- confirming successful transfer completion,
- reading the transferred data back when applicable,
- checking that the resulting local file is accessible to the application.

Testing another directory should be considered a separate filesystem-compatibility test, not a FoE protocol test.

## Engineering Lessons

- Separate protocol behavior from operating-system filesystem behavior during diagnosis.
- A local path parameter is not automatically governed by the fieldbus protocol carrying the file data.
- Do not infer unrestricted filesystem access from the privilege level of a communication service.
- For customer-facing or reusable APIs, define a supported storage boundary instead of requiring users to discover writable paths by trial and error.
- Distinguish a **validated path** from an **exclusive protocol requirement** unless exclusivity has been proven.
- When the precise permission mechanism is unknown, document the supported engineering conclusion rather than promoting a hypothesis to root cause.

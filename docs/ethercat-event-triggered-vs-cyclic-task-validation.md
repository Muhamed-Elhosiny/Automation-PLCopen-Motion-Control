# EtherCAT Motion Tasks — Event-Triggered versus Cyclic Execution Validation

## Engineering objective

A 12-axis EtherCAT servo test system was exercised with both an event-triggered task associated with the EtherCAT network and a periodic PLC task. The engineering question is not which mode is universally faster, but whether each configuration preserves coherent process-data exchange, deterministic command updates, and observable deadline margin under an equivalent motion workload.

This document defines a **validation protocol**, not a claim that every listed acceptance test has passed.

## Architecture boundaries

| Layer | Verification question |
| --- | --- |
| PLC application | When is the motion state machine and velocity command calculated? |
| Task scheduler | Is execution released by a periodic clock or by the configured fieldbus event? |
| Process image | At what point are input snapshots consumed and output commands published? |
| EtherCAT master | What cycle period, synchronization, and process-data exchange are configured? |
| CiA 402 drive | Do Statusword, mode display, and actual velocity confirm the requested operating state? |

An event-triggered task does not automatically guarantee zero latency or eliminate jitter. A periodic task does not automatically imply an extra full-cycle delay. Both claims require timestamps or platform-supported timing traces.

## Controlled comparison

Keep the following constant across runs: controller and runtime build, 12-axis topology, PDO configuration, CSV operating mode, motion command pattern, axis scaling, background workload, and measurement interval. Record the actual EtherCAT cycle separately from the PLC task configuration.

Execute the following sequence independently for each task model:

1. **Idle baseline:** EtherCAT slaves in OP, axes enabled as required, no velocity request; record timing and communication counters.
2. **Command response:** apply a bounded positive velocity request, then negative velocity request; record command and actual-velocity timing.
3. **Stop/re-arm:** request a controlled stop, verify actual velocity reaches the defined standstill tolerance, and ensure a fresh command is required to resume.
4. **Sustained motion:** run all configured axes for a specified duration; record deadline misses, task maxima, and EtherCAT state changes.
5. **Background pressure:** repeat with a documented external load profile; do not substitute PLC computation loops and assume they create equivalent scheduler pressure.
6. **Recovery observation:** after any communication fault, verify drive and EtherCAT states explicitly before allowing motion commands again.

Stop the experiment when a drive or bus fault invalidates the intended comparison. Do not treat a stopped axis as a successful completion of the requested motion profile.

## Evidence record

For each trial retain:

- Task release mechanism, configured period (if periodic), priority, and synchronization source.
- EtherCAT network cycle, Distributed Clock settings if applicable, and initial/final slave states.
- Motion command issue time, process-image update timing where measurable, and drive feedback timestamps.
- Task execution-time distribution, maximum interval, overrun/deadline counters, and any debugger attachment events.
- Frame receive/busy timeouts, mailbox retries, working-counter anomalies where available, and the first observed fault timestamp.
- CPU-load method and level, duration, run identifier, and software revision.

Use a common clock or document clock-offset uncertainty before calculating cross-layer latency. If command and feedback are not timestamped on a common timebase, report their ordering qualitatively rather than inventing microsecond latency.

## Acceptance and interpretation

A configuration is accepted **only against specified application limits**, for example: no unexpected OP-to-SAFE-OP transition, no uncommanded motion, no task deadline violation, and command-to-feedback response within a defined project-specific bound. Missing timing instrumentation means the latency criterion is **not verified**, not passed.

Compare worst-case and distribution-tail timing alongside averages. The test campaign previously observed large debugger-associated timing outliers and externally generated CPU-load communication failures; these observations justify separate measurement-intrusion and scheduler-contention controls, but do **not** prove either task model inherently superior.

## Engineering conclusion

The task trigger, fieldbus cycle, and drive control loop are distinct scheduling domains. A valid comparison holds workload and process data constant, verifies actual drive and EtherCAT state, and correlates command timing with communication diagnostics. Any superiority claim remains conditional until repeated, instrumented trials establish it.

## Confidentiality

This protocol abstracts implementation-specific event paths, internal addresses, proprietary code, and unpublished vendor details. It documents engineering acceptance criteria rather than claiming production qualification.

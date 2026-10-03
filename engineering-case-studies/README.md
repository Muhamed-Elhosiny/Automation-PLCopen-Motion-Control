# Engineering Problem-Solving Case Studies

This section documents real engineering problems encountered during industrial automation, EtherCAT, motion-control, Linux-controller, and commissioning work.

The purpose is not only to record the final fix, but to preserve the complete engineering reasoning process: what was observed, what evidence was collected, which hypotheses were tested, what the root cause was, how the issue was resolved, and how the result was verified.

## Case-Study Structure

Each case follows the same engineering format:

1. **Context** — system and operating conditions
2. **Symptom** — what failed or behaved unexpectedly
3. **Evidence** — logs, measurements, state information, or reproducible observations
4. **Investigation** — diagnostic steps and hypotheses
5. **Root Cause** — confirmed cause, or the strongest supported conclusion when the root cause was not fully proven
6. **Resolution** — implemented fix or mitigation
7. **Verification** — how the result was validated
8. **Engineering Lessons** — reusable principles for future projects

## Current Cases

- [01 — Concurrent SDO Access Causing Intermittent Initialization Failures](01-concurrent-sdo-access.md)
- [02 — EtherCAT State Transition Blocked by Distributed Clock Synchronization](02-dc-sync-state-transition.md)
- [03 — EtherCAT Communication Failure Under High CPU Load](03-cpu-load-frame-timeout.md)
- [04 — Shared Process-Image Resource Conflict](04-process-image-resource-conflict.md)
- [05 — Drive Operating Mode Not Restored After Startup](05-operating-mode-initialization.md)
- [06 — Industrial Controller Network/Gateway Reconfiguration](06-network-gateway-reconfiguration.md)
- [07 — 24 V Supply Collapse When Controller Was Connected](07-power-supply-voltage-collapse.md)
- [08 — Multi-Axis Velocity Scaling Mismatch](08-multi-axis-scaling-mismatch.md)
- [09 — EtherCAT Topology and Slave-Count Mismatch](09-ethercat-topology-slave-count-mismatch.md)
- [10 — EtherCAT Vendor-ID / ESI Identity Mismatch](10-ethercat-vendor-id-esi-mismatch.md)
- [11 — Cyclic Velocity Command Rejected by Invalid Trajectory Parameters](11-csv-invalid-trajectory-parameters.md)
- [12 — Drive Enabled but No Motion: Isolating a Physical Connection Fault](12-drive-enabled-but-no-motion.md)
- [13 — EtherCAT State-Change Command Completed but Requested State Was Not Reached](13-ethercat-state-feedback-semantics.md)
- [14 — Diagnosing Multiple Cycle-Time Settings in a Real-Time EtherCAT System](14-ethercat-cycle-time-configuration-layers.md)

## Confidentiality

The case studies intentionally exclude proprietary source code, internal IP addresses, customer data, credentials, unpublished implementation details, and other confidential information. Technical descriptions are generalized while preserving the engineering reasoning and lessons learned.

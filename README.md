# Automation & PLCopen Motion Control Engineering Portfolio

Engineering portfolio focused on industrial motion control, EtherCAT, CiA 402, PLCopen-style function-block architecture, multi-axis commissioning, real-time validation, and systematic troubleshooting.

The repository documents both implementation patterns and engineering case studies. Its emphasis is on the complete engineering workflow: architecture, commissioning, diagnostics, root-cause analysis, verification, and reusable lessons.

## Engineering Scope

- PLCopen-style motion-control function-block design
- EtherCAT cyclic and acyclic communication
- CiA 402 drive state-machine handling
- Multi-axis servo startup and commissioning
- PDO / SDO integration and verification
- Motion scaling and engineering-unit conversion
- Real-time cycle-time and jitter evaluation
- Intermittent fault reproduction and evidence-based diagnosis
- Linux-based industrial-controller diagnostics

## Documentation

The [`docs/`](docs/) section contains engineering guides and implementation notes covering architecture, commissioning, EtherCAT diagnostics, CiA 402, motion scaling, Structured Text patterns, and performance-testing methodology.

Recommended starting points:

- [System Architecture](docs/architecture.md)
- [Commissioning Workflow](docs/commissioning-workflow.md)
- [EtherCAT Diagnostic Playbook](docs/ethercat-diagnostic-playbook.md)
- [CiA 402 State Machine](docs/cia402-state-machine.md)
- [Real-Time Motion Test Methodology](docs/real-time-motion-test-methodology.md)
- [Structured Text Motion Patterns](docs/structured-text-motion-patterns.md)

## Engineering Problem-Solving Case Studies

The [`engineering-case-studies/`](engineering-case-studies/) section preserves real troubleshooting work in a consistent format:

**Context → Symptom → Evidence → Investigation → Root Cause / Engineering Conclusion → Resolution → Verification → Engineering Lessons**

Current cases include:

- concurrent SDO initialization failures,
- Distributed Clock synchronization blocking EtherCAT state transitions,
- EtherCAT communication degradation under high CPU load,
- process-image resource conflicts,
- drive operating-mode initialization,
- industrial-controller network configuration,
- 24 V supply behavior under load,
- multi-axis velocity scaling mismatch.

See the [case-study index](engineering-case-studies/README.md) for the complete archive.

## Engineering Approach

The material in this repository follows several principles:

1. **Verify actual state, not only command completion.**
2. **Separate symptoms from confirmed root causes.**
3. **Use logs and measurements as engineering evidence.**
4. **Change one variable at a time during fault isolation.**
5. **Validate configuration through read-back and feedback.**
6. **Measure real-time behavior under realistic system load.**
7. **Document unsuccessful mitigations when they narrow the investigation.**

## Confidentiality

Examples and case studies are intentionally generalized. Proprietary source code, internal network addresses, credentials, customer information, and confidential implementation details are excluded while retaining the transferable engineering reasoning.

---

**Muhammad Elhosiany**  
Automation · Motion Control · EtherCAT · PLCopen · Industrial Linux

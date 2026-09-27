# Case 01 — Concurrent SDO Access Causing Intermittent Initialization Failures

## Context

A multi-axis EtherCAT servo system required startup configuration through SDO access before cyclic motion operation. Several drives were initialized in parallel from the controller application.

## Symptom

The first group of drives completed SDO initialization successfully, while later drives intermittently remained uninitialized. Reads of the operating-mode objects returned valid values for some axes but invalid or unavailable values for others.

The failure was not permanent: the same slaves could still be reached from the controller's Linux diagnostic interface after the PLC test.

## Evidence

- Early axes returned the expected operating-mode values.
- Later axes returned invalid results during the parallel PLC sequence.
- Manual SDO reads performed afterward could reach all drives.
- The behavior changed with timing and execution order, indicating an intermittent rather than static configuration fault.

## Investigation

The investigation deliberately separated three possible causes:

1. **Slave communication failure** — rejected because all drives remained reachable through direct diagnostic access.
2. **Incorrect object dictionary configuration** — unlikely because the same objects could be read successfully outside the failing sequence.
3. **Concurrent acyclic mailbox access limitation** — supported by the fact that failures appeared during parallel startup requests and disappeared when access was serialized.

The test strategy was changed from parallel initialization to controlled sequential access so that only one SDO transaction was active at a time.

## Root Cause

The evidence pointed to excessive concurrent acyclic SDO/mailbox activity during startup. Multiple initialization transactions were being issued in parallel faster than the communication path could reliably complete them.

## Resolution

The startup sequence was redesigned to serialize the SDO operations:

```text
Axis 1: Write mode -> Read back -> Validate
Axis 2: Write mode -> Read back -> Validate
Axis 3: Write mode -> Read back -> Validate
...
```

Each transaction was allowed to complete or time out before the next axis was processed.

## Verification

Verification consisted of repeated startup cycles while checking:

- successful write completion,
- successful read-back,
- expected operating-mode display,
- absence of invalid results on later axes,
- continued EtherCAT availability of all slaves.

## Engineering Lessons

- Acyclic fieldbus communication should not be treated like unlimited parallel memory access.
- A successful direct diagnostic read can help distinguish a timing/concurrency problem from a permanently unreachable slave.
- Startup configuration should include read-back verification rather than assuming a completed write means the device accepted the final state.
- Sequential initialization is often preferable when deterministic startup matters more than a few milliseconds of boot time.

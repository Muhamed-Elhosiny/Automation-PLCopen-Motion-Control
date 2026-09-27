# Case 05 — Drive Operating Mode Not Restored After Startup

## Context

A servo axis was intended to operate in Cyclic Synchronous Velocity mode. One drive reported the expected operating mode after startup while another remained at the default mode value and could not proceed into the intended motion sequence.

## Symptom

The requested mode was not consistently active after startup. The control application could write motion-related process data, but the affected axis did not report the expected operating-mode display.

## Investigation

The diagnosis focused on the CiA 402 operating-mode objects:

- requested mode object,
- displayed/active mode object,
- timing of the startup write,
- competition with other startup configuration traffic,
- confirmation that the axis was otherwise reachable.

The important diagnostic principle was to verify the active mode rather than assuming that a write had succeeded.

## Root Cause

The operating mode was not being reliably established during startup. The system needed an explicit initialization step that wrote the requested mode and then read back the active mode before enabling motion.

## Resolution

A dedicated initialization sequence was introduced:

```text
Write requested operating mode
        |
        v
Wait for completion
        |
        v
Read operating-mode display
        |
        +--> expected value -> initialization complete
        |
        +--> unexpected value / timeout -> fault handling
```

The sequence was executed before enabling cyclic motion commands.

## Verification

The drive was accepted as ready only after the operating-mode display confirmed the requested mode. Repeated startup cycles were used to make sure the result was not accidental.

## Engineering Lessons

- Configuration writes should be followed by read-back verification.
- Motion should be gated on confirmed device state, not on assumptions about startup defaults.
- A dedicated initialization state machine is easier to debug than scattered one-shot SDO writes.

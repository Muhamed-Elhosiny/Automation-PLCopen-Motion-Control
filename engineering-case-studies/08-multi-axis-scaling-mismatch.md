# Case 08 — Multi-Axis Velocity Scaling Mismatch

## Context

A multi-axis servo system used different motor feedback configurations. The application commanded the same engineering velocity to all axes, but several drives required different conversion between engineering units and drive-internal increments.

## Symptom

Axes commanded with the same numerical speed did not all rotate at the same physical speed. The discrepancy appeared on a subset of drives rather than across the entire system.

## Investigation

The diagnostic approach compared:

- requested engineering velocity,
- drive target velocity,
- actual velocity feedback,
- encoder/resolver increments per revolution,
- conversion between revolutions per minute and increments per second,
- per-axis scaling parameters.

For a feedback resolution of 1,048,576 increments per revolution, the velocity conversion factor for 1 rpm is:

```text
1,048,576 increments/revolution / 60 seconds/minute
= 17,476.2667 increments/second per rpm
```

This made it possible to distinguish a motion-control problem from a unit-conversion problem.

## Root Cause

The affected axes did not use the same raw-unit interpretation as the application-level velocity command. A per-axis scaling layer was required so that the same engineering command represented the same physical speed on every motor.

## Resolution

The control structure was separated into two layers:

```text
Engineering command
    rpm / position units
          |
          v
Per-axis scaling
          |
          v
Drive process-data units
```

Scaling was configured individually where required instead of applying a single conversion globally to every axis.

## Verification

All axes were commanded with the same engineering velocity and compared using actual velocity feedback and physical motion. The test was repeated in both directions to verify sign convention as well as magnitude.

## Engineering Lessons

- Equal numerical commands do not guarantee equal physical motion unless units and feedback resolution are normalized.
- Scaling belongs in a clearly defined layer rather than being scattered through motion commands.
- Actual feedback should be used to validate unit conversion, not only target values.
- Multi-axis commissioning should explicitly test cross-axis consistency before coordinated motion is attempted.

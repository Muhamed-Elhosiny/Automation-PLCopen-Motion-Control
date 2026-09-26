# Motion Scaling and Unit Conversion

## Purpose

A motion-control application is easier to commission, test, and maintain when the application works in engineering units while drive-specific encoder counts and cyclic values remain isolated behind a conversion layer.

This note presents a vendor-neutral method for designing that layer for PLCopen and EtherCAT/CiA 402 motion systems. The examples are intentionally generic and contain no proprietary device configuration.

## 1. Keep three domains separate

A useful architecture distinguishes between:

1. **Application units** — units meaningful to the machine, such as mm, degrees, mm/s, rpm, or revolutions.
2. **PLCopen units** — the units exposed by the motion abstraction used by the application.
3. **Drive/process-data units** — encoder increments, internal position units, or cyclic velocity values exchanged with the drive.

Do not spread conversion constants throughout the application. Put them in one documented scaling layer.

## 2. Position scaling

For a rotary axis, define:

- `CountsPerMotorRev`: feedback increments per motor revolution
- `GearRatio`: motor revolutions / load revolutions
- `TravelPerLoadRev`: linear travel per load revolution, when applicable

For a direct rotary representation:

```text
counts_per_load_rev = CountsPerMotorRev * GearRatio
```

For a linear axis:

```text
counts_per_mm = counts_per_load_rev / TravelPerLoadRev
```

Then:

```text
drive_position_counts = application_position_mm * counts_per_mm
```

and the inverse conversion is:

```text
application_position_mm = drive_position_counts / counts_per_mm
```

The same principle applies to degrees or revolutions: define the physical relationship once and derive both forward and inverse conversions from it.

## 3. Velocity scaling

Velocity errors are common because position units and velocity units often use different time bases.

If the application command is in revolutions per minute and the drive expects counts per second:

```text
counts_per_second = rpm * CountsPerMotorRev / 60
```

If gearing is included at the load side:

```text
counts_per_second = load_rpm * GearRatio * CountsPerMotorRev / 60
```

For a linear application, derive velocity from the same position scaling rather than introducing an unrelated constant:

```text
counts_per_second = velocity_mm_per_s * counts_per_mm
```

This keeps position and velocity mathematically consistent.

## 4. Direction convention

Scaling is not only magnitude. Direction must also be defined.

Use one explicit sign parameter per axis, for example:

```text
DirectionSign = +1
```

or

```text
DirectionSign = -1
```

Apply it at the conversion boundary rather than adding negative signs in multiple motion commands.

A commissioning record should state what positive motion means physically, for example "clockwise viewed from the shaft" or "carriage moves toward the machine exit."

## 5. Generic Structured Text pattern

The following example illustrates the separation. Names are deliberately generic.

```iecst
// Engineering configuration
lrCountsPerRev := 1048576.0;
lrGearRatio := 1.0;
lrDirection := 1.0;

// Derived conversion
lrCountsPerSecondPerRpm :=
    (lrCountsPerRev * lrGearRatio) / 60.0;

// Application rpm -> cyclic drive velocity
lrDriveVelocity :=
    lrCommandRpm * lrCountsPerSecondPerRpm * lrDirection;

// Drive feedback -> application rpm
lrActualRpm :=
    lrActualDriveVelocity /
    (lrCountsPerSecondPerRpm * lrDirection);
```

In production code, guard against zero divisors and validate configuration before enabling motion.

## 6. Use REAL/LREAL for the calculation boundary

Integer process data should not force integer arithmetic through the whole application.

A robust pattern is:

```text
Engineering command
        |
        v
Floating-point conversion
        |
        v
Range / overflow check
        |
        v
Explicit conversion to process-data type
        |
        v
PDO output
```

Perform rounding intentionally. Avoid relying on implicit type conversion where truncation could be hidden.

## 7. Overflow and range checks

Before converting to an integer target value, verify that the result is representable by the target type and permitted by the machine.

Typical checks include:

- maximum application velocity
- maximum drive target value
- signed/unsigned range
- acceleration and deceleration limits
- software travel limits
- valid scaling configuration

Conceptually:

```iecst
IF ABS(lrDriveVelocity) > lrMaximumDriveVelocity THEN
    xScalingError := TRUE;
ELSE
    diTargetVelocity := LREAL_TO_DINT(lrDriveVelocity);
END_IF;
```

The machine limit should normally be stricter than the numeric datatype limit.

## 8. Verify scaling with low-risk tests

Scaling should be verified before high-speed or long-distance movement.

### Test A — one revolution

Command a known small movement and compare:

- commanded engineering position
- expected motor revolutions
- actual feedback change
- physical movement

### Test B — low constant velocity

Command a low speed for a measured interval. Compare expected travel with actual travel.

### Test C — direction

Apply a small positive command and verify the documented positive physical direction.

### Test D — inverse conversion

Confirm that converted feedback returns approximately the same engineering value as the command under steady-state conditions.

## 9. Multi-axis systems

Do not assume identical scaling because drives or motors look similar.

Store scaling as axis-specific configuration:

```iecst
TYPE ST_AxisScaling :
STRUCT
    lrCountsPerRev : LREAL;
    lrGearRatio : LREAL;
    lrTravelPerRev : LREAL;
    lrDirection : LREAL;
END_STRUCT
END_TYPE
```

A multi-axis application can then use an array of configuration structures while reusing the same conversion functions.

This is especially useful when axes have different feedback devices, gearboxes, mechanics, or direction conventions.

## 10. Common scaling mistakes

| Symptom | Likely scaling problem |
|---|---|
| Axis moves exactly 60x too fast/slow | minute/second conversion missing |
| Position is correct but velocity is wrong | position factor reused without time-base conversion |
| Axis moves in the opposite direction | sign convention inconsistent |
| Similar axes run at different physical speeds | per-axis feedback/mechanical scaling differs |
| Large command wraps or changes sign | integer overflow |
| Small commands become zero | integer conversion performed too early |
| Feedback does not match command units | inverse conversion missing or inconsistent |

## 11. Commissioning checklist

Before enabling normal operation, verify:

- [ ] Feedback resolution is documented.
- [ ] Gear ratio convention is explicitly defined.
- [ ] Mechanical travel per revolution is known when relevant.
- [ ] Application engineering units are documented.
- [ ] Drive position and velocity time bases are known.
- [ ] Positive direction is documented and tested.
- [ ] Forward and inverse conversions use the same constants.
- [ ] Numeric range and overflow are checked.
- [ ] Each axis has its own scaling configuration where necessary.
- [ ] A low-speed physical validation has been completed.

## 12. Design principle

A good motion application should be readable in machine units:

```text
MoveVelocity(100 rpm)
MoveAbsolute(250 mm)
```

rather than exposing unexplained encoder constants to the application logic.

The conversion layer is the boundary between physical machine intent and device representation. Keeping that boundary explicit makes commissioning safer, multi-axis behavior easier to compare, and troubleshooting much faster.

---

**Portfolio note:** This document describes general engineering practice for motion-control scaling. Values and code are illustrative and vendor-neutral.
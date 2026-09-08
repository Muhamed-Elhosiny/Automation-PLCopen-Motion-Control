# Troubleshooting and Engineering Challenges

This document summarizes representative engineering challenges encountered while developing and commissioning EtherCAT servo systems.

> The examples are intentionally generalized for portfolio use. Proprietary source code, confidential company data, customer information, credentials, and internal network details are not included.

## 1. EtherCAT Slave-Count Mismatch

### Symptom

The EtherCAT master reported a different number of detected slaves than expected.

Example diagnostic pattern:

```text
Expected slave count: 6
Detected slave count: 7
```

### Investigation

The troubleshooting process included:

- Checking the physical EtherCAT topology
- Verifying the order of devices on the bus
- Comparing configured device descriptions with the actual hardware
- Checking Vendor IDs and Product Codes
- Reviewing the ESI/XML device description files

### Root Cause

The configured device description did not fully match the actual device identity expected by the EtherCAT master.

### Solution

The device description was corrected and the EtherCAT configuration was regenerated and validated.

### Result

The master enumerated the bus correctly and the slaves could proceed through the EtherCAT state transitions toward Operational state.

---

## 2. Drive Did Not Reach Operation Enabled

### Symptom

The drive was detected on EtherCAT, but motion could not start because the CiA 402 state machine did not reach `Operation Enabled`.

The control sequence stopped before the final enable state.

### Investigation

The following were checked:

- Status-word state decoding
- Control-word transition sequence
- Fault-reset handling
- Brake-release conditions
- Drive enable conditions
- Operating-mode selection

### Root Cause

The command sequence and enabling conditions were not aligned with the drive state required for the final transition into Operation Enabled.

### Solution

The enable logic was corrected so that the CiA 402 transitions occurred in the required sequence and the related release conditions were handled correctly.

### Result

The drive successfully reached Operation Enabled and accepted motion commands.

---

## 3. EtherCAT Slave Lost After Hardware Change

### Symptom

After modifying the drive chain or reconnecting hardware, the EtherCAT master reported errors such as a changed slave number or an unexpected Working Counter.

Typical diagnostic patterns can include:

```text
Slave number changed
Unexpected slave count
Working Counter lower than expected
```

### Investigation

The checks included:

- Inspecting cable connections
- Confirming each physical slave in sequence
- Re-enumerating the EtherCAT bus
- Comparing the detected topology with the engineering configuration
- Checking whether a connector or device had been disconnected or inserted at a different location

### Root Cause

The physical topology no longer matched the stored EtherCAT configuration.

### Solution

The hardware connection and configuration were brought back into agreement and the bus was revalidated.

### Result

The expected topology was restored and cyclic communication became stable again.

---

## 4. Operating Mode Not Active After Startup

### Symptom

A drive did not start in the required motion mode after a restart.

The requested operating mode and the active operating mode did not always match automatically after power-up.

### Investigation

The diagnostic approach included reading the CiA 402 operating-mode objects and confirming the requested and displayed mode values.

Conceptually:

```text
Requested mode → Drive
Actual mode    ← Drive
```

### Root Cause

The required mode had been written during runtime but was not guaranteed to be restored automatically after every startup.

### Solution

Startup logic was added so that the controller explicitly requests the required operating mode and verifies that the drive has accepted it before motion is permitted.

### Result

The motion mode became deterministic across restarts.

---

## 5. Resolver / Encoder Scaling Difference Between Motors

### Symptom

Some axes showed incorrect speed or position scaling even though the same generic motion code worked correctly on other motors.

### Investigation

The troubleshooting process included:

- Comparing motor feedback types
- Checking encoder or resolver resolution
- Reviewing increments-per-revolution values
- Verifying engineering-unit conversion factors
- Comparing commanded speed with measured mechanical speed

### Root Cause

Different feedback systems required different conversion factors between drive increments and engineering units.

### Solution

The scaling was separated from the generic motion logic and handled through axis-specific configuration.

### Result

The same reusable motion function blocks could be used with different motor-feedback configurations while keeping correct engineering units.

---

## 6. Drive Oscillation During Commissioning

### Symptom

One motor showed unstable or oscillating behavior while other axes operated normally.

### Investigation

The analysis focused on:

- Motor parameterization
- Feedback configuration
- Scaling
- Servo tuning
- Mechanical loading
- Comparison with a known-good axis

### Root Cause

The drive configuration did not fully match the connected motor parameters.

### Solution

The motor-related parameters were corrected and the axis was recommissioned.

### Result

The oscillation disappeared and the axis operated normally.

---

## 7. Real-Time Cycle-Time Verification

### Goal

After functional commissioning, the controller and EtherCAT timing were tested under increasing motion load.

### Test Strategy

The system was tested progressively:

1. EtherCAT Operational, axes disabled
2. Drives enabled without motion
3. Several axes moving
4. Increased number of moving axes
5. Full multi-axis motion

### Monitored Values

- PLC task cycle time
- Minimum cycle time
- Maximum cycle time
- Jitter
- CPU load
- EtherCAT communication errors

### Representative Result

For a 1 ms cyclic task, measured average execution timing remained close to the requested cycle period while multiple axes were active.

Representative engineering measurements from the test setup were approximately:

```text
Configured cycle: 1 ms
Average measured cycle: ~999.7 µs
Measured jitter: ~80 µs
```

The purpose of this test was not only to prove that the motors moved, but also to verify that the controller maintained sufficiently stable cyclic execution under multi-axis load.

---

## Troubleshooting Methodology

A recurring principle throughout the project was to troubleshoot from the lowest layer upward:

```text
Physical wiring
      ↓
EtherCAT topology
      ↓
Device identity / ESI
      ↓
Process data
      ↓
CiA 402 drive state
      ↓
Operating mode
      ↓
Motion command
      ↓
Mechanical behavior
```

This avoids debugging high-level PLC logic while the underlying communication or drive state is still incorrect.

## Engineering Takeaways

The main lessons from the commissioning work were:

- Verify the physical topology before debugging software.
- Treat EtherCAT device identity and ESI files as part of the control system, not merely configuration files.
- Always verify both requested and actual CiA 402 operating modes.
- Separate axis-specific scaling from generic motion logic.
- Use status-word and control-word analysis instead of guessing why a drive does not enable.
- Test real-time behavior under increasing load rather than only with a single axis.
- A successful motion-control system requires communication, state-machine logic, drive configuration, timing, and mechanics to work together.

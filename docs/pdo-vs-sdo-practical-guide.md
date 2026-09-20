# EtherCAT PDO vs SDO — Practical Motion-Control Guide

## Purpose

In EtherCAT motion-control projects, PDO and SDO communication solve different engineering problems. Understanding when each mechanism belongs in startup, cyclic control, diagnostics, and commissioning is essential for reliable multi-axis systems.

This guide focuses on practical decision-making rather than vendor-specific implementation.

---

## 1. The Short Version

| Mechanism | Best suited for | Typical timing |
|---|---|---|
| PDO (Process Data Object) | Real-time cyclic control data | Every EtherCAT cycle |
| SDO (Service Data Object) | Configuration, parameters, diagnostics | On demand / startup |

A useful engineering rule is:

> **PDO for deterministic cyclic control; SDO for configuration and service access.**

---

## 2. PDO in a Servo Application

PDOs carry the process data that the controller and drive exchange continuously.

Typical controller-to-drive data includes:

- Controlword
- Target position
- Target velocity
- Target torque
- Operating-mode command, when mapped

Typical drive-to-controller data includes:

- Statusword
- Actual position
- Actual velocity
- Actual torque
- Operating-mode display, when mapped

For a motion application with a 1 ms control task, the relevant PDO data is normally exchanged once per cycle.

This makes PDO communication appropriate for values that participate directly in the real-time control loop.

---

## 3. Why Motion Commands Should Not Depend on SDO Traffic

SDO access is request/response communication intended for parameter and service access. It is not the preferred mechanism for deterministic cyclic motion control.

Using repeated SDO transactions inside a fast motion loop can create several problems:

1. Communication completion time is not equivalent to the cyclic process-data exchange.
2. Multiple axes can generate many simultaneous service requests.
3. Startup logic becomes dependent on transaction completion and timeout handling.
4. Diagnostics become harder because communication and motion sequencing are mixed together.

A cleaner architecture separates the two responsibilities.

```text
Startup / Commissioning
        |
        +--> SDO configuration
        +--> Read-back verification
        |
        v
Ready for cyclic operation
        |
        +--> PDO Controlword
        +--> PDO Target values
        +--> PDO Statusword
        +--> PDO Actual values
```

---

## 4. Typical SDO Use Cases

SDOs are useful when a parameter is not required every control cycle.

Examples include:

- Setting an operating mode during initialization
- Reading a device parameter during commissioning
- Configuring limits
- Reading diagnostic objects
- Writing setup parameters
- Verifying a configuration value after startup
- Storing parameters when supported by the device

The exact object dictionary is device-specific and should always be checked against the drive documentation.

---

## 5. Read-Back Verification

A robust configuration sequence should not assume that a successful write automatically means the drive is ready for motion.

A stronger pattern is:

```text
Request configuration write
        |
        v
Wait for completion
        |
        v
Read parameter back
        |
        v
Expected value received?
     /         \
   Yes          No
    |            |
Continue     Retry / diagnose
```

This is particularly useful in multi-axis systems where one axis may initialize differently from the others.

---

## 6. PDO Mapping and the Process Image

The EtherCAT master maps selected process data into a cyclic process image.

Conceptually:

```text
PLC Application
      |
      v
Process Image
      |
      v
EtherCAT Master
      |
      v
Drive PDOs
```

The application reads and writes process variables while the EtherCAT master handles cyclic network exchange.

This separation is important because the application does not need to execute an individual network transaction for every process value during every cycle.

---

## 7. Example: Cyclic Synchronous Velocity

For a generic CiA 402 velocity application, a simplified control path can look like this:

```text
Motion Profile
     |
     v
Target Velocity
     |
     v
PDO Output
     |
     v
EtherCAT
     |
     v
Servo Drive
```

Feedback follows the opposite direction:

```text
Servo Drive
     |
     v
Actual Velocity / Statusword
     |
     v
PDO Input
     |
     v
PLC Motion Logic
```

Configuration needed before this cyclic exchange may be performed through SDO access or through startup configuration supplied by the EtherCAT master.

---

## 8. Multi-Axis Startup Strategy

With many servo axes, configuration should be treated as a state machine rather than a collection of unrelated requests.

A practical per-axis sequence is:

```text
IDLE
  |
  v
WRITE_CONFIGURATION
  |
  v
WAIT_WRITE
  |
  v
READ_BACK
  |
  v
VERIFY
  |
  +---- mismatch ---> ERROR / RETRY
  |
  v
READY
```

The global motion layer should start only after the required axes report `READY`.

For example:

```text
Axis 1 Ready  --+
Axis 2 Ready  --+
Axis 3 Ready  --+--> AllAxesReady --> Enable Motion
...             |
Axis N Ready  --+
```

This avoids enabling a common motion profile while one drive is still being configured.

---

## 9. Parallel vs Sequential SDO Initialization

### Parallel initialization

Multiple axes receive configuration requests at approximately the same time.

**Advantages**

- Faster startup when the communication stack and devices support the load
- Simple high-level trigger

**Engineering considerations**

- More simultaneous mailbox traffic
- Timeout and resource behavior must be tested
- Failures can be harder to isolate

### Sequential initialization

Axes are configured one after another.

**Advantages**

- Easier diagnostics
- Predictable transaction ordering
- Useful as a comparison method when investigating intermittent failures

**Engineering considerations**

- Longer total startup time

A useful diagnostic technique is to reproduce the same configuration once in parallel and once sequentially. If the behavior changes significantly, the investigation can focus on concurrency, mailbox handling, timeout behavior, or resource limits rather than the parameter itself.

---

## 10. Common Diagnostic Questions

When an axis does not initialize correctly, check the problem layer by layer.

### EtherCAT layer

- Is the slave present?
- Is the expected device detected?
- Has the slave reached the required EtherCAT state?

### Service communication

- Did the SDO request start?
- Did it complete?
- Was an abort code returned?
- Did it exceed the configured timeout?

### Parameter verification

- Does read-back equal the requested value?
- Is the parameter writable in the current device state?
- Does the change require a restart or explicit parameter storage?

### Cyclic process data

- Is the expected PDO mapped?
- Does the process image update?
- Does the drive Statusword change when the Controlword changes?

### Motion layer

- Is the drive in the required CiA 402 state?
- Is the requested operating mode active?
- Are target values reaching the PDO output?
- Are scaling and units correct?

---

## 11. Architecture Principle

A maintainable motion-control application benefits from separating three layers:

```text
+----------------------------------+
| Motion / PLCopen Application     |
+----------------------------------+
| CiA 402 + Process Data Handling  |
+----------------------------------+
| EtherCAT Communication           |
|   PDO: cyclic                    |
|   SDO: configuration/service     |
+----------------------------------+
```

This separation makes failures easier to locate and allows each layer to be tested independently.

---

## 12. Engineering Takeaway

PDO and SDO are complementary, not competing mechanisms.

A reliable servo application normally uses:

- **SDO** to configure and verify parameters that do not belong in the deterministic cyclic loop.
- **PDO** to exchange the commands and feedback required by real-time motion control.
- **State-based startup logic** to ensure configuration is complete before motion begins.
- **Read-back and diagnostics** instead of assuming that a request produced the intended device state.

This pattern scales from a single-axis commissioning setup to larger multi-axis EtherCAT machines.

---

## Portfolio Note

The examples in this document are intentionally vendor-neutral and contain no proprietary device configuration, credentials, internal network information, or company-specific source code.
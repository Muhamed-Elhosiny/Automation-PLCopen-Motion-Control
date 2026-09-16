# EtherCAT Servo Commissioning Workflow

This page documents a reusable engineering workflow for commissioning multi-axis EtherCAT servo systems with CiA 402 motion control. It is intentionally vendor-neutral and contains no proprietary source code, customer data, credentials, or internal network information.

## Objective

The goal of commissioning is not simply to make a motor rotate. A robust commissioning process proves each layer of the motion system independently before enabling automatic movement:

```text
Physical installation
        ↓
EtherCAT communication
        ↓
Process-data mapping
        ↓
CiA 402 state machine
        ↓
Operating mode
        ↓
Feedback and scaling
        ↓
Controlled motion
        ↓
Multi-axis validation
```

This staged approach reduces debugging time because a failure can be assigned to a specific layer instead of troubleshooting the complete machine at once.

## 1. Physical and Safety Checks

Before enabling the fieldbus or power stage:

- Verify drive and motor power connections.
- Verify encoder or resolver feedback connections.
- Confirm protective earth and shielding.
- Check the EtherCAT cable order against the intended topology.
- Ensure mechanical movement is safe and unobstructed.
- Keep motion commands disabled during initial communication tests.

A commissioning workflow should always separate **communication readiness** from **motion permission**.

## 2. Verify EtherCAT Topology

Start by checking whether the controller discovers the expected number of EtherCAT devices in the expected order.

Typical checks include:

- Slave count
- Station order
- Vendor and product identification
- Device-description compatibility
- Link state
- Working-counter consistency

A detected device is not yet proof of a valid configuration. The configured identity and the identity reported by the physical device must also agree.

## 3. Bring the Network Through EtherCAT States

Validate the transition through the EtherCAT communication states:

```text
INIT → PRE-OP → SAFE-OP → OP
```

If a slave does not reach `OP`, investigate the fieldbus layer before debugging motion-control logic.

Useful diagnostic categories are:

- Configuration mismatch
- Invalid or missing startup parameters
- PDO mapping mismatch
- Distributed-clock or synchronization problems
- Working-counter errors
- Physical communication faults

## 4. Validate Process Data

Before sending motion commands, confirm that cyclic process data is exchanged correctly.

For a CiA 402 drive, typical process data includes:

### Controller → Drive

- Controlword
- Target position or target velocity
- Operating-mode command

### Drive → Controller

- Statusword
- Actual position
- Actual velocity
- Operating-mode display

A useful first test is to rotate the motor shaft manually, where mechanically safe, and verify that the actual-position value changes in the expected direction.

## 5. Confirm the Operating Mode

The commanded mode and the drive-reported mode should be checked independently.

For example, in a velocity-oriented application:

```text
Write requested operating mode
        ↓
Read operating-mode display
        ↓
Continue only after confirmation
```

This prevents the application from starting a motion profile while one or more axes are still configured for a different mode.

For multi-axis systems, a useful design pattern is to gate motion startup until **all required axes confirm the expected mode**.

## 6. Execute the CiA 402 Enable Sequence

The drive state should be derived from the Statusword rather than from assumptions based on elapsed time.

Conceptually, commissioning follows the CiA 402 progression toward:

```text
Switch On Disabled
        ↓
Ready to Switch On
        ↓
Switched On
        ↓
Operation Enabled
```

At every step:

1. Evaluate the current Statusword.
2. Determine the current CiA 402 state.
3. Send the appropriate Controlword command.
4. Wait for feedback confirming the new state.
5. Stop the sequence if a fault or timeout occurs.

This feedback-driven approach is more robust than sending a fixed series of Controlword values with arbitrary delays.

## 7. Validate Feedback Scaling

Different feedback systems can expose different counts per revolution or engineering-unit conversions.

Before automatic movement, verify:

- Counts per revolution
- Velocity conversion
- Sign/direction
- Gear ratio, if applicable
- Position units

The objective is that a common engineering command produces comparable physical behavior across axes even when their feedback hardware differs.

A scaling error can appear as a control problem even when EtherCAT and the drive state machine are functioning correctly.

## 8. First Controlled Motion

The first powered movement should use conservative limits.

Recommended sequence:

```text
Reset faults
    ↓
Enable axis
    ↓
Apply low speed
    ↓
Observe actual velocity and position
    ↓
Stop axis
    ↓
Verify repeatability
```

During this stage, monitor:

- Statusword
- Actual velocity
- Actual position
- Following error, where applicable
- Drive fault status
- EtherCAT errors
- Task-cycle timing

## 9. Expand from One Axis to Multiple Axes

A scalable commissioning strategy is:

```text
1 axis → small axis group → full system
```

Do not immediately enable every drive after proving only one axis.

At each expansion step verify:

- Every axis remains in the expected operating mode.
- All drives remain `Operation Enabled`.
- Network communication remains stable.
- Task runtime remains within the cycle budget.
- Motion scaling is consistent between axes.

This method makes it easier to identify whether a new problem is related to a specific drive, configuration, or system load.

## 10. Real-Time Validation

A motion system can move correctly and still have poor real-time behavior.

For deterministic EtherCAT control, record metrics such as:

- Nominal task period
- Average cycle time
- Minimum and maximum cycle time
- Peak-to-peak jitter
- Maximum task runtime
- EtherCAT cycle errors

The portfolio's dedicated [performance-testing](performance-testing.md) page documents the methodology used to evaluate these metrics.

## Commissioning Decision Tree

```text
Device detected?
 ├─ No  → physical link / topology / device identity
 └─ Yes
      ↓
EtherCAT OP?
 ├─ No  → startup parameters / PDO / synchronization / WKC
 └─ Yes
      ↓
Process data valid?
 ├─ No  → mapping / data type / byte order
 └─ Yes
      ↓
Correct mode confirmed?
 ├─ No  → mode configuration / startup sequence
 └─ Yes
      ↓
Operation Enabled?
 ├─ No  → CiA 402 state / fault / brake / interlock
 └─ Yes
      ↓
Feedback correctly scaled?
 ├─ No  → encoder/resolver scaling
 └─ Yes
      ↓
Low-speed motion test
      ↓
Multi-axis validation
      ↓
Real-time performance test
```

## Engineering Takeaway

The most important commissioning principle is to validate the system **layer by layer**. EtherCAT communication, CiA 402 state handling, feedback scaling, motion commands, and real-time performance should each be proven independently.

This approach turns commissioning from trial-and-error into a repeatable engineering process and provides clear evidence for root-cause analysis when a system does not behave as expected.

---

**Portfolio note:** This document describes a generalized engineering methodology based on practical motion-control work. Product-specific confidential implementation details and proprietary source code are intentionally excluded.
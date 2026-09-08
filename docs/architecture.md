# System Architecture

This document describes the high-level architecture used for the PLCopen motion-control work documented in this repository.

> This portfolio documentation intentionally avoids proprietary source code, internal network information, customer data, credentials, and confidential company-specific implementation details.

## Overview

The project is centered around a modular motion-control architecture for EtherCAT servo systems using PLCopen-style function blocks and CiA 402 drive-state handling.

Typical control flow:

```text
Application / State Machine
        ↓
PLCopen Motion Function Blocks
        ↓
Axis Abstraction Layer
        ↓
CiA 402 State Handling
        ↓
EtherCAT Process Data
        ↓
Servo Drive
        ↓
Motor / Mechanical Axis
```

## Main Functional Layers

### 1. Application Layer

The application layer defines the required machine behavior and decides which motion command should be active.

Typical commands include:

- Power / enable axis
- Reset drive faults
- Homing
- Velocity motion
- Absolute positioning
- Additive positioning
- Controlled stopping

The application should not directly manipulate low-level EtherCAT control words or drive-specific state transitions.

### 2. PLCopen Motion Layer

The PLCopen-style function blocks provide a reusable interface between machine logic and the axis-control layer.

Typical function blocks include:

- `MC_Power`
- `MC_Reset`
- `MC_Stop`
- `MC_Home`
- `MC_MoveVelocity`
- `MC_MoveAbsolute`
- `MC_MoveAdditive`
- `MC_MoveContinuousAbsolute`

Each function block is designed around clear command, status, busy, done, aborted, and error behavior.

## 3. Axis Abstraction

The axis abstraction separates generic motion logic from the details of the physical drive.

The application works with an axis reference instead of directly writing device-specific process-data objects.

This makes the motion logic easier to maintain and reuse across multiple axes.

## 4. CiA 402 State Handling

The servo drive is controlled according to the CiA 402 state machine.

Typical drive states include:

```text
Switch On Disabled
        ↓
Ready to Switch On
        ↓
Switched On
        ↓
Operation Enabled
```

The control logic evaluates the drive status word and generates the required control word sequence.

Fault handling and reset behavior are integrated into this layer.

## 5. EtherCAT Communication

EtherCAT provides deterministic cyclic communication between the controller and the servo drives.

The cyclic process data typically carries values such as:

- Control word
- Status word
- Operating mode
- Target velocity or target position
- Actual velocity
- Actual position
- Drive status and diagnostic information

For high-performance motion applications, the communication cycle and PLC task cycle must be configured consistently.

## Multi-Axis Operation

The architecture is intended to scale from a single axis to multiple axes without duplicating application logic.

A typical multi-axis system uses one axis instance per drive while keeping the same reusable motion function blocks.

Example:

```text
Controller
   │
   ├── Axis 1 → Servo Drive 1 → Motor 1
   ├── Axis 2 → Servo Drive 2 → Motor 2
   ├── Axis 3 → Servo Drive 3 → Motor 3
   └── ...
```

## Design Goals

The architecture was developed with the following engineering goals:

- Modular motion-control software
- Reusable PLCopen-style function blocks
- Clear separation between application logic and drive communication
- Predictable CiA 402 state transitions
- Multi-axis scalability
- Easier commissioning and troubleshooting
- Deterministic EtherCAT execution
- Maintainable code structure

## Practical Engineering Focus

The project is not only about implementing motion commands. A large part of real motion-control work involves commissioning, diagnosis, drive-state analysis, EtherCAT topology checks, process-data validation, and timing verification.

For examples of problems encountered during commissioning, see [Troubleshooting](troubleshooting.md).

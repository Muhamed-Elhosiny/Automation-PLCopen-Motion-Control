# 21 — Motion-Profile Cycle Time and Observed Servo Vibration

## Context
A multi-axis EtherCAT servo test system used a PLC-side velocity-profile generator to produce position/velocity trajectory commands. The profile accepted start and target positions, velocity, acceleration, deceleration and a configured cycle time. Motion was evaluated during commissioning with a cyclic control task.

## Symptom
Noticeable vibration occurred during motion with the profile generator configured for a 1 ms calculation interval. A 10 ms interval was subsequently evaluated to reduce the observed vibration.

## Evidence
- The trajectory generator exposed a `CycleTime` parameter, initially configured to 1 ms.
- The setting was changed to 10 ms during motion tuning, with reduced vibration reported.
- No synchronized drive trace, spectral measurement, following-error record or controlled A/B test is available here to quantify the change.

## Investigation
The engineering investigation considered the relationship between profile-update interval, PLC execution interval, command increments and drive response. A slower profile update can change command step sizes and frequency content; it does not automatically improve motion quality. The actual EtherCAT cycle, PLC task period and drive interpolation behavior must be measured independently rather than inferred from the profile parameter.

## Root Cause or Engineering Conclusion
**Confirmed observation:** the 10 ms profile setting was associated with reduced vibration in this test setup.

**Not confirmed:** whether vibration originated from profile discretization, task/fieldbus timing mismatch, scaling, mechanical resonance, drive tuning or another source. Changing the profile interval is a tuning observation, not proof of root cause.

## Resolution
The profile calculation interval was adjusted from 1 ms to 10 ms as a commissioning mitigation. This is not a universal recommended setting and must be validated against the required motion bandwidth, accuracy and stopping behavior.

## Verification
The reported improvement was qualitative. A repeatable verification campaign should record, under equivalent loads and moves:
1. Actual PLC task period and EtherCAT cycle time, including jitter.
2. Generated target-position and target-velocity sequences, with timestamps.
3. Drive actual position/velocity, following error and torque where available.
4. Peak/RMS vibration or a comparable measured motion-quality metric.
5. Stop distance, endpoint error and behavior at direction reversal.

Compare multiple runs at both intervals with the same scaling, gains, mechanics and trajectory limits. Do not claim a validated optimum without these measurements.

## Engineering Lessons
- Keep trajectory calculation period, task scheduling period and EtherCAT exchange period conceptually separate.
- A reduction in visible vibration after a parameter change establishes correlation, not a confirmed mechanism.
- Check the physical effect of command quantization and drive interpolation before accepting a slower update rate.
- Record motion quality alongside following error and safety-relevant stopping behavior; smoother appearance alone is insufficient acceptance evidence.

## Confidentiality
This case intentionally excludes proprietary source code, internal network details, customer information and unpublished vendor internals.

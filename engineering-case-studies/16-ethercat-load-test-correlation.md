# Case 16 — Distinguishing EtherCAT Timing Outliers from Communication Breakdown

## Context

A 12-axis EtherCAT motion system was evaluated under CPU stress while cyclic control and EtherCAT communication were both configured around a 1 ms timing target. Two different observations appeared during testing:

- occasional cycle-time outliers in timing measurements, and
- reproducible EtherCAT communication breakdowns at higher externally generated CPU load.

Because both phenomena appeared in timing-sensitive tests, it was necessary to determine whether they represented the same failure mechanism.

## Symptom

At higher external CPU-load levels, the system could develop a sequence of communication errors that ended with multiple axes stopping. Separately, timing measurements could show individual cycle-time excursions without an immediate EtherCAT failure.

Treating every timing outlier as the direct cause of the communication breakdown would have been an unsupported conclusion.

## Evidence

The stress-test evidence showed two distinct levels of observation:

### Timing observation

Cycle-time measurements could contain isolated excursions from the nominal period. An outlier by itself described a scheduling/timing deviation, but did not prove that an EtherCAT frame was lost or that a slave left OP.

### Communication-failure observation

During reproducible high-load failures, the diagnostic sequence included multiple communication-level symptoms such as:

- frame receive or busy timeouts,
- mailbox retry exhaustion,
- slave state degradation from OP toward SAFE-OP,
- AL status errors,
- emergency/error activity,
- coordinated loss of motion across the multi-axis system.

The externally generated CPU load was also a significant variable: comparable application-side computational loading did not automatically reproduce the same failure behavior.

## Investigation

The investigation separated **correlation** from **causation**.

Instead of asking only whether a timing outlier existed, the diagnostic workflow correlated events by timestamp:

```text
CPU / scheduler pressure
        |
        v
PLC and EtherCAT timing measurements
        |
        v
Frame / mailbox diagnostics
        |
        v
Actual EtherCAT slave states
        |
        v
Motion-system response
```

For each test run, the important question was whether a measured timing excursion occurred at the same time as the first communication error and whether the same sequence repeated across multiple runs.

The following cases were therefore distinguished:

1. **Timing outlier without communication errors** — evidence of timing jitter, not proof of EtherCAT breakdown.
2. **Communication errors without sufficient timing evidence** — a confirmed communication problem whose scheduling trigger still required investigation.
3. **Repeated timestamp correlation between timing degradation and communication errors** — evidence supporting a relationship, but still requiring care before claiming a single root cause.

## Engineering Conclusion

The timing outliers and the EtherCAT communication breakdown should not be documented as automatically identical problems.

They can be related because both may originate from insufficient real-time scheduling margin or resource contention, but an isolated cycle-time excursion is not equivalent to an EtherCAT failure. The communication breakdown is defined by fieldbus-level evidence: missed or delayed communication, retries/timeouts, state transitions, and resulting loss of motion.

The strongest supported conclusion is therefore that timing degradation is a **potential contributing indicator** that must be correlated with EtherCAT diagnostics. It is not, by itself, proof of the root cause.

## Resolution / Diagnostic Strategy

A repeatable test procedure was established around synchronized evidence collection:

1. Keep the motion workload and EtherCAT configuration constant.
2. Apply controlled CPU-load levels.
3. Record PLC task timing and EtherCAT timing metrics.
4. Capture system and EtherCAT logs using the same test window.
5. Record the first frame/mailbox error and the first slave state transition.
6. Compare successful and failing runs.
7. Repeat the same load point to determine reproducibility.
8. Classify timing excursions separately from communication failures unless timestamp evidence links them.

This prevents a visually obvious timing spike from being promoted prematurely to a confirmed root cause.

## Verification

A relationship between timing degradation and EtherCAT failure should be considered strong only when repeated tests show the same ordered sequence under comparable conditions.

Negative evidence is equally important. Runs that contain timing excursions but continue operating correctly demonstrate that the excursion alone is insufficient to explain the failure.

## Engineering Lessons

- Real-time troubleshooting requires timestamp correlation across multiple diagnostic layers.
- A cycle-time outlier is a measurement symptom; an EtherCAT breakdown is a communication-system failure state.
- Correlation should be demonstrated across repeated tests before a causal statement is made.
- Negative test results are valuable because they eliminate overly broad hypotheses.
- External CPU stress and application-generated computation can affect scheduler behavior differently and should be tested separately.
- Root-cause reports should clearly label confirmed facts, contributing indicators, and unresolved hypotheses.

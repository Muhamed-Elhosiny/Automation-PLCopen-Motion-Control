# 19 — Debugger-Attach Timing Outlier in PLC Cycle-Time Measurements

## Context
A multi-axis EtherCAT motion-control test system was evaluated using cyclic PLC tasks and application-level timing instrumentation. Measurements included PLC cycle intervals and execution-time statistics, with task periods of 1 ms and 500 µs evaluated in separate runs.

## Symptom
A very large one-time timing excursion appeared when online debugging was attached. The observed diagnostic peak was approximately 716–720 ms, far beyond the nominal task period. An application statistics function block did not retain the same maximum in the reviewed measurement sequence.

## Evidence
- The large excursion coincided with the start of online debugging.
- A PLC diagnostic view displayed the transient peak.
- The application-level maximum did not capture it in the compared statistics after a reset/restart sequence.
- In stable measurement windows, the 1 ms task average was approximately 999.7 µs.

These observations establish a measurement-context discrepancy; they do not establish a recurring runtime overrun under normal unattended operation.

## Investigation
1. Compared the PLC diagnostic timing display with the application statistics block.
2. Identified when online debugging began relative to the anomalous sample.
3. Reviewed whether the statistics block had been reset or restarted before the maximum could be retained.
4. Separated startup/debugger-attachment measurements from steady-state timing data.
5. Kept cyclic-task timing and EtherCAT communication failures as separate diagnostic questions unless correlated by timestamps and fieldbus evidence.

## Root Cause or Engineering Conclusion
**Confirmed observation:** the exceptional timing sample occurred at debugger attachment, and the two measurement views did not retain the same maximum.

**Engineering conclusion:** measurement-window boundaries, instrumentation lifecycle, and debugger activity can materially affect reported timing extrema. A reset/restart is a plausible explanation for a missing recorded maximum, but the exact internal cause of the discrepancy was not independently proven. The observation alone does not prove a production-runtime scheduling defect or an EtherCAT frame loss.

## Resolution
For performance comparisons, established a measurement procedure that separates startup and debugger-attachment transients from steady-state windows. Record both diagnostic maxima and application statistics with explicit reset points, task periods, and measurement start/end conditions. Preserve anomalous samples as separate findings rather than deleting them.

## Verification
Stable 1 ms measurements were subsequently evaluated using averages near the configured period. The isolated debugger-associated excursion was excluded from steady-state comparative averages while retained as a documented diagnostic artifact. No claim is made that a controller or runtime defect was fixed.

## Engineering Lessons
- Define the measurement window before comparing controller performance.
- Log when instrumentation is reset; a maximum is only meaningful over its actual observation interval.
- Treat online debugger attachment as a possible perturbation to real-time measurements.
- Compare independent diagnostic sources before concluding that a spike is absent or resolved.
- Do not equate a timing outlier with EtherCAT communication failure without frame, state-transition, and motion-response evidence.
- Report both steady-state statistics and exceptional events, with their operating context.

## Confidentiality
Controller identifiers, network addresses, proprietary application code, and unpublished implementation details are intentionally omitted.

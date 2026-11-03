# Comparative EtherCAT Controller Performance — Measurement and Interpretation

## Engineering Context

A twelve-axis EtherCAT servo test stand was used to compare three industrial controller CPU variants under cyclic motion workload. The objective was to distinguish PLC task scheduling behavior from EtherCAT processing cost, rather than infer overall controller capability from a single CPU-utilization figure.

The test setup used twelve servo axes operating in cyclic synchronous velocity mode (CiA 402 mode 9), with a separate EtherCAT I/O coupler. Measurements were taken at nominal PLC task periods of **1 ms** and **500 µs**. These are test-stand observations, not production-system qualification results.

## Measurement Architecture

The evaluation separated three measurement domains:

| Domain | What was measured | Interpretation boundary |
| --- | --- | --- |
| PLC task cycle | Actual interval between task activations; average and extrema | Includes scheduling and runtime effects; not equivalent to application execution time |
| Application code section | Timed portion of the PLC application using a dedicated timer | Measures only the instrumented region |
| EtherCAT cyclic processing | EtherCAT task processing time reported by diagnostics | Not interchangeable with full PLC cycle time or end-to-end drive response |

Measurements were recorded after initialization and statistics reset, with stable operating windows distinguished from startup and debugger-attachment transients. An observed debugger-attachment outlier of approximately **716–720 ms** was excluded from steady-state comparisons and documented separately in [Case Study 19](../engineering-case-studies/19-debugger-attach-timing-measurement.md).

## Test Procedure

1. Keep the EtherCAT topology, axis count, motion mode, and application workload equivalent between controller variants.
2. Run the same measurement sequence at **1 ms** and **500 µs** task periods.
3. Record PLC cycle timing, timed code-section execution, and EtherCAT cyclic processing separately.
4. Reset measurement statistics before the steady-state observation window; document any tool attachment or startup activity.
5. Compare **absolute processing time** before reporting relative percentage differences.
6. Repeat runs when task load, communication state, or debugger behavior changes. Never compare samples from different operating conditions as though they were equivalent.

## Observed Results

Across the evaluated controllers, the **500 µs task-period averages were close to the configured 500 µs**. The measured EtherCAT processing-time ordering was:

**CPS0419 (lowest) → CPS0415 → CPS0212 (highest).**

In the recorded comparison, the reported relative EtherCAT processing-time advantages were approximately:

- **CPS0419 vs. CPS0212:** 42.6% lower processing time.
- **CPS0415 vs. CPS0212:** 24.4% lower processing time.
- **CPS0419 vs. CPS0415:** 24.1% lower processing time.

These percentages summarize one controlled test configuration; they are **not** general CPU benchmarks or guarantees for other topologies, task loads, or software versions. The underlying absolute values and measurement-window definitions should accompany any external quantitative performance claim.

## Engineering Conclusions and Limitations

**Supported conclusion:** Under the recorded twelve-axis EtherCAT test conditions, the CPS0419 showed the lowest EtherCAT cyclic processing time of the three evaluated CPU variants.

**Not established:** The comparison alone does not prove deterministic worst-case latency, maximum supported axis count, or fault-free operation at elevated system load. Average cycle timing near its configured period does not rule out rare deadline misses.

**Important distinction:** Separate high-load experiments reproduced EtherCAT communication failures with receive/busy timeouts and slaves leaving OP state. Those failure observations must not be attributed solely to the relative processing-time ranking; see [Case Study 03](../engineering-case-studies/03-cpu-load-frame-timeout.md) and [Case Study 16](../engineering-case-studies/16-ethercat-load-test-correlation.md).

## Reporting Checklist

For an auditable controller comparison, report the controller variant, runtime/software version where publishable, number of EtherCAT devices, motion mode, configured task period, load conditions, instrumentation, measurement window, sample count, absolute minimum/average/maximum times, and any excluded outliers with their exclusion rationale.

Keep task-cycle jitter, application execution time, EtherCAT processing time, and communication integrity as **separate acceptance criteria**. A faster average processing time is useful evidence of headroom, but cannot replace a worst-case timing and stability assessment.

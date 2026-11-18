# Real-Time Controller Performance Comparison — 12-Axis EtherCAT Test System

## Scope

A comparative engineering assessment of three controller variants (CPS0419, CPS0415 and CPS0212) using a common 12-axis EtherCAT motion test system. The purpose was to separate PLC task-period accuracy from the processor time consumed by EtherCAT processing and to assess the effect of a shorter cycle period.

This is a bounded test-system comparison, not a production qualification or an assertion of vendor-wide performance.

## Test configuration

| Dimension | Recorded configuration |
| --- | --- |
| EtherCAT network | 12 servo axes and an I/O coupler |
| Drive operating mode | CiA 402 cyclic synchronous velocity (CSV, mode 9) |
| Controller variants | CPS0419, CPS0415, CPS0212 |
| PLC task periods | 1 ms and 500 µs |
| Motion workload | Repeated velocity/position motion sequences |
| Observables | Task-cycle statistics, EtherCAT processing CPU time, communication state and diagnostics |

For a defensible comparison, preserve identical topology, application workload, task configuration, instrumentation and measurement windows across controller variants. Record differences explicitly rather than treating unmatched runs as directly comparable.

## Recorded findings

- At the **1 ms** task setting, observed mean task-cycle durations were approximately **999.72–999.73 µs** in the recorded runs. This describes period tracking; it is **not** EtherCAT execution time.
- At the **500 µs** task setting, mean cycle durations were close to **500 µs** across all three variants.
- The observed ordering of EtherCAT processing CPU time was **CPS0419 (lowest), CPS0415, CPS0212 (highest)**.
- A prior comparison summary reported CPS0419 approximately **42.6% faster than CPS0212**, CPS0415 approximately **24.4% faster than CPS0212**, and CPS0419 approximately **24.1% faster than CPS0415**, for the compared processing-time metric. These are **test-specific relative comparisons**, not CPU benchmark scores. The raw per-run samples and calculation baseline should accompany any external quantitative performance claim.
- Attaching an online debugger coincided with an isolated task-timing outlier around **716–720 ms** in a separate measurement. That observation must not be silently merged into steady-state timing statistics.

## Interpretation and engineering judgment

**Cycle period and execution cost are different quantities.** A task can maintain a mean period near its nominal setpoint while the EtherCAT portion consumes substantially different CPU time across controllers. Averages also conceal deadline misses and rare latency spikes.

**Lower processing time is not sufficient to certify stability.** In separate load tests, communication timeouts and OP-to-SAFEOP transitions occurred under combined CPU loading and motion. The causal mechanism was not conclusively isolated; the comparison above must not be represented as proof that any controller passes worst-case communication stability requirements.

**Debugger-induced disturbances require separate labeling.** Instrumentation can affect the system under test. Record the attach time, distinguish startup/transient observations from steady-state windows, and retain both datasets.

## Reproducible validation protocol

1. Freeze the EtherCAT topology, drive configuration, task periods, motion commands and application revision.
2. For each controller and period, capture the same measurement duration, warm-up policy and load conditions.
3. Export per-cycle task duration and EtherCAT execution-time samples; report median, mean, maximum, p99/p99.9 and missed-deadline count.
4. Log debugger attach/detach, communication warnings, EtherCAT slave-state transitions and any external load generator activity with aligned timestamps.
5. Repeat each run to estimate variability. Do not infer statistical confidence from a single screenshot or a single short run.
6. Compute speed differences using an explicitly stated denominator: for execution-time reduction, `(reference_time - candidate_time) / reference_time × 100%`. Do not conflate time reduction with throughput increase.
7. Mark each controller/period/load combination **pass**, **fail**, or **not yet verified** against predefined timing and communication criteria.

## Evidence boundaries

The reported ordering and approximate relative figures reflect recorded engineering observations. Complete raw timing distributions, replicate counts and a final worst-case acceptance decision are not available in this portfolio document. No production deployment, root-cause closure, or validated universal performance advantage is claimed.

## Engineering lessons

- Compare the measured **execution-time metric**, not just the configured task period.
- Preserve workload equivalence and raw data before publishing relative performance numbers.
- Treat debugger activity and external CPU loading as controlled experimental variables.
- Couple performance evaluation with EtherCAT communication integrity and deadline evidence.
- State what was measured, what remains unverified, and which acceptance decision the evidence can actually support.

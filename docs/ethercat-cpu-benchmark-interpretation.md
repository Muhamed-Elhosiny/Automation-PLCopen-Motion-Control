# EtherCAT Controller CPU Benchmark — Interpreting Relative Performance

## Scope

This engineering note describes how to interpret comparative CPU measurements from a multi-axis EtherCAT motion-control test system. The test setup used 12 servo axes in Cyclic Synchronous Velocity (CSV) mode, with cyclic and event-triggered task configurations investigated separately. The observations are from a validation setup, not a production qualification.

## Recorded relative results

A comparative test summary reported:

| Comparison | Reported relative advantage |
| --- | ---: |
| Controller A versus Controller C | 42.6% |
| Controller B versus Controller C | 24.4% |
| Controller A versus Controller B | 24.1% |

These are **reported comparative performance figures**, not independently reproduced throughput measurements. The original definition of the performance metric and its denominator must be retained before translating these percentages into execution times or capacity estimates. In particular, percentage improvements cannot be chained or treated as interchangeable with reductions in CPU utilization.

## Experimental context

- Twelve servo axes operated over EtherCAT in CSV mode.
- Cyclic configurations included 1 ms and 10 ms task periods; a 500 µs scenario was also investigated.
- CPU load was increased while motion and EtherCAT communication were active.
- Separate timing measurements indicated nominal average task periods near their configured values; occasional extreme outliers required event correlation.
- Under elevated load, communication timeouts and EtherCAT state degradation were observed. This establishes a system-level failure mode, **not** a proven CPU-model-specific limit.

## Interpretation constraints

1. **Keep workload constant.** Compare the same axis count, PDO payload, motion logic, network topology, task period, and background load.
2. **Define the metric.** A faster execution time, higher available CPU headroom, and lower utilization are different quantities.
3. **Separate normal timing from tails.** Average cycle period alone does not characterize worst-case latency or EtherCAT deadline misses.
4. **Account for measurement intrusion.** Debugger attachment was associated with a one-time large timing spike in the wider test campaign; exclude or annotate such intervals rather than silently averaging them.
5. **Correlate failures.** Align task timing, load, frame receive/busy timeouts, mailbox retries, and slave state transitions on a common timeline.
6. **Avoid a false threshold.** Observed breakdowns at different imposed load levels do not establish a universal safe operating limit without repeatability and controlled configuration.

## Recommended reproducibility record

For each controller, record firmware/runtime version, CPU model, task type and priority, cycle period, axis count, process-data size, load-generation method, sampling duration, timing instrumentation, CPU-utilization definition, mean and high-percentile execution time, maximum observed latency, communication error counts, and final slave states. Repeat trials and retain raw logs before claiming statistical significance.

## Engineering conclusion

The comparative results support a **relative ranking within the recorded test configuration**, but do not by themselves prove a production-safe axis capacity, a deterministic maximum load, or an EtherCAT deadline guarantee. Controller selection should be based on reproducible workload-matched timing and communication stability, with sufficient headroom for abnormal conditions.

## Confidentiality and provenance

Controller identifiers are generalized here. No proprietary source, private network details, customer identifiers, or unpublished vendor implementation details are included. Numerical comparisons are retained as previously recorded test-summary observations; the underlying raw benchmark dataset is not included in this repository.

# Multi-Axis EtherCAT Commissioning Acceptance Matrix

## Purpose

A repeatable acceptance protocol for a twelve-axis EtherCAT motion-control test system. It separates configuration correctness, drive readiness, commanded motion, and sustained cyclic communication. Passing one stage does **not** establish that later stages are healthy.

This is a verification template informed by multi-axis commissioning and stress-testing observations; it is **not** a claim that every acceptance criterion below has already passed.

## Test configuration record

Capture before each run:

| Field | Record |
| --- | --- |
| Controller model and software release | |
| EtherCAT master release and configuration revision | |
| Number of expected / discovered / operational slaves | |
| Drive operating mode (0x6060 requested; 0x6061 displayed) | |
| PDO mapping and engineering-unit scaling revision | |
| EtherCAT cycle time and PLC task period | |
| Distributed Clock synchronization status | |
| CPU load source and measured utilization | |
| Test duration and operator | |

Do not publish internal network addresses, serial numbers, credentials, customer identifiers, or proprietary configuration exports.

## Acceptance gates

| Gate | Procedure | Required evidence | Pass criterion |
| --- | --- | --- | --- |
| 1. Topology | Compare configured and discovered slave order/count; inspect identities | Slave inventory, identity readback, configuration revision | No unexplained mismatch |
| 2. State transition | Bring network to OP; observe every slave individually | Timestamped state and AL status | All intended slaves remain OP |
| 3. Drive mode | Write intended mode, then read 0x6061 | Requested and displayed mode per axis | Mode display matches request |
| 4. CiA 402 readiness | Execute switch-on and enable sequence | Statusword transitions and fault bits | Each axis reaches Operation Enabled without persistent fault |
| 5. Motion feedback | Command a bounded, safe movement per axis | Setpoint, actual position/velocity, statusword | Feedback responds with expected direction and scaling; no unexpected motion |
| 6. Simultaneous operation | Run the defined multi-axis motion profile | Per-axis feedback, task timing, EtherCAT state | No unexpected axis stop or state loss |
| 7. Timing | Measure PLC task period, code execution and EtherCAT processing separately | Average, extrema, observation window, measurement reset points | Values assessed against **project-specific** timing limits |
| 8. Load and recovery | Repeat under documented load levels; recover after any fault | CPU-load trace, timeout sequence, AL code, recovery steps | Failure/recovery characterized; stability claimed only for tested conditions |

## Execution discipline

1. Establish a known-safe state, working emergency stop, appropriate mechanical clearance and conservative motion limits before enabling drives.
2. Run gates in order. Record **fail**, **pass**, or **not tested** for every axis; do not infer all-axis success from one representative drive.
3. Keep PLC task period, EtherCAT bus cycle and measured execution time as distinct quantities. Record the timing source and measurement window.
4. During load tests, correlate controller load, frame receive/busy timeouts, mailbox retries, slave state transitions and motion feedback by timestamp.
5. Treat a command block's `Done` output as command completion **unless** its documented contract explicitly guarantees the requested physical state. Confirm the state through independent feedback.
6. Exclude debugger-attach and startup transients from *steady-state summaries* only when they are separately recorded and explicitly labeled; never erase them from the evidence.
7. When changing scheduling priority or another mitigation, repeat the same baseline and load profile. A mitigation that does not prevent recurrence is not a verified fix.

## Results and disposition

For each test run, preserve a short record:

| Run ID | Gates completed | Conditions | Observed deviations | Evidence reference | Disposition |
| --- | --- | --- | --- | --- | --- |
| _Template_ | _1–8_ | _Cycle / load / duration_ | _Faults and timing_ | _Sanitized log or chart_ | _Pass / fail / inconclusive_ |

A pass is valid only for the recorded hardware, software, operating conditions and duration. If a load-induced communication breakdown occurs, report it as a **failed stress condition**, not as a successful acceptance run.

## Engineering interpretation

In a twelve-axis validation setup, repeated frame timeouts and simultaneous OP-to-SAFEOP transitions were observed during combined motion and generated CPU load. The observed association supports a load-sensitive communication failure, but **does not independently prove a single scheduler-level root cause**. A scheduling-policy adjustment was tested without eliminating recurrence. Document the unsuccessful mitigation and keep the underlying cause open pending further evidence.

Related reading: [EtherCAT load-related communication case](../engineering-case-studies/03-cpu-load-frame-timeout.md), [state feedback semantics](../engineering-case-studies/13-ethercat-state-feedback-semantics.md), [timing outlier case](../engineering-case-studies/19-debugger-attach-timing-measurement.md), and [controller performance comparison](multi-controller-ethercat-performance-comparison.md).

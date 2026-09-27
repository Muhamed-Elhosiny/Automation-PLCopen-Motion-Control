# Case 07 — 24 V Supply Collapse When Controller Was Connected

## Context

A 24 VDC power supply showed the expected output voltage when unloaded. When an industrial controller was connected, the controller repeatedly powered on and off and the supply voltage dropped.

## Symptom

- Correct voltage with no load connected.
- Voltage collapse when the controller was attached.
- Controller LEDs cycled on and off instead of remaining stable.

## Investigation

The key diagnostic step was to compare **open-circuit voltage** with **voltage under load**.

A supply that measures 24 V with no load is not automatically healthy. The next questions are:

1. Does the supply maintain 24 V under the expected current draw?
2. Is current limiting or overload protection activating?
3. Is there a short circuit, wiring fault, reversed polarity, or excessive downstream load?
4. Is the supply correctly rated for the controller and attached modules?
5. Does the voltage recover immediately after the load is disconnected?

In this case, the voltage returned to normal after disconnecting the controller, making the load-dependent behavior the important observation.

## Engineering Conclusion

The failure pattern was consistent with the supply entering current limiting / protection or with an excessive load or fault on the connected circuit. The no-load voltage measurement alone could not prove that the supply was capable of delivering the required power.

## Resolution Strategy

The correct troubleshooting path was to avoid replacing random components and instead isolate the load step by step:

```text
Verify polarity and wiring
        |
        v
Measure supply under load
        |
        v
Disconnect downstream modules/loads
        |
        v
Reconnect incrementally
        |
        v
Identify the point at which voltage collapses
```

The supply current rating and downstream power demand should then be compared before returning the system to operation.

## Verification

A healthy result requires the supply to maintain the expected voltage while the controller remains continuously powered, without repetitive startup/reset behavior.

## Engineering Lessons

- No-load voltage is only one part of power-supply diagnosis.
- Load testing is essential when a controller repeatedly boots and resets.
- Current limiting can look like a software boot problem because the controller repeatedly starts and loses power.
- Power faults should be ruled out before spending time debugging higher-level software or fieldbus behavior.

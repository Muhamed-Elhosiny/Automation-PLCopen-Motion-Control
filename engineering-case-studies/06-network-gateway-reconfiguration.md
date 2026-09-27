# Case 06 — Industrial Controller Network/Gateway Reconfiguration

## Context

An industrial controller had to be moved from one network environment to another while remaining reachable for engineering access. The IP address, subnet, DNS configuration, and default gateway had to be aligned with the target network.

## Symptom

The controller could be assigned a static IP address, but communication outside the local subnet failed until the correct gateway was configured. Entering network values only through the engineering UI did not initially produce the expected result.

## Investigation

The network configuration was inspected directly on the controller instead of relying only on the graphical interface.

The workflow was:

1. Export the current network configuration.
2. Verify whether DHCP was enabled or disabled.
3. Confirm the interface address and prefix length.
4. Confirm DNS settings.
5. Confirm the configured default gateway.
6. Apply the corrected configuration.
7. Export the configuration again to verify what the controller had actually stored.

A key point was that a gateway cannot be chosen arbitrarily. It must be reachable on the local Layer-3 network and correspond to the router that forwards traffic outside the subnet.

## Root Cause

The controller had an incomplete or incorrect Layer-3 network configuration for the new environment. A valid local IP address alone was not sufficient for routed communication.

## Resolution

The interface was configured with the correct static address, subnet, DNS information, and network-provided gateway. The effective configuration was verified from the controller after applying the changes.

## Verification

Verification included:

- successful access from the engineering workstation,
- confirmation of the stored interface configuration,
- successful routed communication after the gateway correction.

## Engineering Lessons

- A static IP address and a default gateway solve different problems.
- The gateway must belong to the actual network design; inventing an unused address does not create a router.
- When a UI behaves unexpectedly, inspecting the effective configuration at the operating-system level can separate a presentation/configuration issue from a networking issue.
- Always re-read the final configuration after applying network changes.

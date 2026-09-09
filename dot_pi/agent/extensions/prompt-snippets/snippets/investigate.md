---
name: Investigate
description: Force investigation mode — load debug skill, delegate multi-target evidence gathering to investigator subagents
placement: prepend
order: 20
---
This is an investigation. Load the `debug` skill and follow it. If more than one independent target or lead exists (multiple services, pods, hosts, environments, or plausible-but-unrelated causes), dispatch one `investigator` sub-agent per target/lead in this same turn before running any diagnostic command yourself — do not investigate serially. Collect all results before forming a hypothesis.

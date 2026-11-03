# Validation plan

## Stage 0: Synthetic smoke test

Run `buildtool test` and `buildtool demo` in MATLAB. Static GitHub checks do not replace these tests.

## Stage 1: ENV1 calibration/development

Use `configs/env1.json` with the archival repo checked out beside OceanScope. Compare numeric interpolated grids and selected images with the legacy longitudinal output; align the depth grid, interpolation, coastal-distance reference and color palettes before claiming equivalence. ENV1 CTD day 7 and nutrient day 1 are currently configured. Import days 1–8 in a later, separate step.

## Stage 2: ENV2 independent validation

Freeze the core functions and provide dataset-specific JSON only. Check expected CTD sampling days (1, 3, 5, 7), nutrient day 1, station spacing and section limits.

## Stage 3: ENV3 independent validation

Repeat without editing core code. Specifically check that day 5 has nine stations, not ten. Missing measurement days should not be inferred or fabricated.

## Scientific acceptance criteria

- Inputs remain byte-for-byte unchanged.
- Numeric columns and units are documented; no silent unit conversions.
- Interpolation grids and sample masks are recorded.
- Floating-point comparisons use defined tolerances.
- Output manifests identify exact source inputs and software release.
- Archive figures are scientifically compared before a stable release is tagged.

The current version **does not meet** all of these scientific acceptance criteria and should remain pre-release.

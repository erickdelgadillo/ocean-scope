# Validation plan

## Stage 0: Synthetic smoke test

Run `buildtool test` and `buildtool demo` in MATLAB. Static GitHub checks do not replace these tests.

## Duplicate-coordinate QC

For every variable, OceanScope groups observations at exactly identical
(distance-from-coast, depth) coordinates **after** excluding non-finite values
and samples outside the configured depth interval. Within each duplicate group,
the arithmetic mean is used for interpolation; the original source files are
never modified. The `manifest.json` output entries record input/retained
samples, unique positions, duplicate groups, and duplicate additional samples.
This is not statistical outlier removal, spatial binning, or profile averaging.

ENV1 CTD day 7 contains 1763 rows and 1762 unique raw
(longitude, latitude, depth) coordinates. One repeated point at station 2,
53.569 m has two different measurements. ENV1 nutrient day 1 has
20 records and no repeated raw coordinates. The coordinate transform may
introduce additional coincident interpolation positions: compare the
per-variable manifest counts with these raw counts.

This implementation explicitly matches the arithmetic-mean behavior previously
triggered inside MATLAB `griddata` but **does not establish full numerical
equivalence** with the legacy figures. Review whether averaging is scientifically
appropriate for each variable, particularly turbidity.

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

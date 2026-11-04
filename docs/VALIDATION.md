# ENV1 numerical validation and audit

## Scope and reference

Validated against the **current curated archival MATLAB section workflow**, at
archive commit `a97630b45dba86bd6fec92977f0c60aeb27dca91`, not against pixels or
an independently preserved numeric output from the original publication.
`validation/env1_reference.json` pins SHA-256 hashes of two workbooks and two
reference scripts. Changes require scientific review before rebaselining.
The historical repository is read-only; all outputs go under OceanScope results.

Run `buildtool test` and `buildtool validate` from this repository in MATLAB.
The ENV1 unit test is explicitly incomplete when the adjacent archive is absent;
`buildtool validate` requires the archive and fails if unavailable or changed.
GitHub Actions performs static checks only, not MATLAB validation.

`validation/validate_env1.m` calls the archival geometry function, then separately
extracts the filtering, grid construction and raw `griddata(...,'linear')`
calculation from `generate_longitudinal_sections.m`. It does not call OceanScope
filtering, aggregation, or interpolation for the reference. The five legacy CTD
duplicate warnings are intentional and visible; MATLAB averages those points.
Production OceanScope averages them explicitly before interpolation.

## Audit findings and resolutions

- Historical depth queries start at 5 m; the original OceanScope started at 0 m.
  ENV1 now explicitly selects 5:5:limit via `interpolation`; existing configs
  retain defaults of 0 m start, 5 m step and 60 horizontal positions.
- Historical geometry uses longitude 8.9145 and median finite input latitude.
  OceanScope previously used minimum observed longitude and its first latitude.
  ENV1 now declares the historical origin. The old default remains for backward
  compatibility but **is not a general easternmost/coastal-origin algorithm**.
  Signed east-positive input must use a consistently signed explicit origin.
  This distance is radial great-circle distance, not accumulated track distance.
- Historical interpolation spans minimum/maximum *valid observed* distance,
  even though its plot axes use the complete fixed transect extent. OceanScope
  preserves the interpolation bounds; full-transect plotting remains different.
- A two-distance/two-depth check admitted collinear points. A rank check now
  rejects degenerate interpolation coordinates. Grid dimensions and spacings
  are validated, and unknown interpolation options fail explicitly.
- Calculation was coupled to rendering. `interpolate_section` now returns query
  grids, values, original-row mask, distances, aggregated samples and QC without
  graphics. PNG production uses that same result and exports it as a MAT file.
- Manifests now include resolved configuration, exact MATLAB version, config,
  input and implementation SHA-256 hashes. These identify scientific inputs;
  timestamps and MAT container bytes are not expected to be identical per run.

## Scientific assumptions

Coordinates are in degrees, distances in km, and depth in metres positive down.
No value-unit conversion, outlier removal, clipping, smoothing or extrapolation
is performed. Color limits affect only rendering. Per-variable finite-value and
0 <= depth <= max_depth filtering precedes exact distance/depth duplicate grouping.
The arithmetic mean is applied without rounding or spatial binning. Source data
are untouched. Linear interpolation leaves NaNs outside the convex hull.

ENV1 CTD day 7 has 1763 observations. The 260.77 m observation is excluded;
1762 remain, with one additional duplicate at station 2, depth 53.569 m,
longitude 8.9145, latitude 42. There are 1761 unique interpolation positions.
All seven nutrient variables use all 20 observations with no duplicates.
CTD day 7 and nutrient day 1 are separate sampling events, not coincident profiles.

## Measured results

Local MATLAB R2026a: all 13 MATLAB unit tests passed. ENV1 regression compares
sample masks, transformed distances, query coordinates, finite values and NaN
masks. Absolute value tolerance is 1e-10 in each variable's native units;
coordinate tolerance is 1e-10 km. This is a numerical reproducibility tolerance,
not a claim about measurement uncertainty. NaN masks must agree exactly.

| Variables | Finite cells per variable | Max abs difference | Mean abs difference | RMSE | Differing NaN cells |
| --- | ---: | ---: | ---: | ---: | ---: |
| Temperature, salinity, fluorescence, turbidity, PAR | 2353 | 0 | 0 | 0 | 0 |
| Nitrite, nitrate, ammonium, TIN, phosphate, silicate, chlorophyll-a | 1603 | 0 | 0 | 0 | 0 |

All transformed-distance differences were zero. There are no differing NaN-mask
locations. `results/validation/env1_comparison.json` reports each variable and
lists differences as [row, column, distance_km, depth_m] if present. Separate MAT
files preserve both matrices and masks. Input hashes are checked before and after
validation. The tests also cover a known analytic plane, convex-hull boundaries,
duplicate means, collinearity, missing endpoints, signed origins and invalid grids.

## Remaining limitations and next milestone

This establishes equivalence to the pinned curated algorithm for ENV1 only.
Both paths use MATLAB griddata; this is a regression comparison, not independent
validation of its numerical implementation. A synthetic analytic plane provides
an additional check. Other MATLAB versions may differ within the tolerance.

General QC ranges, units schema, campaign/station metadata validation, complete
configuration schema checks and output-name collision protection remain open.
Rendering still uses parula and observed horizontal limits, not historical jet
and full-transect axes. No pixel equivalence is claimed. Missing coordinates are
filtered rather than imputed; the default observed-minimum origin should not be
used blindly for new transects. Hashing requires the standard MATLAB JVM.

Next: validate ENV2 and ENV3 with configuration changes only, including ENV3 day 5
with nine stations, numerical expectations and input provenance. Do not tag v1.0
until those independent campaigns pass scientific review.

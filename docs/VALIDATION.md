# ENV1–ENV3 numerical validation and audit

## Scope and reference

Validated against the **current curated archival MATLAB section workflow**, at
archive commit `a97630b45dba86bd6fec92977f0c60aeb27dca91`, not against pixels or
an independently preserved numeric output from the original publication.
`validation/env1_reference.json`, `env2_reference.json` and `env3_reference.json`
pin SHA-256 hashes of each campaign’s two workbooks and the two reference scripts. Changes require scientific review before rebaselining.
The historical repository is read-only; all outputs go under OceanScope results.

Run `buildtool test` and `buildtool validateAll` from this repository in MATLAB.
`buildtool validate` retains its ENV1-only behavior.
Campaign unit tests are explicitly incomplete when their adjacent archive is absent;
`buildtool validateAll` requires all three campaigns in the archive and fails if unavailable or changed.
GitHub Actions performs static checks only, not MATLAB validation.

`validation/validate_campaign.m` calls the archival geometry function, then separately
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

The ENV1 baseline passed all 13 original tests on MATLAB R2026a Update 5. ENV1 regression compares
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

## Independent ENV2 and ENV3 campaigns

No production MATLAB files changed from the merged ENV1 milestone (`891492a`).
Only configurations, validation utilities, tests and documentation were extended.
`validate_env1` remains a compatibility wrapper around `validate_campaign`.
Reference filenames, column mappings, limits and query grids are selected from
the archival algorithm independently of the production configuration. Input
hashes must match the configured file and the pinned archival file. References
are never automatically rebaselined on a failed comparison.

| Campaign | CTD workbook / day | Nutrient workbook / day |
| --- | --- | --- |
| ENV2 (spring) | `ctd_env2_d7.xlsx` / 7 | `nuts_env2_d1.xlsx` / 1 |
| ENV3 (summer) | `ctd_env3_d5.xlsx` / 5 | `nuts_env3_d1.xlsx` / 1 |

Files are under the archive's `data/longitudinal/`. Both campaigns also have
additional daily CTD days 1, 3, 5 and 7 under `daily_ctd`; these series were
inventoried but are outside this static-section validation. Selected days are
not temporal or seasonal averages.

CTD mappings are `Longitude`, `Latitude`, `depth`, and `temp`, `sal`, `fluo`,
`turb`, `par`. Nutrients use `lon`, `lat`, `Prof`, and `no2`, `no3`, `nh4`, `TIN`,
`po4`, `sio2`, `Total_Chla`. CTD day and station metadata use `day` and `st`;
nutrients use `day` and `St`. Case is preserved.

Geometry remains a fixed 8.9145 west-positive longitude and median finite input
latitude: 42 degrees for CTD and 42.142 degrees for nutrients. CTD longitude ranges
are 8.9145–9.708 for ENV2 and 8.9145–9.608 for ENV3; nutrient ranges are
8.956–9.608 for both. ENV3 lacks the offshore 9.708 position. The query grid spans
observed valid distances, so its nine-position section does not extrapolate to
the absent endpoint. Both use 60 horizontal query positions and 5 m vertical
spacing starting at 5 m, with limits of 260 m (CTD) and 200 m (nutrients).

| Input | Longitude positions | Observed depth (m) | Original rows | Valid rows per variable | Additional duplicates | Unique positions |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| ENV1 CTD d7 | 10 | 3.968–260.768 | 1763 | 1762 | 1 | 1761 |
| ENV1 nutrients d1 | 4 | 5–175 | 20 | 20 | 0 | 20 |
| ENV2 CTD d7 | 10 | 1.984–263.740 | 1798 | 1790 | 0 | 1790 |
| ENV2 nutrients d1 | 4 | 5–165 | 20 | 20 | 0 | 20 |
| ENV3 CTD d5 | **9** | 3.968–252.841 | 1497 | 1497 | 0 | 1497 |
| ENV3 nutrients d1 | 4 | 5–150 | 20 | 20 | 0 | 20 |

There are no nonfinite coordinate/depth/value rows for the selected variables.
Eight ENV2 CTD rows exceed 260 m; all are excluded by the same documented depth
filter used by the reference. ENV3 excludes no rows. Duplicate group counts are
one for ENV1 CTD and zero for all other inputs. No concentrations, coordinates,
units, duplicate means, interpolation methods or NaN rules were changed.

| Campaign | Variables validated | Finite cells per CTD variable | Finite cells per nutrient variable | Max abs / MAE / RMSE (every variable) | NaN-mask differences |
| --- | ---: | ---: | ---: | --- | ---: |
| ENV1 | 12 | 2353 | 1603 | 0 / 0 / 0 | 0 |
| ENV2 | 12 | 2352 | 1544 | 0 / 0 / 0 | 0 |
| ENV3 | 12 | 2224 | 1466 | 0 / 0 / 0 | 0 |

Distances and query grids also match; there are no differing NaN-mask locations.
Tolerances remain 1e-10 native variable units and 1e-10 km, with exact mask agreement.
The different finite-cell counts reflect different observed domains and depths,
not a forced common coverage. Reports for all 36 comparisons are written to
`results/validation/env{1,2,3}_comparison.json`; numeric arrays remain in MAT files.

On MATLAB R2026a Update 5, all **16 tests passed**, with zero failures or
incomplete tests. The expanded suite checks both independent campaigns, station/day metadata,
expected sample counts and coverage, missing observations, configurable grids,
origins, input preservation, exported matrices and provenance. Existing analytic
plane and duplicate-aggregation tests are retained. Full ENV2 and ENV3 workflows
each export 12 PNGs and 12 MAT files. Input hashes are checked before and after
execution; a separate audit checks all 145 tracked archival files for changes.

## Remaining limitations and next milestone

This establishes equivalence to the pinned curated algorithm for the selected
ENV1–ENV3 static sections.
Both paths use MATLAB griddata; this is a regression comparison, not independent
validation of its numerical implementation. A synthetic analytic plane provides
an additional check. Other MATLAB versions may differ within the tolerance.

General QC ranges, units schema, campaign/station metadata validation, complete
configuration schema checks and output-name collision protection remain open.
Rendering still uses parula and observed horizontal limits, not historical jet
and full-transect axes. No pixel equivalence is claimed. Missing coordinates are
filtered rather than imputed; the default observed-minimum origin should not be
used blindly for new transects. Hashing requires the standard MATLAB JVM.

Next: review the independent validation PR, formalize units and QC/configuration
validation, and define the supported v1.0 scope. Daily CTD time series remain
unvalidated. No release or tag is created by this milestone.

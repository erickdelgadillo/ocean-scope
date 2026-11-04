# OceanScope

MATLAB toolkit for reproducible oceanographic CTD and nutrient transect analyses.

## Status

**Pre-release: ENV1 numerically validated against the pinned curated archive.** The code is independent of the historical publication repository. ENV1 is the first target; ENV2 and ENV3 are reserved for subsequent independent validation. No historical files are changed or imported into this repository.

## Quick start

Requires MATLAB R2023b or newer for the recommended workflow, with built-in `readtable`, `griddata`, and `exportgraphics`. MATLAB licensing is required for local execution; GitHub CI currently performs static repository checks and does **not** claim to run MATLAB.

In MATLAB, from this repository root:

```matlab
addpath(pwd)
run_oceanscope("configs/demo.json")
```

This produces temperature and salinity transects and a run manifest in `results/demo/`.

## Historical ENV1 source data

The legacy, curated source is maintained at [coastal-upwelling-oceanography](https://github.com/erickdelgadillo/coastal-upwelling-oceanography). Clone that repository **next to** this one:

```bash
git clone https://github.com/erickdelgadillo/coastal-upwelling-oceanography.git
git clone https://github.com/erickdelgadillo/ocean-scope.git
```

Then execute:

```matlab
run_oceanscope("configs/env1.json")
```

The ENV1 configuration starts with the archived **day-7 CTD section** and **day-1 nutrient section**. The eight-day CTD series is an upcoming extension. Configurations point to existing source data rather than copying historical material.

ENV1 regression matches all 12 variables with zero numerical and NaN-mask
differences on MATLAB R2026a. See [validation results and limitations](docs/VALIDATION.md).
ENV2/ENV3 validation is still required before v1.0.

## Execution model

Each dataset declares input columns, variables, optional color limits and maximum
depth in metres. Paths are relative to the configuration. Optional `interpolation`
settings are `horizontal_points` (default 60), `depth_start` (0 m), and `depth_step`
(5 m). ENV1 explicitly starts at 5 m to reproduce the archival method.

Optional `geometry.origin_longitude` and `geometry.origin_latitude` (numeric degrees
or `"median"`) specify a great-circle origin. ENV1 uses 8.9145 degrees west-positive
and median latitude. Without geometry, the minimum observed longitude and its
first latitude are used for backward compatibility; this is not universally the
coastal endpoint. Signed coordinates require a consistently signed origin.

Finite samples within the depth limit are retained per variable. Exact duplicate
(distance, depth) positions are averaged explicitly. Linear `griddata` interpolation
never extrapolates. Each variable produces a PNG and a MAT section with numeric
values, query grids, sample mask and QC. The manifest records configuration,
MATLAB version and SHA-256 provenance. Generated outputs stay untracked.

## Project layout

- `run_oceanscope.m` — callable entry point
- `+oceanscope/` — MATLAB input, geometry, and plotting functions
- `configs/demo.json` — self-contained synthetic demonstration
- `configs/env1.json` — real ENV1 inputs in an adjacent historical repository
- `examples/` — synthetic fixtures only
- `tests/` — MATLAB unit tests
- `buildfile.m` — local `buildtool` tasks
- `.github/workflows/` — independent static checks (not scientific MATLAB validation)
- `results/` — ignored generated outputs

## Local checks

```matlab
results = runtests("tests");
assertSuccess(results)
```

or, where MATLAB Build Tool is available:

```matlab
buildtool test
buildtool demo
buildtool validate % Requires adjacent historical repository
```

## Scope and provenance

This is a new reusable analysis engine, **not** a replacement for the archived publication workflows. Do not alter ENV1/ENV2/ENV3 source files. After ENV1 numerical regression, validate unchanged MATLAB functions on ENV2 and ENV3, including ENV3 day 5 with nine station positions. Nutrient days and CTD days are not interchangeable, and static sections are not seasonal means.

The program deliberately does not calculate absolute salinity, density, or mixed-layer depths yet; those require more explicit unit and QC controls.

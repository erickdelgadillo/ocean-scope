# OceanScope

MATLAB toolkit for reproducible oceanographic CTD and nutrient transect analyses.

## Status

**Development scaffold (not yet scientifically validated).** The code is independent of the historical publication repository. ENV1 is the first target; ENV2 and ENV3 are reserved for subsequent independent validation. No historical files are changed or imported into this repository.

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

**Important:** the current implementation uses generic, data-driven grids and does not guarantee pixel- or numerically identical figures to the published MATLAB outputs. A full numerical regression suite must be established before claiming scientific equivalence.

## Execution model

A configuration JSON contains a `datasets` array. Each dataset declares a file, source columns, optional CSV delimiter, variables, optional color limits, and depth limit. Files are resolved relative to the configuration file; output directories are also relative to that file. Longitude may be west-positive in the source data, as in ENVISION: OceanScope uses great-circle **distance from the easternmost/coastal endpoint**, taking absolute longitude differences, without interpreting stored signs as a geospatial standard. The input's latitude units must be degrees.

Each run validates required columns, removes non-finite samples per variable, explicitly averages exact duplicate (distance, depth) coordinates and records counts for each variable in `manifest.json`, then interpolates using MATLAB's linear `griddata` on a 60-column and 5 m vertical grid, produces PNG sections, and writes a JSON manifest. Interpolated NaNs outside the convex hull are left blank rather than filled or extrapolated.

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
```

## Scope and provenance

This is a new reusable analysis engine, **not** a replacement for the archived publication workflows. Do not alter ENV1/ENV2/ENV3 source files. After ENV1 is verified against historical figures, validate unchanged MATLAB functions on ENV2 and ENV3, including ENV3 day 5 with nine station positions. Nutrient days and CTD days are not interchangeable, and static sections are not seasonal means.

The program deliberately does not calculate absolute salinity, density, or mixed-layer depths yet; those require more explicit unit and QC controls.

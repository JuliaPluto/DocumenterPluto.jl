# DocumenterPluto.jl

[![Build Status](https://github.com/JuliaPluto/DocumenterPluto.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaPluto/DocumenterPluto.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaPluto.github.io/DocumenterPluto.jl/dev/)

A [Documenter.jl](https://documenter.juliadocs.org) plugin that embeds
[Pluto.jl](https://plutojl.org) notebooks directly into an HTML documentation
build — no iframes, live and interactive.

## Requirements

- Julia 1.10+
- Documenter 1.9+ (for `RawHTMLHeadContent`)
- Pluto 0.20+

## Usage

```julia
# docs/make.jl
using Documenter
using DocumenterPluto      # loading is enough — no configuration

makedocs(sitename = "MyPackage.jl")
```

Then in any Markdown page:

````markdown
```@pluto
notebook = "notebooks/intro.jl"
```
````

Or with a hosted notebook:

````markdown
```@pluto
pluto_notebookfile = "https://bucket1.pluto.land/n/….jl"
pluto_statefile    = "https://bucket1.pluto.land/n/….plutostate"
```
````

See the [documentation](https://JuliaPluto.github.io/DocumenterPluto.jl/dev/)
for the full option reference and a live demo.

## How it works

DocumenterPluto hooks into Documenter's expansion and build pipelines:

1. An `@pluto` code block is parsed into a `PlutoBlock` AST node.
2. A build step walks all pages, runs any locally-referenced notebooks through
   Pluto (`Pluto.SessionActions.open` + `Pluto.notebook_to_js` + `Pluto.pack`),
   and copies the notebook + `.plutostate` into `docs/build/pluto_notebooks/`.
3. The same step injects Pluto's frontend `<head>` assets globally via
   [`Documenter.HTMLWriter.RawHTMLHeadContent`](https://github.com/JuliaDocs/Documenter.jl/pull/2726).
4. Each `PlutoBlock` is rendered as a `<script data-pluto-file="launch-parameters">`
   plus a `<pluto-editor>` placeholder that the frontend hydrates on load.

## License

MIT.

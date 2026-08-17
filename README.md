# DocumenterPluto.jl

[![Build Status](https://github.com/JuliaPluto/DocumenterPluto.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaPluto/DocumenterPluto.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaPluto.github.io/DocumenterPluto.jl/dev/)

A [Documenter.jl](https://documenter.juliadocs.org) plugin to embed
[Pluto.jl](https://plutojl.org) notebooks inside documenter pages. This package embeds the Pluto notebook directly, without iframe.

## Requirements

- Julia 1.10+
- Documenter 1.9+ (for `RawHTMLHeadContent`), waiting for https://github.com/JuliaDocs/Documenter.jl/issues/2933
- Pluto 0.20+

## Usage

```julia
# docs/make.jl
using Documenter
using DocumenterPluto      # `using DocumenterPluto` will set up Pluto support in pages

makedocs(sitename = "MyPackage.jl")
```

Then in any Markdown page:

````markdown
Here is a **Pluto notebook**:

```@pluto
notebook = "notebooks/intro.jl"
```
````

You can also embed notebooks that are pre-rendered, if they are hosted somewhere else:

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
2. A build step finds all notebooks, runs them using
   Pluto (`Pluto.SessionActions.open` + `Pluto.notebook_to_js` + `Pluto.pack`),
   and copies the notebook + `.plutostate` into `docs/build/pluto_notebooks/`.
3. Pluto's frontend `<head>` assets are injected globally via
   [`Documenter.HTMLWriter.RawHTMLHeadContent`](https://github.com/JuliaDocs/Documenter.jl/pull/2726).
4. Each `PlutoBlock` is rendered as a `<script data-pluto-file="launch-parameters">`
   plus a `<pluto-editor>` placeholder that the frontend hydrates on load.

## AI disclosure
The design for this package and the required Documenter.jl PRs were made by Fons. The implementation of this package and some of the documentation is generated using AI.

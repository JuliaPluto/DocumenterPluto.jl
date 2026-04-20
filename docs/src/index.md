# DocumenterPluto.jl

Embed [Pluto.jl](https://plutojl.org) notebooks directly inside a
[Documenter.jl](https://documenter.juliadocs.org) site — no iframes, live and
interactive.

## Install

```julia
julia> import Pkg; Pkg.add("DocumenterPluto")
```

## Usage

In your `docs/make.jl`:

```julia
using Documenter
using DocumenterPluto  # loading is enough

makedocs(; sitename = "MyPackage.jl", ...)
```

Then in any `.md` page, drop in a ```` ```@pluto ```` block.

### From a local notebook file

The plugin runs the notebook headlessly at build time and ships the generated
state alongside your docs:

````markdown
```@pluto
notebook = "notebooks/intro.jl"
```
````

The path is resolved relative to `docs/src/`. The notebook and its serialized
state are copied into `docs/build/pluto_notebooks/`.

### From a hosted notebook

If you already host the notebook and state (e.g. via
[`pluto.land`](https://pluto.land) or your own bucket):

````markdown
```@pluto
url    = "https://bucket1.pluto.land/n/01JVKXFS45K76H3Y8HY3J158JA.jl"
state  = "https://bucket1.pluto.land/n/01JVKXFS45K76H3Y8HY3J158JA.plutostate"
binder = "https://mybinder.org/v2/gh/fonsp/pluto-on-binder/v0.20.8"
```
````

### Options

| Key          | Type    | Default | Meaning                                 |
| ------------ | ------- | ------- | --------------------------------------- |
| `notebook`   | String  | —       | Path to a local `.jl` notebook          |
| `url`        | String  | —       | URL of a hosted `.jl` notebook          |
| `state`      | String  | —       | URL of a hosted `.plutostate` file      |
| `binder`     | String  | —       | Optional Binder launch URL              |
| `disable_ui` | Bool    | `true`  | Hide Pluto's UI chrome                  |

Set exactly one of `notebook` or `url`. If `url` is set, `state` is required.

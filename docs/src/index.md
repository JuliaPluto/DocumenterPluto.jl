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
pluto_notebookfile = "https://bucket1.pluto.land/n/01JVKXFS45K76H3Y8HY3J158JA.jl"
pluto_statefile    = "https://bucket1.pluto.land/n/01JVKXFS45K76H3Y8HY3J158JA.plutostate"
pluto_binder_url   = "https://mybinder.org/v2/gh/fonsp/pluto-on-binder/v0.20.8"
```
````

### Options

| Key                          | Type   | Default | Meaning                                        |
| ---------------------------- | ------ | ------- | ---------------------------------------------- |
| `notebook`                   | String | —       | Path to a local `.jl` notebook (relative to `docs/src/`) |
| `pluto_notebookfile`         | String | —       | URL of a hosted `.jl` notebook                 |
| `pluto_statefile`            | String | —       | URL of a hosted `.plutostate` file             |
| `pluto_disable_ui`           | Bool   | `true`  | Hide Pluto's UI chrome                         |
| `pluto_binder_url`           | String | —       | Binder launch URL for the "Edit" button        |
| `pluto_slider_server_url`    | String | —       | PlutoSliderServer base URL for interactivity   |
| `pluto_preamble_html`        | String | —       | HTML inserted before the notebook              |
| `pluto_recording_url`        | String | —       | URL of a recording to play back               |
| `pluto_recording_audio_url`  | String | —       | URL of the audio track for a recording        |

Set exactly one of `notebook` or `pluto_notebookfile`. If `pluto_notebookfile` is set, `pluto_statefile` is also required.

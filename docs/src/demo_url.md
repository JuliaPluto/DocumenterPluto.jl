# Demo: hosted notebook

This page embeds a Pluto notebook hosted on `pluto.land`.

```@pluto
pluto_notebookfile = "https://bucket1.pluto.land/n/01JVKXFS45K76H3Y8HY3J158JA.jl"
pluto_statefile    = "https://bucket1.pluto.land/n/01JVKXFS45K76H3Y8HY3J158JA.plutostate"
pluto_binder_url   = "https://mybinder.org/v2/gh/fonsp/pluto-on-binder/v0.20.8"
```

And regular Documenter content still works below the notebook:

```@repl
a = 1
b = 2
a + b
```

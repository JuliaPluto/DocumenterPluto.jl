# Demo: hosted notebook

This page embeds a Pluto notebook hosted on `pluto.land`.

```@pluto
url    = "https://bucket1.pluto.land/n/01JVKXFS45K76H3Y8HY3J158JA.jl"
state  = "https://bucket1.pluto.land/n/01JVKXFS45K76H3Y8HY3J158JA.plutostate"
binder = "https://mybinder.org/v2/gh/fonsp/pluto-on-binder/v0.20.8"
```

And regular Documenter content still works below the notebook:

```@repl
a = 1
b = 2
a + b
```

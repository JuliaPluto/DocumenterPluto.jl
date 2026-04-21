"""
    DocumenterPluto

A Documenter.jl plugin that embeds Pluto.jl notebooks directly into an HTML
documentation build — no iframes.

Loading the package is enough: any page containing a ````` ```@pluto ````` block
will be rendered as a live, interactive Pluto editor, and the necessary frontend
assets are injected into the site's `<head>`.

    using DocumenterPluto  # that's it — then use @pluto blocks in your .md pages
"""
module DocumenterPluto

using MarkdownAST: MarkdownAST, Node
using Documenter: Documenter, Selectors, DOM
using Documenter.HTMLWriter: DCtx, RawHTMLHeadContent
import Pluto
import TOML

include("head.jl")
include("expander.jl")
include("run_notebook.jl")
include("builder.jl")
include("domify.jl")

end # module

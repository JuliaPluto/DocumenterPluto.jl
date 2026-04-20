# The @pluto block. Follows the same shape as DocumenterMermaid's mermaid block:
# a custom ExpanderPipeline matches the code block during the expansion phase,
# replaces the node element with a PlutoBlock, and then a dedicated domify
# method renders it in the HTMLWriter phase.

"""
    PlutoBlock

MarkdownAST element produced by the `@pluto` expander. Holds the parsed
attributes of one ```` ```@pluto ```` code block:

- `notebook :: Union{String, Nothing}` — path to a local `.jl` file, relative to
  the Documenter source root. When set, the plugin runs the notebook headlessly
  and copies both the `.jl` and the generated `.plutostate` into the build
  output.
- `url :: Union{String, Nothing}` — URL of a hosted notebook file
  (`pluto_notebookfile`).
- `state :: Union{String, Nothing}` — URL of a hosted `.plutostate` file.
- `binder :: Union{String, Nothing}` — optional Binder launch URL.
- `disable_ui :: Bool` — whether to hide Pluto's UI chrome (default `true`).

Exactly one of `notebook` or `url` must be set. When `url` is set, `state` is
required too.

The resolved URLs used by the frontend (`window.pluto_notebookfile`,
`window.pluto_statefile`) are filled in by the builder step before domify runs.
"""
mutable struct PlutoBlock <: Documenter.AbstractDocumenterBlock
    notebook   :: Union{String, Nothing}
    url        :: Union{String, Nothing}
    state      :: Union{String, Nothing}
    binder     :: Union{String, Nothing}
    disable_ui :: Bool
    # Filled in by the builder: final URLs the rendered <script> will point at.
    # For a local `notebook`, these become build-relative paths.
    resolved_notebook :: Union{String, Nothing}
    resolved_state    :: Union{String, Nothing}
end

function PlutoBlock(; notebook=nothing, url=nothing, state=nothing, binder=nothing, disable_ui=true)
    PlutoBlock(notebook, url, state, binder, disable_ui, nothing, nothing)
end

abstract type PlutoExpander <: Documenter.Expanders.ExpanderPipeline end
Selectors.order(::Type{PlutoExpander}) = 7.9
Selectors.matcher(::Type{PlutoExpander}, node, page, doc) = Documenter.iscode(node, "@pluto")

function Selectors.runner(::Type{PlutoExpander}, node, page, doc)
    code = node.element.code
    block = try
        _parse_pluto_block(code)
    catch err
        @error "DocumenterPluto: failed to parse `@pluto` block on $(page.source)" exception = (err, catch_backtrace())
        rethrow(err)
    end
    node.element = block
    return
end

# The block body is TOML. Keys accepted (case-insensitive, snake-cased):
#   notebook | url | state | binder | disable_ui
function _parse_pluto_block(code::AbstractString)
    raw = isempty(strip(code)) ? Dict{String,Any}() : TOML.parse(code)
    # Normalise keys to lowercase so `Notebook=` and `notebook=` both work.
    kv = Dict{String,Any}(lowercase(k) => v for (k, v) in raw)

    notebook  = get(kv, "notebook", nothing)
    url       = get(kv, "url", nothing)
    state     = get(kv, "state", nothing)
    binder    = get(kv, "binder", nothing)
    disable_ui = get(kv, "disable_ui", true)

    if notebook === nothing && url === nothing
        error("`@pluto` block must set either `notebook = \"path/to/notebook.jl\"` or `url = \"…\"` + `state = \"…\"`.")
    end
    if notebook !== nothing && url !== nothing
        error("`@pluto` block sets both `notebook` and `url`; use exactly one.")
    end
    if url !== nothing && state === nothing
        error("`@pluto` block with `url` must also set `state = \"…plutostate\"`.")
    end

    PlutoBlock(;
        notebook   = notebook isa AbstractString ? String(notebook) : nothing,
        url        = url      isa AbstractString ? String(url)      : nothing,
        state      = state    isa AbstractString ? String(state)    : nothing,
        binder     = binder   isa AbstractString ? String(binder)   : nothing,
        disable_ui = Bool(disable_ui),
    )
end

# Documenter's search-index and link-check phases flatten pages to plain text
# via MDFlatten.mdflatten; emit nothing so our block is invisible to them.
Documenter.MDFlatten.mdflatten(io, ::MarkdownAST.Node, ::PlutoBlock) = nothing

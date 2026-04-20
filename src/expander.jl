# The @pluto block. Follows the same shape as DocumenterMermaid's mermaid block:
# a custom ExpanderPipeline matches the code block during the expansion phase,
# replaces the node element with a PlutoBlock, and then a dedicated domify
# method renders it in the HTMLWriter phase.

"""
    PlutoBlock

MarkdownAST element produced by the `@pluto` expander. Holds the parsed
attributes of one ```` ```@pluto ```` code block.

The only recognised special key is:

- `notebook :: Union{String, Nothing}` — path to a local `.jl` file, relative to
  the Documenter source root. When set, the plugin runs the notebook headlessly
  and copies both the `.jl` and the generated `.plutostate` into the build
  output, then exposes them to the frontend as `window.pluto_notebookfile` and
  `window.pluto_statefile`.

Every other key must start with `pluto_` and is forwarded verbatim to the
frontend as `window.<key> = <value>;` in the launch-parameters script. Typical
keys for pre-hosted notebooks are `pluto_notebookfile` and `pluto_statefile`;
see Pluto's frontend for the full list (`pluto_disable_ui`, `pluto_binder_url`,
`pluto_recording_url`, …).

Exactly one of the following must hold: `notebook` is set, *or* both
`pluto_notebookfile` and `pluto_statefile` are set.
"""
mutable struct PlutoBlock <: Documenter.AbstractDocumenterBlock
    notebook     :: Union{String, Nothing}
    pluto_params :: Dict{String, Any}
    # Filled in by the builder for local notebooks: build-root-relative paths
    # that domify turns into page-relative hrefs.
    resolved_notebook :: Union{String, Nothing}
    resolved_state    :: Union{String, Nothing}
end

PlutoBlock(; notebook=nothing, pluto_params=Dict{String,Any}()) =
    PlutoBlock(notebook, pluto_params, nothing, nothing)

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

# The block body is TOML. `notebook` is special; every other key must start
# with `pluto_` and is forwarded as-is to `window.<key>` in the launch script.
function _parse_pluto_block(code::AbstractString)
    raw = isempty(strip(code)) ? Dict{String,Any}() : TOML.parse(code)

    notebook     = nothing
    pluto_params = Dict{String,Any}()
    for (k, v) in raw
        if k == "notebook"
            v isa AbstractString || error("`@pluto`: `notebook` must be a string.")
            notebook = String(v)
        elseif startswith(k, "pluto_")
            pluto_params[k] = v
        else
            error("`@pluto`: unknown key `$k`. Use `notebook = \"…\"` or a key starting with `pluto_`.")
        end
    end

    # Default: hide Pluto's UI chrome in docs builds.
    get!(pluto_params, "pluto_disable_ui", true)

    has_urls = haskey(pluto_params, "pluto_notebookfile") && haskey(pluto_params, "pluto_statefile")
    if notebook === nothing && !has_urls
        error("`@pluto` block must set either `notebook = \"path/to/notebook.jl\"` or both `pluto_notebookfile` and `pluto_statefile`.")
    end
    if notebook !== nothing && (haskey(pluto_params, "pluto_notebookfile") || haskey(pluto_params, "pluto_statefile"))
        error("`@pluto` block sets `notebook` together with `pluto_notebookfile`/`pluto_statefile`; use one or the other.")
    end

    return PlutoBlock(; notebook, pluto_params)
end

# Documenter's search-index and link-check phases flatten pages to plain text
# via MDFlatten.mdflatten; emit nothing so our block is invisible to them.
Documenter.MDFlatten.mdflatten(io, ::MarkdownAST.Node, ::PlutoBlock) = nothing

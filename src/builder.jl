# DocumentPipeline hook that runs once, late enough that all pages have been
# expanded (so every @pluto code block is already a PlutoBlock in the AST).
# Responsibilities:
#   1. Walk every page and collect PlutoBlocks.
#   2. For blocks with a local `notebook`: run the notebook headlessly, copy the
#      .jl and generated .plutostate into the build output, and fill in
#      `resolved_notebook` / `resolved_state` on the block.
#   3. For blocks without `notebook`: nothing to resolve — the pre-hosted URLs
#      are already sitting in `pluto_params` and will be emitted verbatim.
#   4. If any PlutoBlock was seen, push one `RawHTMLHeadContent` onto the
#      site's `format.assets` so every page loads Pluto's frontend.

abstract type PlutoBuilder <: Documenter.Builder.DocumentPipeline end
Selectors.order(::Type{PlutoBuilder}) = 5.5

const _PLUTO_ASSET_SUBDIR = "pluto_notebooks"

function Selectors.runner(::Type{PlutoBuilder}, doc::Documenter.Document)
    blocks = _collect_pluto_blocks(doc)
    isempty(blocks) && return

    format = doc.user.format
    # Documenter supports multiple output formats in one build; only act on
    # HTML. The head-asset injection is meaningless for e.g. LaTeXWriter.
    html_format = _find_html_format(format)
    html_format === nothing && return

    _materialise_notebooks!(doc, blocks)
    _inject_head_assets!(html_format)
    return
end

_find_html_format(f::Documenter.HTML) = f
function _find_html_format(formats::AbstractVector)
    for f in formats
        f isa Documenter.HTML && return f
    end
    return nothing
end
_find_html_format(_) = nothing

function _collect_pluto_blocks(doc)
    out = Tuple{Any,PlutoBlock}[]  # (page, block)
    for page in values(doc.blueprint.pages)
        _visit(page.mdast) do node
            node.element isa PlutoBlock && push!(out, (page, node.element))
        end
    end
    return out
end

function _visit(f, node::Node)
    f(node)
    for c in node.children
        _visit(f, c)
    end
end

function _materialise_notebooks!(doc, blocks)
    source_root = doc.user.source
    build_root  = doc.user.build
    asset_dir   = joinpath(build_root, _PLUTO_ASSET_SUBDIR)

    for (page, block) in blocks
        block.notebook === nothing && continue  # pre-hosted: pluto_params carries the URLs

        nb_rel = block.notebook::String
        nb_src = isabspath(nb_rel) ? nb_rel : normpath(joinpath(source_root, nb_rel))
        isfile(nb_src) || error("DocumenterPluto: notebook not found: $nb_src")

        mkpath(asset_dir)
        slug = _slug(nb_rel)
        nb_out    = joinpath(asset_dir, slug * ".jl")
        state_out = joinpath(asset_dir, slug * ".plutostate")

        # Cache: skip re-running if the copied .jl is newer than the source.
        if !(isfile(nb_out) && isfile(state_out) && mtime(nb_out) >= mtime(nb_src))
            @info "DocumenterPluto: running notebook" notebook=nb_rel
            cp(nb_src, nb_out; force=true)
            run_notebook(nb_out; out_state=state_out)
        end

        block.resolved_notebook = _site_root_relative(nb_out, build_root)
        block.resolved_state    = _site_root_relative(state_out, build_root)
    end
    return
end

# Deterministic, filesystem-safe slug derived from the source-relative path so
# that notebooks/a/foo.jl and notebooks/b/foo.jl don't collide.
function _slug(rel_path::AbstractString)
    s = replace(String(rel_path), r"[^A-Za-z0-9._-]" => "_")
    endswith(s, ".jl") ? s[1:end-3] : s
end

# Build-root-relative path with forward slashes; domify turns this into a
# page-relative href via HTMLWriter.relhref.
function _site_root_relative(abs_path::AbstractString, build_root::AbstractString)
    rel = relpath(abs_path, build_root)
    return replace(rel, '\\' => '/')
end

function _inject_head_assets!(html_format::Documenter.HTML)
    head = pluto_head_html()
    asset = RawHTMLHeadContent(head)
    # Idempotency: makedocs may be invoked multiple times in a session.
    any(a -> a isa RawHTMLHeadContent && a.content == head, html_format.assets) && return
    push!(html_format.assets, asset)
    return
end

# Render a PlutoBlock as the HTML a Pluto frontend needs to bring itself online:
# the `launch-parameters` <script> that sets window.pluto_{notebookfile,state…},
# followed by the <pluto-editor> placeholder that the JS in <head> hydrates.

function Documenter.HTMLWriter.domify(dctx::DCtx, ::Node, block::PlutoBlock)
    DOM.@tags script div progress pluto_editor

    page_url = Documenter.HTMLWriter.get_url(dctx.ctx, dctx.navnode.page)
    nb_href    = _resolve_href(page_url, block.resolved_notebook)
    state_href = _resolve_href(page_url, block.resolved_state)

    launch_params = """
    window.pluto_notebookfile = $(_js_string(nb_href));
    window.pluto_disable_ui = $(block.disable_ui ? "true" : "false");
    window.pluto_binder_url = $(block.binder === nothing ? "undefined" : _js_string(block.binder));
    window.pluto_statefile = $(_js_string(state_href));
    window.pluto_recording_url = undefined;
    window.pluto_recording_audio_url = undefined;
    """

    # DOM.@tags doesn't allow `pluto-editor` as an identifier, so we use
    # `pluto_editor` and fix the tag name with a Tag() override. The frontend
    # matches on the hyphenated custom element name.
    editor = DOM.Tag(Symbol("pluto-editor"))[ :class => "loading" ](
        progress[
            :style => "filter:grayscale()",
            :class => "delete-me-when-live statefile-fetch-progress",
            :max => "100",
        ],
    )

    return [
        script[Symbol("data-pluto-file") => "launch-parameters"](launch_params),
        div[:style => "display:flex; overflow-y: hidden;"](editor),
    ]
end

# target is either an external URL (http/https), or a build-root-relative path
# like "pluto_notebooks/foo.jl". For the relative case, turn it into a
# page-relative href via Documenter's own helper so that baseurl/prettyurl
# deployments keep working.
function _resolve_href(page_url::AbstractString, target::Union{String,Nothing})
    target === nothing && return ""
    _is_absolute_url(target) && return target
    return Documenter.HTMLWriter.relhref(page_url, target)
end

_is_absolute_url(s::AbstractString) =
    startswith(s, "http://") || startswith(s, "https://") || startswith(s, "//") || startswith(s, "/")

# Minimal JS string literal: JSON encoding is a superset of JS-string syntax for
# our purposes (URLs), and Julia's repr() for String happens to produce a valid
# JS string too. Use repr.
_js_string(s::AbstractString) = repr(s)

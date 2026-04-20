# Render a PlutoBlock as the HTML a Pluto frontend needs to bring itself online:
# the `launch-parameters` <script> that sets window.pluto_* globals, followed
# by the <pluto-editor> placeholder that the JS in <head> hydrates.

function Documenter.HTMLWriter.domify(dctx::DCtx, ::Node, block::PlutoBlock)
    page_url = Documenter.HTMLWriter.get_url(dctx.ctx, dctx.navnode.page)

    # Start from the user's pluto_* params, then overlay the locally-resolved
    # notebook/state paths (if any) so they win over anything the user set.
    params = copy(block.pluto_params)
    if block.resolved_notebook !== nothing
        params["pluto_notebookfile"] = Documenter.HTMLWriter.relhref(page_url, block.resolved_notebook)
    end
    if block.resolved_state !== nothing
        params["pluto_statefile"] = Documenter.HTMLWriter.relhref(page_url, block.resolved_state)
    end

    launch_params = join(
        ["window.$k = $(_js_string(params[k]));" for k in sort!(collect(keys(params)))],
        "\n",
    )

    editor = DOM.Tag(Symbol("pluto-editor"))[ :class => "loading" ](
        DOM.Tag(:progress)[
            :style => "filter:grayscale()",
            :class => "delete-me-when-live statefile-fetch-progress",
            :max => "100",
        ],
    )

    return [
        DOM.Tag(:script)[Symbol("data-pluto-file") => "launch-parameters"](launch_params),
        DOM.Tag(:div)[:style => "display:flex; overflow-y: hidden;"](editor),
    ]
end

struct JSLiteral
    x
end

# JS literal encoding for the scalar types TOML can produce, plus Nothing
# (→ `undefined`) and JSLiteral (raw unquoted JS, e.g. `undefined`, function
# literals) for user-provided pluto_* values that need to be something other
# than a string/number/bool.
_js_string(s::AbstractString) = repr(String(s))
_js_string(s::Nothing)        = "undefined"
_js_string(s::Bool)           = s ? "true" : "false"
_js_string(s::Number)         = string(s)
_js_string(s::AbstractVector) = "[" * join((_js_string(x) for x in s), ", ") * "]"
_js_string(s::AbstractDict)   = "{" * join(("$(repr(String(k))): $(_js_string(v))" for (k,v) in s), ", ") * "}"
_js_string(s::JSLiteral)      = s.x

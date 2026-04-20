# Extracts the subset of Pluto's frontend-shell <head> needed to host embedded
# <pluto-editor> elements inside a Documenter page. We strip <title>, <meta
# description>, and <link rel=icon> so the plugin doesn't fight Documenter's own
# page metadata.

const _HEAD_STRIP_PATTERNS = [
    r"<title.*?/title>",
    r"<meta name=[\"']?description.*?>",
    r"<link rel=[\"']?icon.*?>",
]

# CSS to stop Documenter's default <pre>/<code> styling from leaking into the
# embedded Pluto editor. Without this, cell code blocks get an extra border and
# background.
const _STYLE_OVERRIDES = """
<style>
.content :where(pluto-editor) {
    position: relative;

    pre {
        border: none;
        background: none;
    }
    pre code {
        padding: 0;
    }
    pre code:is(:first-of-type, :last-of-type) {
        padding: unset !important;
    }
    
    .edit_or_run {
        z-index: unset;
        position: absolute;
    }
}
    
#documenter .docs-sidebar:not(.asdf) {
    z-index: 200;
}
</style>
"""

"""
    pluto_head_html(; pluto_cdn_root=nothing) -> String

Return the raw HTML that must live inside the site's `<head>` in order to host
embedded Pluto editors. This is the same content produced by
`Pluto.generate_html`, minus the page-level metadata tags that would clash with
Documenter.

Most users don't need to call this directly — the `DocumenterPluto` build step
injects it automatically for any site that contains a `@pluto` block.
"""
function pluto_head_html(; pluto_cdn_root=nothing)
    shell = Pluto.generate_html(; pluto_cdn_root)
    m = match(r"<head.*?>(.*)</head>"s, shell)
    m === nothing && error("DocumenterPluto: could not locate <head> in Pluto.generate_html output")
    head = m[1]
    for r in _HEAD_STRIP_PATTERNS
        head = replace(head, r => "")
    end
    return head * _STYLE_OVERRIDES
end

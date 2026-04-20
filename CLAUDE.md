# CLAUDE.md

Non-obvious context for working on this repo. Does not repeat what's in the
source or README.

This package has no users yet so breaking changes are fine.

The user is a Pluto.jl expert developer, you can ask them to clarify any Pluto internals you need.

## What this package is

A Documenter.jl plugin that embeds Pluto.jl notebooks into a documentation site
**without iframes**. Users write `@pluto` code blocks in their Markdown, and
the plugin runs the notebooks, serialises them, and injects Pluto's frontend
shell into the site's `<head>` so the `<pluto-editor>` custom element hydrates
on page load.

## The plugin model (mirrors DocumenterMermaid)

Three-stage pipeline, same shape as
[DocumenterMermaid.jl](https://github.com/JuliaDocs/DocumenterMermaid.jl/blob/main/src/DocumenterMermaid.jl):

1. **Expander** (`src/expander.jl`, `Selectors.order = 7.9`) — matches
   ```` ```@pluto ```` code blocks by `Documenter.iscode(node, "@pluto")` and
   rewrites the MarkdownAST node's `.element` to a `PlutoBlock`.
2. **Builder** (`src/builder.jl`, `Selectors.order = 5.5`) — runs once on the
   whole `Document`. Walks every page, materialises local notebooks via
   `run_notebook`, and appends a single `RawHTMLHeadContent` to
   `doc.user.format.assets`.
3. **Domify** (`src/domify.jl`) — per-block HTML rendering via
   `Documenter.HTMLWriter.domify(::DCtx, ::Node, ::PlutoBlock)`.

If you're adding a new pipeline stage, check DocumenterMermaid's source again
— it is the canonical minimal example.

## Internals we depend on (none are officially public)

**Pluto.jl** (pinned at `"0.20"` in `Project.toml`):

- `Pluto.ServerSession`
- `Pluto.Configuration.from_flat_kwargs`
- `Pluto.SessionActions.open` (with `run_async=false` to block until the
  notebook finishes)
- `Pluto.SessionActions.shutdown`
- `Pluto.notebook_to_js` — the Dict that Pluto's own `/statefile` route packs
- `Pluto.pack` — MsgPack encoder (Pluto re-exports from its vendored MsgPack)
- `Pluto.generate_html(; pluto_cdn_root)` — the only part that feels
  semi-public; used to produce the `<head>` shell, which we then strip

We **do not** start Pluto's HTTP server. A bare `ServerSession` is enough.
PlutoSliderServer does the same dance; we deliberately don't depend on it
(user request).

One non-obvious detail from PlutoSliderServer: before packing the state, we
`delete!(state, "status_tree")`. That key is a transient UI hint that isn't
needed to replay a completed run and isn't guaranteed to be MsgPack-clean.

**Documenter.jl** (pinned at `"1.9"` — the version that shipped
`RawHTMLHeadContent`, see PR #2726):

- `Documenter.AbstractDocumenterBlock` (base type for `PlutoBlock`)
- `Documenter.Expanders.ExpanderPipeline` + `Documenter.Builder.DocumentPipeline`
  (selector hierarchies)
- `Documenter.Selectors.{order,matcher,runner}`
- `Documenter.HTMLWriter.DCtx`, `.domify`, `.relhref`, `.get_url`,
  `.RawHTMLHeadContent`
- `Documenter.DOM.Tag(Symbol("pluto-editor"))(...)` — the `@tags` macro only
  supports identifier tag names, so hyphenated custom elements need the
  explicit `Tag` constructor
- `Documenter.MDFlatten.mdflatten` — must define a no-op method for each
  custom block type, otherwise search-index generation crashes

## Why the `<head>` is stripped

`Pluto.generate_html()` returns a full HTML page. We yank out just the
`<head>` inner HTML and then delete:

- `<title>` — would clash with Documenter's own page title
- `<meta name="description">` — same
- `<link rel="icon">` — same

The style overrides in `src/head.jl` neutralise Documenter's `<pre>`/`<code>`
CSS, which otherwise leaks into rendered cells and makes Pluto look like it
has a wrong-coloured background around every code cell.

## Asset-injection scope is global

Every page in the site gets the Pluto head assets, even pages with no
`@pluto` block. This matches DocumenterMermaid and matches the state of
Documenter's HTMLWriter — per-page asset differentiation would require
extending HTMLWriter infrastructure. See the discussion on
[Documenter#2726](https://github.com/JuliaDocs/Documenter.jl/pull/2726).
Per-page scoping is a v0.2+ idea.

## URL resolution

`PlutoBlock` stores two "resolved" fields set during the builder step:

- For `url=`/`state=` (hosted): resolved fields are the URLs verbatim.
- For `notebook=` (local): resolved fields are **build-root-relative paths**
  (e.g. `"pluto_notebooks/foo.jl"`), not absolute paths. Domify turns them
  into page-relative hrefs via `HTMLWriter.relhref(page_url, target)` where
  `page_url = HTMLWriter.get_url(ctx, navnode.page)`. This is the same
  mechanism Documenter uses for its own asset links, so it survives
  `prettyurls`, `baseurl`, and GH-Pages subpath deployments.

Do not switch to root-relative paths like `/pluto_notebooks/...` — that
breaks GH-Pages sites hosted under `<user>.github.io/<repo>/`.

## Key external references

- [JuliaDocs/Documenter.jl#2726](https://github.com/JuliaDocs/Documenter.jl/pull/2726)
  — introduced `RawHTMLHeadContent`; the entire reason this plugin is
  possible.
- [fonsp/Pluto.jl#3237](https://github.com/fonsp/Pluto.jl/pull/3237) —
  switched Observable's stdlib to ES modules via jsDelivr so it doesn't
  collide with Documenter's RequireJS.
- [JuliaDocs/DocumenterMermaid.jl](https://github.com/JuliaDocs/DocumenterMermaid.jl)
  — the structural template.
- [JuliaPluto/PlutoSliderServer.jl](https://github.com/JuliaPluto/PlutoSliderServer.jl)
  — does the same notebook-running dance at scale. Good reference for
  error-handling patterns if we ever need them, but **not** a dependency.

## Decisions the maintainer has already made

These came up during the initial design discussion; don't re-litigate without
a reason:

- Package name is `DocumenterPluto.jl` (matches DocumenterMermaid naming).
- Lives under the `JuliaPluto` GitHub org.
- v0.1 supports both local `.jl` paths *and* pre-hosted URLs.
- No dependency on PlutoSliderServer. We call Pluto directly.
- Global asset injection for v0.1. Per-page is a later concern.
- Zero-config UX: `using DocumenterPluto` in `make.jl` is enough. No
  `DocumenterPluto.generate()` call in user code.

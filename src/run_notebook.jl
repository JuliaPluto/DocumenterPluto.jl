# Headless notebook runner. Uses a small set of Pluto.jl internals that are also
# used by PlutoSliderServer and by Pluto's own `generate_html` — they are
# de-facto stable, but not part of Pluto's declared public API, so the
# `Pluto = "0.20"` compat bound in Project.toml matters.
#
# Internals touched: Pluto.ServerSession, Pluto.Configuration.from_flat_kwargs,
# Pluto.SessionActions.open/shutdown, Pluto.notebook_to_js, Pluto.pack.

"""
    run_notebook(path; out_state::AbstractString) -> Nothing

Run the Pluto notebook at `path` to completion in a fresh headless session,
serialize its final state via MsgPack, and write the bytes to `out_state`.
Errors inside notebook cells do not abort the build — they surface in the
rendered editor the same way they would in a live Pluto session.
"""
function run_notebook(path::AbstractString; out_state::AbstractString)
    opts = Pluto.Configuration.from_flat_kwargs(;
        disable_writing_notebook_files = true,
        auto_reload_from_file          = false,
        show_banner                    = false,
        launch_browser                 = false,
    )
    session = Pluto.ServerSession(; options = opts)
    notebook = Pluto.SessionActions.open(session, path; run_async = false)
    try
        state = Pluto.notebook_to_js(notebook)
        # PlutoSliderServer strips `status_tree` — it's a transient UI hint the
        # frontend doesn't need to replay a completed run.
        delete!(state, "status_tree")
        open(out_state, "w") do io
            Pluto.pack(io, state)
        end
    finally
        Pluto.SessionActions.shutdown(session, notebook)
    end
    return nothing
end

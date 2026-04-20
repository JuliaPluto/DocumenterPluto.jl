# Headless notebook runner. Uses a small set of Pluto.jl internals, for API spec see https://plutojl.org/en/docs/api/

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
        launch_browser                 = false,
    )
    session = Pluto.ServerSession(; options = opts)
    notebook = Pluto.SessionActions.open(session, path; run_async = false)
    try
        state = Pluto.notebook_to_js(notebook)
        # PlutoSliderServer strips `status_tree` — it's a transient UI hint the
        # frontend doesn't need to replay a completed run.
        delete!(state, "status_tree")
        write(out_state, Pluto.pack(io, state))
    finally
        Pluto.SessionActions.shutdown(session, notebook)
    end
    return nothing
end

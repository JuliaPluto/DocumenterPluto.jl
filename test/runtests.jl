using DocumenterPluto
using Documenter
using Test

const DP = DocumenterPluto

@testset "block parsing" begin
    b = DP._parse_pluto_block("""
    pluto_notebookfile = "https://example.com/n.jl"
    pluto_statefile    = "https://example.com/n.plutostate"
    """)
    @test b isa DP.PlutoBlock
    @test b.notebook === nothing
    @test b.pluto_params["pluto_notebookfile"] == "https://example.com/n.jl"
    @test b.pluto_params["pluto_statefile"]    == "https://example.com/n.plutostate"
    @test b.pluto_params["pluto_disable_ui"]   == true  # default

    b2 = DP._parse_pluto_block("""
    notebook         = "notebooks/intro.jl"
    pluto_disable_ui = false
    pluto_binder_url = "https://mybinder.org/…"
    """)
    @test b2.notebook == "notebooks/intro.jl"
    @test b2.pluto_params["pluto_disable_ui"] == false
    @test b2.pluto_params["pluto_binder_url"] == "https://mybinder.org/…"

    # empty block rejected
    @test_throws Exception DP._parse_pluto_block("")
    # can't mix local notebook with explicit pluto_notebookfile
    @test_throws Exception DP._parse_pluto_block("""
        notebook           = "a.jl"
        pluto_notebookfile = "https://example.com/n.jl"
        pluto_statefile    = "https://example.com/n.plutostate"
        """)
    # pluto_statefile required alongside pluto_notebookfile
    @test_throws Exception DP._parse_pluto_block("""pluto_notebookfile = "https://example.com/n.jl" """)
    # unknown (non-pluto_) key rejected
    @test_throws Exception DP._parse_pluto_block("""url = "https://example.com/n.jl" """)
end

@testset "head html" begin
    h = DP.pluto_head_html()
    @test occursin("pluto-editor", h) || occursin("<script", h)
    @test !occursin("<title", h)
    @test !occursin("rel=\"icon\"", h) && !occursin("rel='icon'", h)
end

@testset "end-to-end build" begin
    mktempdir() do tmp
        src = joinpath(tmp, "src")
        mkpath(src)
        write(joinpath(src, "index.md"), """
        # Test

        ```@pluto
        pluto_notebookfile = "https://example.com/n.jl"
        pluto_statefile    = "https://example.com/n.plutostate"
        ```
        """)

        build = joinpath(tmp, "build")
        makedocs(;
            root     = tmp,
            source   = "src",
            build    = "build",
            sitename = "Test",
            format   = Documenter.HTML(prettyurls = false),
            remotes  = nothing,
        )

        html = read(joinpath(build, "index.html"), String)
        @test occursin("data-pluto-file=\"launch-parameters\"", html)
        @test occursin("pluto-editor", html)
        @test occursin("https://example.com/n.jl", html)
        @test occursin("https://example.com/n.plutostate", html)
        @test occursin("window.pluto_disable_ui = true;", html)
    end
end

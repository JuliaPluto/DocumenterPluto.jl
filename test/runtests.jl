using DocumenterPluto
using Documenter
using Test

const DP = DocumenterPluto

@testset "block parsing" begin
    b = DP._parse_pluto_block("""
    url   = "https://example.com/n.jl"
    state = "https://example.com/n.plutostate"
    """)
    @test b isa DP.PlutoBlock
    @test b.url == "https://example.com/n.jl"
    @test b.state == "https://example.com/n.plutostate"
    @test b.notebook === nothing
    @test b.disable_ui == true

    b2 = DP._parse_pluto_block("""
    notebook   = "notebooks/intro.jl"
    disable_ui = false
    """)
    @test b2.notebook == "notebooks/intro.jl"
    @test b2.disable_ui == false

    @test_throws Exception DP._parse_pluto_block("")
    @test_throws Exception DP._parse_pluto_block("""notebook = "a"
                                                    url      = "b" """)
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
        url   = "https://example.com/n.jl"
        state = "https://example.com/n.plutostate"
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
    end
end

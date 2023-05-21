using SimpleCaching
using Test

const testing_cache_dir = mktempdir(prefix = "SimpleCaching_test_")
const cached_type = "testing_object"

module A
    using SimpleCaching

    export heavy_computation

    function heavy_computation(cached_type, testing_cache_dir, x, s::Integer...)
        return @scache cached_type testing_cache_dir fill(x, s...)
    end
end

@testset "SimpleCaching.jl" begin
    # test @scache
    res1 = @scache cached_type testing_cache_dir fill(0.0, 10, 10, 10)
    @test isdir(testing_cache_dir)
    res2 = @scache cached_type testing_cache_dir fill(0.0, 10, 10, 10)
    res3 = @scache cached_type testing_cache_dir fill(Float64(1 - 1), 10, 10, 10)
    res4 = @scache cached_type testing_cache_dir fill(res3[1,1,1], 10, 10, 10)

    res = fill(0.0, 10, 10, 10)

    @test res1 == res
    @test res2 == res
    @test res3 == res
    @test res4 == res

    # test @scachejld
    res1 = @scachejld cached_type testing_cache_dir fill(0.0, 20, 20, 20)
    res2 = @scachejld cached_type testing_cache_dir fill(0.0, 20, 20, 20)
    res3 = @scachejld cached_type testing_cache_dir fill(Float64(1 - 1), 20, 20, 20)
    res4 = @scachejld cached_type testing_cache_dir fill(res3[1,1,1], 20, 20, 20)

    res = fill(0.0, 20, 20, 20)

    @test res1 == res
    @test res2 == res
    @test res3 == res
    @test res4 == res

    rm(testing_cache_dir; recursive = true)

    @testset "no type" begin
        # test @scache
        res1 = @scache testing_cache_dir fill(0.0, 10, 10, 10)
        @test isdir(testing_cache_dir)
        res2 = @scache testing_cache_dir fill(0.0, 10, 10, 10)
        res3 = @scache testing_cache_dir fill(Float64(1 - 1), 10, 10, 10)
        res4 = @scache testing_cache_dir fill(res3[1,1,1], 10, 10, 10)

        res = fill(0.0, 10, 10, 10)

        @test res1 == res
        @test res2 == res
        @test res3 == res
        @test res4 == res

        # test @scachejld
        res1 = @scachejld testing_cache_dir fill(0.0, 20, 20, 20)
        res2 = @scachejld testing_cache_dir fill(0.0, 20, 20, 20)
        res3 = @scachejld testing_cache_dir fill(Float64(1 - 1), 20, 20, 20)
        res4 = @scachejld testing_cache_dir fill(res3[1,1,1], 20, 20, 20)

        res = fill(0.0, 20, 20, 20)

        @test res1 == res
        @test res2 == res
        @test res3 == res
        @test res4 == res

        rm(testing_cache_dir; recursive = true)

        @testset "no dir" begin
            # test @scache
            res1 = @scache fill(0.0, 10, 10, 10)
            @test isdir(SimpleCaching.settings.cache_dir)
            res2 = @scache fill(0.0, 10, 10, 10)
            res3 = @scache fill(Float64(1 - 1), 10, 10, 10)
            res4 = @scache fill(res3[1,1,1], 10, 10, 10)

            res = fill(0.0, 10, 10, 10)

            @test res1 == res
            @test res2 == res
            @test res3 == res
            @test res4 == res

            # test @scachejld
            res1 = @scachejld fill(0.0, 20, 20, 20)
            res2 = @scachejld fill(0.0, 20, 20, 20)
            res3 = @scachejld fill(Float64(1 - 1), 20, 20, 20)
            res4 = @scachejld fill(res3[1,1,1], 20, 20, 20)

            res = fill(0.0, 20, 20, 20)

            @test res1 == res
            @test res2 == res
            @test res3 == res
            @test res4 == res

            rm(SimpleCaching.settings.cache_dir; recursive = true)
        end
    end

    @testset "conditionals" begin
        # test @scache_if
        res = fill(0.0, 10, 10, 10)

        res1 = @scache_if false cached_type testing_cache_dir fill(0.0, 10, 10, 10)
        @test !isdir(testing_cache_dir)
        @test res1 == res

        res1 = @scache_if true cached_type testing_cache_dir fill(0.0, 10, 10, 10)
        @test isdir(testing_cache_dir)
        @test res1 == res

        rm(testing_cache_dir; recursive = true)

        # test @scachejld_if
        res = fill(0.0, 10, 10, 10)

        res1 = @scachejld_if false cached_type testing_cache_dir fill(0.0, 10, 10, 10)
        @test !isdir(testing_cache_dir)
        @test res1 == res

        res1 = @scachejld_if true cached_type testing_cache_dir fill(0.0, 10, 10, 10)
        @test isdir(testing_cache_dir)
        @test res1 == res

        rm(testing_cache_dir; recursive = true)

        @testset "no type" begin
            # test @scache_if
            res = fill(0.0, 10, 10, 10)

            res1 = @scache_if false testing_cache_dir fill(0.0, 10, 10, 10)
            @test !isdir(testing_cache_dir)
            @test res1 == res

            res1 = @scache_if true testing_cache_dir fill(0.0, 10, 10, 10)
            @test isdir(testing_cache_dir)
            @test res1 == res

            rm(testing_cache_dir; recursive = true)

            # test @scachejld_if
            res = fill(0.0, 10, 10, 10)

            res1 = @scachejld_if false testing_cache_dir fill(0.0, 10, 10, 10)
            @test !isdir(testing_cache_dir)
            @test res1 == res

            res1 = @scachejld_if true testing_cache_dir fill(0.0, 10, 10, 10)
            @test isdir(testing_cache_dir)
            @test res1 == res

            rm(testing_cache_dir; recursive = true)

            @testset "no dir" begin
                # test @scache_if
                res = fill(0.0, 10, 10, 10)

                res1 = @scache_if false fill(0.0, 10, 10, 10)
                @test !isdir(SimpleCaching.settings.cache_dir)
                @test res1 == res

                res1 = @scache_if true fill(0.0, 10, 10, 10)
                @test isdir(SimpleCaching.settings.cache_dir)
                @test res1 == res

                rm(SimpleCaching.settings.cache_dir; recursive = true)

                # test @scachejld_if
                res = fill(0.0, 10, 10, 10)

                res1 = @scachejld_if false fill(0.0, 10, 10, 10)
                @test !isdir(SimpleCaching.settings.cache_dir)
                @test res1 == res

                res1 = @scachejld_if true fill(0.0, 10, 10, 10)
                @test isdir(SimpleCaching.settings.cache_dir)
                @test res1 == res

                rm(SimpleCaching.settings.cache_dir; recursive = true)
            end
        end
    end

    # test using macro within another module
    using .A
    res = fill(0.0, 20, 20, 20)
    hc = heavy_computation(cached_type, testing_cache_dir, 0.0, 20, 20, 20)

    @test hc == res

    # test with local variables
    begin
        local n = 10

        @scache cached_type testing_cache_dir vcat(fill(1, n), fill(2, 2n))
    end
end

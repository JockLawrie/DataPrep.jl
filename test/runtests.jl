using Test
using DataPrep

# NOTE: pwd is /path/to/DataPrep.jl/test/
const outdir = joinpath(pwd(), "output")

if !isdir(outdir)
    mkdir(outdir)
end

function cleanup()
    contents = readdir(outdir; join=true)
    for x in contents
        rm(x; recursive=true)
    end
end

# Test sets
cleanup()
include("testset1.jl")  # Describe test set here
cleanup()
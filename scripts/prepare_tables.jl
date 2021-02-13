using Pkg
Pkg.activate(".")
println("Loading DataPrep.jl")
using DataPrep
configfile = ARGS[1]
DataPrep.prepare_tables(configfile)
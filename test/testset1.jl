# Run data prep
configfile = joinpath(pwd(), "config", "testset1.toml")
outdir1 = DataPrep.prepare_tables(configfile)

# Import result
outfile = joinpath(outdir1, "table1.tsv")
result  = DataFrame(CSV.File(outfile; delim='\t', type=String))

# Import target
targetfile = joinpath(pwd(), "data", "table1_target.csv")
target     = DataFrame(CSV.File(outfile; delim=',', type=String))

# Compare

println(output)
println("")
println(target)

@test output == target
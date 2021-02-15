# Run data prep
configfile = joinpath(pwd(), "config", "testset1.toml")
outdir1 = DataPrep.prepare_tables(configfile)

# Import result
outfile = joinpath(outdir1, "output", "table1.tsv")
result  = DataFrame(CSV.File(outfile; delim='\t', type=String))

# Import target
targetfile = joinpath(pwd(), "data", "table1_target.csv")
target     = DataFrame(CSV.File(targetfile; delim=',', type=String))

# Compare

show(result)
println("\n\n")
show(target)
println("\n\n")

@test result == target
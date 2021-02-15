module preparetables

export prepare_tables

using CSV
using DataFrames
using Dates
using Logging
using Schemata

using ..config

"Prepare tables according to the config and return the output directory."
function prepare_tables(configfile::String)
    @info "$(now()) Configuring data prep"
    cfg = DataPrepConfig(configfile)

    @info "$(now()) Initialising output directory: $(cfg.output_directory)"
    d = cfg.output_directory
    mkdir(d)
    mkdir(joinpath(d, "input"))
    mkdir(joinpath(d, "output"))
    cp(configfile, joinpath(d, "input", basename(configfile)))  # Copy config file to d/input
    software_versions = construct_software_versions_table()
    CSV.write(joinpath(d, "input", "SoftwareVersions.csv"), software_versions; delim=',')  # Write software_versions to d/input

    # Prepare tables
    for (tablename, tableconfig) in cfg.tables
        @info "$(now()) Preparing table: $(tablename)"
        prepare_table(tablename, tableconfig, d)
    end
    d
end

function prepare_table(tablename::String, tableconfig::TableConfig, outdir::String)
    n = 1_000_000  # Process rows in batches of 1_000_000
    i = 0          # Current row number in the current batch
    i_total = 0    # Total number of rows processed
    result  = init_table(tableconfig.target_schema, n)
    infile  = tableconfig.input_data_file
    outfile = joinpath(outdir, "output", "$(tablename).tsv")
    CSV.write(outfile, init_table(tableconfig.target_schema, 0); delim='\t')
    for inrow in CSV.Rows(infile; reusebuffer=true)
        i += 1
        outrow = view(result, i:i, :)
        for f in tableconfig.eachrow
            val = f(inrow, outrow)
            if val isa Tuple  # (colname, value)
                result[i, val[1]] = val[2]
            elseif val isa Bool
                if val == false  # Row is not valid...roll back
                    i -= 1
                    continue
                end
            else
                error("Invalid value for function $(j): $(val)")
            end
        end

        # If result is full, write to disk
        if i == n
            CSV.write(outfile, result; delim='\t', append=true)
            i_total += i
            @info "$(now()) Exported $(div(i_total, n))M rows of $(tablename)"
            i = 0  # Reset the row number
        end
    end
    if i != 0  # Write remaining rows if they exist
        CSV.write(outfile, view(result, 1:i, :); delim='\t', append=true)
        i_total += i
        @info "$(now()) Exported $(format_number(i_total)) rows of $(tablename)"
    end
end

################################################################################
# Utils

function construct_software_versions_table()
    pkg_version = get_package_version()
    DataFrame(software=["Julia", "DataPrep.jl"], version=[VERSION, pkg_version])
end

function get_package_version()
    pkg_version = "unknown"
    pkgdir = dirname(@__DIR__)
    f = open(joinpath(pkgdir, "Project.toml"))
    i = 0
    for line in eachline(f)
        i += 1
        if i == 4
            v = split(line, "=")  # line: version = "0.1.0"
            pkg_version = replace(strip(v[2]), "\"" => "")  # v0.1.0
            close(f)
            return pkg_version
        end
    end
end

function init_table(tableschema::TableSchema, n::Int)
    result = DataFrame()
    for colname in tableschema.columnorder
        result[!, colname] = Vector{Union{Missing, String}}(missing, n)
    end
    result
end

"Convert integer to string and insert commas for pretty printing."
function format_number(x::Int)
    s      = string(x)
    n      = length(s)
    lead   = rem(n, 3)  # Number of digits before the 1st comma
    lead   = lead == 0 ? 3 : lead
    result = s[1:lead]
    n_done = lead
    for i= 1:100  # Append remaining digits in groups of 3
        n_done == n && break
        s2 = ",$(s[(n_done + 1):(n_done + 3)])"
        result = result * s2
        n_done += 3
    end
    result
end

end
module config

export DataPrepConfig, TableConfig

using Dates
using Schemata
using TOML

using ..constructeachrow

################################################################################
"""
datafile:   The complete path to the data file.
            If datafile is nothing, then the spine is constructed as part of the run_linkage function.
schemafile: The complete path to the schema file.
schema:     The TableSchema for the data, specified in the schema file.
"""
struct TableConfig
    input_data_file::String
    target_schema_file::String
    target_schema::TableSchema
    eachrow::Vector{Function}  # f(row) = value. If value isa Bool, filter row. If value isa String, set value.

    function TableConfig(input_data_file, target_schema_file, schema, eachrow)
        !isnothing(input_data_file) && !isfile(input_data_file) && error("The input data file for the table does not exist.")
        !isfile(target_schema_file) && error("The schema file for the table does not exist.")
        new(input_data_file, target_schema_file, schema, eachrow)
    end
end

function TableConfig(d::Dict)
    tableschema = readschema(d["target_schema_file"])
    eachrow     = construct_eachrow(d["eachrow"])
    TableConfig(d["input_data_file"], d["target_schema_file"], tableschema, eachrow)
end

################################################################################

struct DataPrepConfig
    projectname::String
    description::String
    output_directory::String
    tables::Dict{String, TableConfig}  # tablename =? tableconfig
end

function DataPrepConfig(configfile::String)
    !isfile(configfile) && error("The config file $(configfile) does not exist.")
    d = TOML.parsefile(configfile)
    DataPrepConfig(d)
end

function DataPrepConfig(d::Dict)
    projectname = d["projectname"]
    description = d["description"]
    dttm        = "$(round(now(), Second(1)))"
    dttm        = replace(dttm, "-" => ".")
    dttm        = replace(dttm, ":" => ".")
    outdir      = joinpath(d["output_directory"], "dataprep-$(projectname)-$(dttm)")
    tables      = Dict(tablename => TableConfig(x) for (tablename, x) in d["tables"])
    DataPrepConfig(projectname, description, outdir, tables)
end

end
module config

export DataPrepConfig, TableConfig

using Dates
using Schemata
using TOML

using ..constructeachrow

################################################################################
"""
input_data_file:    The complete path to the input data file.
target_schema_file: The complete path to the file containing the table's desired schema.
target_schema:      The TableSchema for the data, specified in the target schema file.
"""
struct TableConfig
    input_data_file::String
    target_schema_file::Union{Nothing, String}
    target_schema::Union{Nothing, TableSchema}
    eachrow::Vector{Function}  # f(row) = value. If value isa Bool, filter row. If value isa String, set value.
    colnames::Vector{Symbol}

    function TableConfig(input_data_file, target_schema_file, target_schema, eachrow, colnames)
        !isnothing(input_data_file)    && !isfile(input_data_file)    && error("The input data file for the table does not exist.")
        !isnothing(target_schema_file) && !isfile(target_schema_file) && error("The schema file for the table does not exist.")
        isnothing(target_schema_file)  && !isnothing(target_schema)   && error("Cannot have a schema without a schema file")
        if isnothing(target_schema) && !isnothing(target_schema_file)
            target_schema = readschema(target_schema_file)
        end
        isempty(colnames) && error("The user-supplied operations (eachrow) do not define any columns for the output")
        new(input_data_file, target_schema_file, target_schema, eachrow, colnames)
    end
end

function TableConfig(d::Dict)
    target_schema_file = haskey(d, "target_schema_file") ? d["target_schema_file"] : nothing
    tableschema        = isnothing(target_schema_file) ? nothing : readschema(d["target_schema_file"])
    colnames, eachrow  = construct_eachrow(d["eachrow"])
    TableConfig(d["input_data_file"], target_schema_file, tableschema, eachrow, colnames)
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
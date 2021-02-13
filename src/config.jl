module config

export DataPrepConfig

using Dates
using Schemata
using TOML

struct DataPrepConfig
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
    outdir      = joinpath(d["output_directory"], "linkage-$(projectname)-$(dttm)")
    DataPrepConfig()
end

end
module preparetables

export prepare_tables

using ..config

function prepare_tables(configfile::String)
    cfg = DataPrepConfig(configfile)
end

end
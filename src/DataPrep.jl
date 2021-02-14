module DataPrep

include("constructeachrow.jl")
include("config.jl")
include("preparetables.jl")

using .constructeachrow  # Exports construct_eachrow. No dependencies.
using .config            # Exports DataPrepConfig. Depends on constructeachrow.
using .preparetables     # Exports prepare_tables. Depends on config.

end
module DataPrep

include("config.jl")
include("preparetables.jl")

using .config         # Exports DataPrepConfig. No dependencies.
using .preparetables  # Exports prepare_tables. Depends on config.

end
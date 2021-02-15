module constructeachrow

export construct_eachrow

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

"""
Returns:
- columns: Vector of column names in the output row defined by eachrow.
- eachrow: Vector of operations to be applied to each row of the data.
"""
function construct_eachrow(arr::Vector{String})
    colnames = Symbol[]
    eachrow  = Vector{Function}(undef, length(arr))
    for (i, s) in enumerate(arr)
        if s[1:14] == "retain row if "
            eachrow[i] = construct_filter(s[15:end])
            continue
        end
        idx = findfirst('=', s)
        isnothing(idx) && error("Invalid operation: $(s)")
        colname = Symbol(strip(s[1:(idx - 1)]))
        push!(colnames, colname)
        ex = strip(s[(idx + 1):end])
        if ex[1:6] == "using "
            eachrow[i] = construct_replace(ex[7:end])
        elseif ex == "row satisfies schema"
            eachrow[i] = construct_row_satisfies_schema()
        else
            eachrow[i] = construct_value_constructor(colname, ex)
        end
    end
    colnames, eachrow
end

function construct_value_constructor(colname::Symbol, ex)
    ex = Meta.parse("(input, output) -> (\"$(colname)\", $(ex))")
    @RuntimeGeneratedFunction(ex)
end

function construct_filter(ex)
    ex = Meta.parse("(input, output) -> $(ex)")
    @RuntimeGeneratedFunction(ex)
end

#construct_value_constructor(colname::Symbol, ex) = (input, output) -> (colname, eval(Meta.parse(ex)))

#construct_filter(ex) = (input, output) -> eval(Meta.parse(ex))

function construct_replace(s)
end

function construct_row_satisfies_schema()
end

end
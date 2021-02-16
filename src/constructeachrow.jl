module constructeachrow

export construct_eachrow

using Schemata
using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

const d = Dict{Symbol, Any}()  # Populated by prepare_table(). Keys = [:target_schema, :uniquevalues]

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
            eachrow[i] = construct_filter(strip(s[15:end]))
            continue
        end
        idx = findfirst('=', s)
        isnothing(idx) && error("Invalid operation: $(s)")
        colname = Symbol(strip(s[1:(idx - 1)]))
        push!(colnames, colname)
        ex = strip(s[(idx + 1):end])
        if ex[1:6] == "using "
            eachrow[i] = construct_replace(ex[7:end])
        else
            eachrow[i] = construct_value_constructor(colname, ex)
        end
    end
    colnames, eachrow
end

function construct_value_constructor(colname::Symbol, s)
    if s == "row_satisfies_schema()"
        (inrow, outrow) -> (colname, string(row_satisfies_schema(outrow, d[:target_schema], d[:uniquevalues])))
    else
        ex = Meta.parse("(input, output) -> (\"$(colname)\", $(s))")
        @RuntimeGeneratedFunction(ex)
    end
end

function construct_filter(s)
    if s == "row_satisfies_schema()"
        (inrow, outrow) -> row_satisfies_schema(outrow, d[:target_schema], d[:uniquevalues])
    else
        ex = Meta.parse("(input, output) -> $(s)")
        @RuntimeGeneratedFunction(ex)
    end
end

function construct_replace(s)
end

################################################################################
# Functions that the 3 basic operations can use

"Returns true if outrow satisfies the table schema."
function row_satisfies_schema(outrow, tableschema::TableSchema, uniquevalues)
    # Assess each value in isolation (modified version of Schemata.assessrow!)
    result = true
    for (colname, colschema) in tableschema.colname2colschema
        if !hasproperty(outrow, colname)
            result = false  # Do not return early because we must collect unique values even if the row doesn't satisfy the schema
            continue
        end
        val = getproperty(outrow, colname)
        if ismissing(val) && colschema.isrequired
            result = false  # Do not return early because we must collect unique values even if the row doesn't satisfy the schema
            continue
        end
        if Schemata.value_is_valid(val, colschema.validvalues)
            if colschema.isunique
                if in(val, uniquevalues[colname])
                    result = false  # Do not return early because we must collect unique values even if the row doesn't satisfy the schema
                end
                push!(uniquevalues[colname], val)
            end
            continue
        end
        result = false  # Do not return early because we must collect unique values even if the row doesn't satisfy the schema
    end
    result == false && return false  # Unique values have been collected -> can return early if the row doesn't satisfy the schema

    # Assess intrarow constraints (modified version of Schemata.test_intrarow_constraints!)
    for (msg, f) in tableschema.intrarow_constraints
        ok = @eval $f($outrow)     # Hack to avoid world age problem.
        ismissing(ok) && continue  # This case is picked up at the column level
        !ok && return false
    end
    true
end

end
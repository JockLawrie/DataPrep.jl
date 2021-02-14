module constructeachrow

export construct_eachrow

function construct_eachrow(arr::Vector{String})
    result = Vector{Function}(undef, length(arr))
    for (i, s) in arr
        if s[1:14] == "retain row if "
            result[i] = construct_filter(s[15:end])
            continue
        end
        idx = findfirst('=', s)
        isnothing(idx) && error("Invalid operation: $(s)")
        colname = Symbol(strip(s[1:(idx - 1)]))
        ex = strip(s[(idx + 1):end])
        if ex[1:6] == "using "
            result[i] = construct_replace(ex[7:end])
        elseif ex == "row satisfies schema"
            result[i] = construct_row_satisfies_schema()
        else
            result[i] = construct_value_constructor(colname, ex)
        end
    end
    result
end

function construct_filter(s::String)
    (input, output) -> eval(Meta.parse(ex))
end

function construct_replace(s::String)
end

function construct_row_satisfies_schema()
end

function construct_value_constructor(colname::Symbol, ex::String)
    (input, output) -> (colname, eval(Meta.parse(ex)))
end

end
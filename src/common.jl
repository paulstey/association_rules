# Common types and functions

type Rule
    P::Array{Int64} # Antecedent
    Q::Array{Int64} # Consequent
end

# Support Count: σ(x) = | {tᵢ|x ⊆ t_i, t_i ∈ T}|
function σ(x, T)
    res = 0
    for t in T
        if x ⊆ t
            res += 1
        end
    end
    return res
end

# Support of rule x -> y, which x does not intersect y.
support(x, y, T) = σ(union(x, y), T)/length(T)

# Confidence of rule x -> y, which x does not intersect y.
confidence(x, y, T) = σ(union(x, y), T)/σ(x, T)

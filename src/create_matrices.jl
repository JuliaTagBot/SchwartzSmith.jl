"""
    SSParams

Defines the Schwartz Smith parameters that will be estimated.
"""
mutable struct SSParams{T}
    k::T
    σ_χ::T
    λ_χ::T
    μ_ξ::T
    σ_ξ::T
    μ_ξ_star::T
    ρ_ξχ::T
    s::Vector{T}
end

function A(T, p::SSParams)
    a = p.μ_ξ_star * T - (1 - exp(-p.k * T)) * (p.λ_χ/p.k)
    b = 0.5 * ( (1 - exp(-2 * p.k * T)) * (p.σ_χ^2)/(2 * p.k) + p.σ_ξ^2 * T + 2 * (1 - exp(-p.k * T)) * (p.ρ_ξχ * p.σ_χ * p.σ_ξ)/p.k )
    return a + b
end

function V(p::SSParams)
    for i in eachindex(p.s)
        if p.s[i] > 1e3
            p.s[i] = 1e3
        end
    end
    cov_matrix = Diagonal(p.s.^2)
    ensure_pos_sym!(cov_matrix)
    return cov_matrix
end

function W(p::SSParams, delta_t)
    ρ = (1 - exp(-p.k * delta_t)) * (p.ρ_ξχ * p.σ_χ * p.σ_ξ)/(p.k)
    cov_matrix = [
            (1 - exp(-2 * p.k * delta_t)) * (p.σ_χ^2)/(2 * p.k)     ρ
            ρ                                                       p.σ_ξ^2 * delta_t
    ]

    ensure_pos_sym!(cov_matrix)
    return cov_matrix
end

function G(p::SSParams, n_exp::Int64, delta_t)
    G_aux = [exp(-p.k * delta_t)     0
        0                       1]

    if n_exp == 0
        return G_aux
    else
        G_s = zeros(Float64, 2 + n_exp, 2 + n_exp)

        G_s[1:2, 1:2]      = G_aux
        G_s[3:end, 3:end]  = 1 .* Matrix(I, n_exp, n_exp)

        return G_s
    end
end

function c(p::SSParams, n_exp::Int64, delta_t)
    return [0; p.μ_ξ * delta_t; zeros(n_exp)]
end

function d(T::Vector{Typ}, p::SSParams) where Typ
    A_vec = Vector{Typ}(undef,length(T))
    for (i, t) in enumerate(T)
        A_vec[i] = A(t, p)
    end

    return A_vec
end

function F(T::Vector{Typ}, p::SSParams, X_t::Vector) where Typ
    n_exp = length(X_t)

    F_aux = Matrix{Typ}(undef, length(T), 2)
    for (i, t) in enumerate(T)
        e = exp(-p.k * t)

        if e <= 1e-8
            F_aux[i, 1] = 1e-8
        else
            F_aux[i, 1] = exp(-p.k * t)
        end

        F_aux[i, 2] = 1
    end

    if n_exp == 0
        return F_aux
    else
        F_s = Matrix{Float64}(undef, length(T), 2 + n_exp)
        F_s[:, 1:2]    = F_aux
        F_s[:, 3:end] .= X_t'

        return F_s
    end
end

function R(n_exp::Int64)
    R_aux = 1 .* Matrix(I, 2, 2)

    if n_exp == 0
        return R_aux
    else
        return [R_aux; zeros(n_exp, 2)]
    end
end

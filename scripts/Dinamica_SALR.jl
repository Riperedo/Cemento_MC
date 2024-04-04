using NESCGLE
using JSON

function main(args...)
    # user inputs
    ϕ_str, A_str, z1_str, z2_str =  args

    # variable definition
    ϕ = parse(Float64, ϕ_str)
    A = parse(Float64, A_str)
    z1 = parse(Float64, z1_str)
    z2 = parse(Float64, z2_str)
    # preparing saving folder
    save_path = NESCGLE.make_directory("SCGLE")
    save_path = NESCGLE.make_directory(save_path*"SALR")
    save_path = NESCGLE.make_directory(save_path*"phi"*num2text(ϕ))
    save_path = NESCGLE.make_directory(save_path*"A"*num2text(A))
    save_path = NESCGLE.make_directory(save_path*"z1"*num2text(z1))
    save_path = NESCGLE.make_directory(save_path*"z2"*num2text(z2))
    filename = save_path*"output.json"
    if !isfile(filename)
        println("Running SCGLE")
        # wave vector # WARNING NaN at k=0 for this system
        k = collect(0.01:0.1:15*π)
        
        # computing Static structures
        #I = T != 0 ? Input_Yukawa(ϕ, 1/T, z, k) : Input_HS(ϕ, k, VW=true)
        I = Input_SALR(ϕ, A, z1, A, z2, k)
        S = structure_factor(I)
        # computing dynamics
        τ, Fs, F, Δζ, Δη, D, W = SCGLE(I)
        # parsing to json file
        structural_data = Dict("k"=>k, "S"=>S)
        dynamics_data = Dict("tau"=>τ, "sISF"=>Fs, "ISF"=>F, "Dzeta"=>Δζ, "Deta"=>Δη, "D"=>D, "MSD"=>W)
        data = Dict("Statics"=>structural_data, "Dynamics"=>dynamics_data)
        # saving data
        open(filename, "w") do file
            JSON.print(file, data)
        end
    end
    println("Calculation complete.")
end

@time main(ARGS...)
#julia Eq_YA_script.jl 0.25 1.5 2.0

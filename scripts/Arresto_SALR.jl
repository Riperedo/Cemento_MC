using NESCGLE
using JSON

#Función que calcula el punto crítico de la inestabilidad termodinámica
function PuntoCritico(LambdaArray)
    TuplaCrit = findmax(LambdaArray)
    Tcrit=TuplaCrit[1]
    return Tcrit
end

function difrel(Tcvieja)
    Tc=Tcvieja/0.2
    dif=round(abs(1-(1.95/Tc))*100)
    rel=1.95/Tc
    Tcelcius=1450*dif
    if rel<1
        Tclinker=round(1450-Tcelcius)
        par="menos"
    else
        Tclinker=round(1450+Tcelcius)
        par="mas"
    end

    CO2gen=(Tclinker/21000)
    
    #println("La nueva temperatura de clinkerizacion es: ",Tclinker)
    #println("Haz contaminado ",dif,"% ",par)
    #println("Generas ", CO2gen, "kg de CO2 por kg de cemento")

    return dif, Tclinker, CO2gen
end

#function main(args...)
function main(A, z1, z2)
    # user inputs
    #A_str, z1_str, z2_str =  args
    
    # variable definition
    #A = parse(Float64, A_str) # number of times the repulsion is bigger than the atrtration
    #z1 = parse(Float64, z1_str)
    #z2 = parse(Float64, z2_str)

    # preparing saving folder
    save_path = NESCGLE.make_directory("SCGLE")
    save_path = NESCGLE.make_directory(save_path*"SALR")
    save_path = NESCGLE.make_directory(save_path*"A"*num2text(A))
    save_path = NESCGLE.make_directory(save_path*"z1"*num2text(z1))
    save_path = NESCGLE.make_directory(save_path*"z2"*num2text(z2))
    filename_a = save_path*"arrest_SALR_A"*num2text(A)*"_z1"*num2text(z1)*"_z2"*num2text(z2)*".json"
    filename_l = save_path*"lambda_SALR_A"*num2text(A)*"_z1"*num2text(z1)*"_z1"*num2text(z1)*"_z2"*num2text(z2)*".json"
    filename_s = save_path*"spinodal_SALR_A"*num2text(A)*"_z1"*num2text(z1)*"_z1"*num2text(z1)*"_z2"*num2text(z2)*".json"
    filename_CO2 = save_path*"CO2_A"*num2text(A)*"_z1"*num2text(z1)*"_z1"*num2text(z1)*"_z2"*num2text(z2)*".json"
    
    if !isfile(filename_l)
        # computiing lambda
        phi = collect(0.01:0.01:0.45)
        T_lambda = zeros(length(phi))
        T_min = 1e-6
        T_max = 1e1
            
        # preparing Input object
        k = collect(0.01:0.1:15*π)

        # main loop
        for (i, ϕ) in enumerate(phi)
            println("Computing ϕ= ", ϕ)
            function condition(T)
                I = Input_SALR(ϕ, 1/T, z1, A/T, z2, k)
                S = structure_factor(I)
                return sum(S .< 0.0) == 0
            end
            T_lambda[i] = NESCGLE.bisection(condition, T_max, T_min, 1e-3)
        end
        # calculando CO2
        Tc = PuntoCritico(T_lambda)
        dif, Tclinker, CO2gen = difrel(Tc)
        #saving data
        data = Dict("dif"=>dif, "Tclinker"=>Tclinker, "CO2gen"=>CO2gen, "A"=>A, "z1"=>z1, "z2"=>z2)
        open(filename_CO2, "w") do file
            JSON.print(file, data)
        end
        
        #saving data
        data = Dict("phi"=>phi, "Temp"=>T_lambda)
        open(filename_l, "w") do file
            JSON.print(file, data)
        end
        save_data("test_lambda.dat", [phi T_lambda])
    end

    if !isfile(filename_s)
        # computiing spinodal
        phi = collect(0.01:0.01:0.45)
        T_s = zeros(length(phi))
        T_min = 1e-6
        T_max = 1e1
            
        # preparing Input object
        k = collect(0.01:0.01:0.1)

        # main loop
        for (i, ϕ) in enumerate(phi)
            println("Computing ϕ= ", ϕ)
            function condition(T)
                I = Input_SALR(ϕ, 1/T, z1, A/T, z2, k)
                S = structure_factor(I)
                return sum(S .< 0.0) == 0
            end
            T_s[i] = NESCGLE.bisection(condition, T_max, T_min, 1e-3)
        end
        #saving data
        data = Dict("phi"=>phi, "Temp"=>T_s)
        open(filename_s, "w") do file
            JSON.print(file, data)
        end
        save_data("test_s.dat", [phi T_s])
    end
    # TO DO binodal
    if !isfile(filename_a)
        # preparing ϕ-T space grid
        dict = JSON.parsefile(filename_l)
        Phi = dict["phi"]
        T_l = dict["Temp"]
        dict = JSON.parsefile(filename_s)
        Phi = dict["phi"]
        T_s = dict["Temp"]
        phi = zeros(length(Phi))
        Temperature = zeros(length(phi))
        T_max = 1e1
        
        # preparing Input object
        k = collect(0.1:0.1:25*π)

        # main loop
        for (i, ϕ) in enumerate(Phi)
            println("Computing ϕ= ", ϕ)
            function condition(T)
                I = Input_SALR(ϕ, 1/T, z1, A/T, z2, k)
                iterations, gammas, system = Asymptotic(I, flag = false)
                return system == "Glass"
            end
            phi[i] = ϕ
            Temperature[i] = NESCGLE.bisection(condition, max(T_s[i], T_l[i]), T_max, 1e-6)
        end
        #saving data
        data = Dict("phi"=>phi, "Temp"=>Temperature)
        open(filename_a, "w") do file
            JSON.print(file, data)
        end
        save_data("test.dat", [phi Temperature])
    end
    
    println("Calculation complete.")
end

#@time main(ARGS...)
for A in 0.0:0.1:2.0
    for z1 in 0.1:0.1:5.0
        z2 = 0.5
        main(A, z1, z2)
    end
end

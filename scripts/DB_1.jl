using NESCGLE
using JSON

#Función que calcula el punto crítico de la inestabilidad termodinámica
function PuntoCritico(LambdaArray)
    TuplaCrit = findmax(LambdaArray)
    Tcrit = TuplaCrit[1]
    return Tcrit
end

function difrel(Tcvieja)
    Tc = Tcvieja*5
    rel = Tc/1.95
    dif = Float16(rel-1)
    Tcelcius=1450*dif
    par = ""
    if dif>0
        Tclinker=Float16(1450+Tcelcius)
        par *= "menos"
    else
        Tclinker=Float16(1450+Tcelcius)
        par *= "más"
    end

    CO2gen=Float16(Tclinker/21000)
    
    return dif, Tclinker, CO2gen, par
end


Col1 = [] #A
Col2 = [] #z1
Col3 = [] #z2
Col4 = [] #phi
Col5 = [] #lambda
Col6 = [] #spinodal
Col7 = [] #arrest

# csv promt
A_ = []
z1_ = []
z2_ = []
prompt_ = []
Tc_ = []
dif_ = []
Tclinker_ = []
CO2gen_ = []

# main loop
z2 = 0.5
for A in 0.0:0.1:2.0
    for z1 in 0.1:0.1:5.0
        # preparing saving folder and file paths
        save_path = NESCGLE.make_directory("SCGLE")
        save_path = NESCGLE.make_directory(save_path*"SALR")
        save_path = NESCGLE.make_directory(save_path*"A"*num2text(A))
        save_path = NESCGLE.make_directory(save_path*"z1"*num2text(z1))
        save_path = NESCGLE.make_directory(save_path*"z2"*num2text(z2))
        filename_a = save_path*"arrest_SALR_A"*num2text(A)*"_z1"*num2text(z1)*"_z2"*num2text(z2)*".json"
        filename_l = save_path*"lambda_SALR_A"*num2text(A)*"_z1"*num2text(z1)*"_z1"*num2text(z1)*"_z2"*num2text(z2)*".json"
        filename_s = save_path*"spinodal_SALR_A"*num2text(A)*"_z1"*num2text(z1)*"_z1"*num2text(z1)*"_z2"*num2text(z2)*".json"

        # reading data
        dict = JSON.parsefile(filename_l)
        Phi = dict["phi"]
        T_lambda = dict["Temp"]
        dict = JSON.parsefile(filename_s)
        T_spinodal = dict["Temp"]
        dict = JSON.parsefile(filename_a)
        T_arrest = dict["Temp"]
        Tc = PuntoCritico(T_lambda)
        dif, Tclinker, CO2gen, par = difrel(Tc)

        prompt = "La nueva temperatura de clinkerizacion es: $Tclinker\n"
        prompt *= "Haz contaminado $dif% $par\n" 
        prompt *= "Generas $CO2gen kg de CO2 por kg de cemento"

        println(prompt)
        # reset path
        save_path = ""
        # append data to DB1
        append!(Col1, A*ones(length(Phi)))
        append!(Col2, z1*ones(length(Phi)))
        append!(Col3, z2*ones(length(Phi)))
        append!(Col4, Phi)
        append!(Col5, T_lambda)
        append!(Col6, T_spinodal)
        append!(Col7, T_arrest)
        # append data to DB1
        append!(A_, A)
        append!(z1_, z1)
        append!(z2_, z2)
        append!(Tc_, Tc)
        append!(dif_, dif)
        append!(Tclinker_, Tclinker)
        append!(CO2gen_, CO2gen)
        append!(prompt_, prompt)
    end
end

#save_data("database.csv", [Col1 Col2 Col3 Col4 Col5 Col6 Col7], header = "A,z1,z2,phi,lambda,spinodal,arrest")
save_data("database2.csv", [A_ z1_ z2_ Tc_ dif_ Tclinker_ CO2gen_], header = "A, z1, z2, Tc, dif, Tclinker, CO2gen, prompt")

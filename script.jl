# Extracted Julia chunks from index.qmd

# ---- Chunk 1 ----

# Load necessary packages

using Pkg;
Pkg.activate(pwd());
using Dates;
using CSV;
using DataFrames;
using HTTP;
using CDSAPI;
using Statistics;
using NCDatasets;
using Plots;
using Plots.PlotMeasures;

# ---- Chunk 2 ----
# Function to convert wide format data to long format

function longseries(data)
    height = size(data, 1) # Number of rows, equivalent to the number of years;
    last_row = 12 - count(ismissing, data[end, 2:13]) # Number of non-missing months in the last year;

    many = (height - 1) * 12 + last_row # Total number of months in the long format;
    long = zeros(many, 1) # Long format array;

    for ii = 1:(height-1) # Loop through all years except the last one;
        for jj = 1:12 # Loop through all months;
            long[(ii-1)*12+jj] = data[ii, jj+1];
        end
    end

    for jj = 1:last_row # Loop through the last year;
        long[(height-1)*12+jj] = data[height, jj+1];
    end

    return long
end;

# ---- Chunk 3 ----
# Download the HadCRUT temperature data 
# URL of the HadCRUT5 global monthly average CSV
hurl = "https://www.metoffice.gov.uk/hadobs/hadcrut5/data/HadCRUT.5.1.0.0/analysis/diagnostics/HadCRUT.5.1.0.0.analysis.summary_series.global.monthly.csv";
# Local filename to save
hfilename = "data/HadCRUT5_global_monthly_average.csv";
open(hfilename, "w") do io
    write(io, HTTP.get(hurl).body)
end;

rawhadcrut = CSV.read(hfilename, DataFrame);
rename!(rawhadcrut, :Time => :Date);
rename!(rawhadcrut, :"Anomaly (deg C)" => :RawTemperature);

hadcrut = rawhadcrut[!, [:Date, :RawTemperature]];

oldbase = mean(hadcrut[(hadcrut.Date .>= Date(1850, 1, 1)) .& (hadcrut.Date .< Date(1900, 1, 1)), :RawTemperature]);
hadcrut[!, :Temp] = hadcrut[!, :RawTemperature] .- oldbase;

CSV.write(hfilename, hadcrut);

last(hadcrut, 5) # Show the first 5 rows of the HadCRUT5 data;

# ---- Chunk 4 ----
# Download the GISTEMP temperature data 
# URL of the GISTEMP global monthly average CSV
gurl = "https://data.giss.nasa.gov/gistemp/tabledata_v4/GLB.Ts%2BdSST.csv";
# Local filename to save
gfilename = "data/GISTEMP_global_monthly_average.csv";
# Download the file

open(gfilename, "w") do io
    write(io, HTTP.get(gurl).body)
end;

longgistemp = CSV.read(gfilename, DataFrame, header=2, missingstring=["***"]);
gistemp = longseries(longgistemp)[:];
Tt = length(gistemp) - 1;

start = Date(1880, 1, 1); # Start date of the dataset;
fin = start + Month(Tt); # End date of the dataset;
fechas = collect(start:Month(1):fin); # Create a Date array;

gistemp = DataFrame(:Date=>fechas, :RawTemp=>gistemp);

oldbase = mean(gistemp[(gistemp.Date .>= Date(1880, 1, 1)) .& (gistemp.Date .< Date(1900, 1, 1)), :RawTemp]);
gistemp[!, :Temp] = gistemp[!, :RawTemp] .- oldbase .+ 0.038 # Adjust for pre-1880 data;

CSV.write(gfilename, gistemp);

last(gistemp, 5) # Show the first 5 rows of the GISTEMP data;

# ---- Chunk 5 ----
# Download the NOAAGlobalTemp temperature data 
# URL of the NOAAGlobalTemp global monthly average CSV ---yearmonth.asc
nurl = "https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v6.1/access/timeseries/aravg.mon.land_ocean.90S.90N.v6.1.0.202605.asc";
# Local filename to save
nfilename = "data/NOAA_global_monthly_average.csv";

# Download the file
open(nfilename, "w") do io
    write(io, HTTP.get(nurl).body)
end;

lines = readlines(nfilename);
cleaned_lines = [join(split(strip(line)), ",") for line in lines];

# Write to file
write(nfilename, join(cleaned_lines, "\n"));

rawnoaa = CSV.read(nfilename, DataFrame; delim=(','), header=0);

fechas = Date.(rawnoaa.Column1, rawnoaa.Column2, 1) # Create Date column from Column1 and Column2;

noaa = DataFrame(:Date=>fechas, :RawTemp=>rawnoaa.Column3);

oldbase = mean(noaa[(noaa.Date .>= Date(1850, 1, 1)) .& (noaa.Date .< Date(1900, 1, 1)), :RawTemp]);
noaa[!, :Temp] = noaa[!, :RawTemp] .- oldbase;

CSV.write(nfilename, noaa);

last(noaa, 5) # Show the first 5 rows of the NOAAGlobalTemp data;

# ---- Chunk 6 ----

# Download the Berkeley Earth temperature data
# URL of the Berkeley Earth global monthly average CSV
burl = "https://storage.googleapis.com/berkeley-earth-temperature-hr/global/Global_TAVG_monthly.txt";
# Local filename to save
bfilename = "data/BerkeleyEarth_global_monthly_average.csv";
# Download the file
open(bfilename, "w") do io
    write(io, HTTP.get(burl).body)
end;

rawtemp = CSV.read(bfilename, DataFrame, comment="%", delim=" ", ignorerepeated=true);


colnames = [:Year, :Month, :Anomaly_Monthly, :Unc_Monthly,
    :Anomaly_Annual, :Unc_Annual, :Anomaly_5yr, :Unc_5yr,
    :Anomaly_10yr, :Unc_10yr, :Anomaly_20yr, :Unc_20yr];
rename!(rawtemp, colnames);

rawtemp.Date = Date.(rawtemp.Year, rawtemp.Month, 1) # Create Date column from Year and Month;
rename!(rawtemp, :Anomaly_Monthly => :RawTemperature);

berkeley = rawtemp[!, [:Date, :RawTemperature]];

oldbase = mean(rawtemp[(rawtemp.Date .>= Date(1850, 1, 1)) .& (rawtemp.Date .< Date(1900, 1, 1)), :RawTemperature]);
rawtemp[!, :Temp] = rawtemp[!, :RawTemperature] .- oldbase;

berkeley.Temp = rawtemp.Temp;

CSV.write(bfilename, berkeley);

last(berkeley, 5) # Show the first 5 rows of the Berkeley Earth data;

# ---- Chunk 7 ----

dataset = "reanalysis-era5-single-levels-monthly-means";

request = """{
    "product_type": ["monthly_averaged_reanalysis"],
    "variable": ["2m_temperature"],
    "year": [ "2026" ],
    "month": [
        "01", "02", "03",
        "04", "05", "06",
        "07", "08", "09",
        "10", "11", "12"
    ],
    "time": ["00:00"],
    "data_format": "netcdf",
    "download_format": "unarchived"
}""";

CDSAPI.retrieve(dataset, request, "data/era5_2m_temperature.nc");

# ---- Chunk 8 ----
filename = "data/era5_2m_temperature.nc";
ds = NCDataset(filename, "r");

lat_era = ds["latitude"][:];
lon_era = ds["longitude"][:];
time_era = ds["valid_time"][:];
date_era = Date.(time_era);
lat = lat_era * π/180;

# ---- Chunk 9 ----
chunk_size = 120; # Number of months to process per chunk;

global_mean_C = zeros(length(date_era));

# ---- Chunk 10 ----
if !isempty(date_era)
    for ini in 1:chunk_size:length(date_era)
        final_idx = minimum([ini + chunk_size - 1, length(date_era)]);

        for i in ini:final_idx
            t2m = ds["t2m"][:, :, i]  # 2D slice [lon, lat] for first time; in K;
            t_lon_mean = mean(t2m, dims=1)  # [lat]; drops new dim=2;
            weights = cos.(lat)
            global_mean_K = sum(t_lon_mean' .* weights) / sum(weights)
            global_mean_C[i] = global_mean_K - 273.15
        end;

        display(global_mean_C[ini:final_idx]);

    end;
end;

era_5_update = DataFrame(Date=date_era, RawTemperature=global_mean_C);

# ---- Chunk 11 ----

era_5_raw = CSV.read("data/ERA5_global_monthly_average_raw.csv", DataFrame);
era5_raw = vcat(
    filter(row -> row.Date < minimum(era_5_update.Date), era_5_raw),
    era_5_update
);

CSV.write("data/ERA5_global_monthly_average_raw.csv", era5_raw);

# ---- Chunk 12 ----

time_dates = Date.(era5_raw.Date);

# ---- Chunk 13 ----
time_dates = Date.(era5_raw.Date);
start_1991 = findfirst(≥(Date(1991, 1, 1)), time_dates);
end_2020 = findfirst(≥(Date(2021, 1, 1)), time_dates) - 1;
n_clim = end_2020 - start_1991 + 1  # ~360;

month_clim = zeros(12);
for m in 1:12
    idx = (month.(time_dates[start_1991:end_2020]) .== m);
    month_clim[m] = mean(era5_raw.RawTemperature[start_1991:end_2020][idx]);
end;

anom_1991_2020 = era5_raw.RawTemperature .- month_clim[month.(time_dates)];
offset_preind = 0.88  # Latest ERA5-to-1850-1900; check HadCRUT5 [web:73];
pa_anom = anom_1991_2020 .+ offset_preind;

println("2025 annual PA anomaly: ", round(mean(pa_anom[(end-11):end]), digits=2), "°C");

era5 = DataFrame(Date=time_dates, RawTemperature=anom_1991_2020, Temp=pa_anom);
CSV.write("data/ERA5_global_monthly_average.csv", era5);

# ---- Chunk 14 ----
erafilename = "data/ERA5_global_monthly_average.csv";
era5 = CSV.read(erafilename, DataFrame);

# ---- Chunk 15 ----
last(era5, 5) # Show the first 5 rows of the ERA5 data;

# ---- Chunk 16 ----
# Download the ONI data
ourl = "https://www.cpc.ncep.noaa.gov/data/indices/sstoi.indices";
ofilename = "data/Nino_data.csv";

open(ofilename, "w") do io
    write(io, HTTP.get(ourl).body);
end;

lines = readlines(ofilename);
cleaned_lines = [join(split(strip(line)), ",") for line in lines];

# Write to file
write(ofilename, join(cleaned_lines, "\n"));

rawoni = CSV.read(ofilename, DataFrame; delim=(','), header=1);
fechas = Date.(rawoni.YR, rawoni.MON, 1) # Create Date column from YR and MON;

oni = DataFrame(Date=fechas, Anom=rawoni[!, :ANOM_3]);

CSV.write(ofilename, oni);

last(oni, 5) # Show the first 5 rows of the ONI data;

# ---- Chunk 17 ----
# Load the datasets
hfilename = "data/HadCRUT5_global_monthly_average.csv";
gfilename = "data/GISTEMP_global_monthly_average.csv";
nfilename = "data/NOAA_global_monthly_average.csv";
bfilename = "data/BerkeleyEarth_global_monthly_average.csv";
erafilename = "data/ERA5_global_monthly_average.csv";
ofilename = "data/Nino_data.csv";

hadcrut = CSV.read(hfilename, DataFrame);
gistemp = CSV.read(gfilename, DataFrame);
noaa = CSV.read(nfilename, DataFrame);
berkeley = CSV.read(bfilename, DataFrame);
era5 = CSV.read(erafilename, DataFrame);
oni = CSV.read(ofilename, DataFrame);

# Dates
min_date = minimum([minimum(hadcrut.Date), minimum(gistemp.Date), minimum(noaa.Date), minimum(berkeley.Date), minimum(oni.Date)]);
max_date = maximum([maximum(hadcrut.Date), maximum(gistemp.Date), maximum(noaa.Date), maximum(berkeley.Date), maximum(oni.Date)]);
complete_dates = collect(min_date:Month(1):max_date);
compiled_data = DataFrame(Date=complete_dates);

# HadCRUT5
compiled_data = leftjoin(compiled_data, hadcrut, on=:Date);
rename!(compiled_data, :RawTemperature => :HadCRUT_RawTemperature);
rename!(compiled_data, :Temp => :HadCRUT_Temp);
sort!(compiled_data, :Date);

# GISTEMP
compiled_data = leftjoin(compiled_data, gistemp, on=:Date);
rename!(compiled_data, :RawTemp => :GISTEMP_RawTemperature);
rename!(compiled_data, :Temp => :GISTEMP_Temp);
sort!(compiled_data, :Date);

# NOAA
compiled_data = leftjoin(compiled_data, noaa, on=:Date);
rename!(compiled_data, :RawTemp => :NOAA_RawTemperature);
rename!(compiled_data, :Temp => :NOAA_Temp);
sort!(compiled_data, :Date);

# Berkeley Earth
compiled_data = leftjoin(compiled_data, berkeley, on=:Date);
rename!(compiled_data, :RawTemperature => :Berkeley_RawTemperature);
rename!(compiled_data, :Temp => :Berkeley_Temp);
sort!(compiled_data, :Date);

# ERA5
compiled_data = leftjoin(compiled_data, era5, on=:Date);
rename!(compiled_data, :RawTemperature => :ERA5_RawTemperature);
rename!(compiled_data, :Temp => :ERA5_Temp);
sort!(compiled_data, :Date);

# ONI
compiled_data = leftjoin(compiled_data, oni, on=:Date);
rename!(compiled_data, :Anom => :ONI_Anomaly);
sort!(compiled_data, :Date);

# Save the compiled data
compiled_filename = "data/Compiled_Global_Temperature_Data.csv";
CSV.write(compiled_filename, compiled_data);

last(compiled_data, 5) # Show the last 5 rows of the compiled data;

# ---- Chunk 18 ----
# Load the compiled data and plot packages

compiled_data = CSV.read(compiled_filename, DataFrame);

# Set plot aesthetics
theme(:ggplot2);
default(;
    fontfamily="Computer Modern",
    tickfontsize=10,
    legendfontsize=10,
    titlefontsize=12,
    xlabelfontsize=10,
    ylabelfontsize=10,
    titlefontfamily="Computer Modern",
    legendfontfamily="Computer Modern",
    tickfontfamily="Computer Modern"
);

# Extract the dates for x-axis ticks
# This will be used for the x-axis ticks in the plot
xls = compiled_data.Date;

# ---- Chunk 19 ----
# Plot the data one dataset at a time, for clarity
p = plot(compiled_data.Date, compiled_data.HadCRUT_Temp, label="HadCRUT5", xlabel="Date (monthly)", ylabel="Temperature Anomaly (°C)", title="Global Temperature Anomalies", linewidth=0.5, markershape=:circle, markersize=1);
plot!(compiled_data.Date, compiled_data.GISTEMP_Temp, label="GISTEMP", xlabel="Date (monthly)", ylabel="Temperature Anomaly (°C)", title="Global Temperature Anomalies", linewidth=0.5, markershape=:diamond, markersize=1);
plot!(compiled_data.Date, compiled_data.NOAA_Temp, label="NOAAGlobalTemp", xlabel="Date (monthly)", ylabel="Temperature Anomaly (°C)", title="Global Temperature Anomalies", linewidth=0.5, markershape=:+, markersize=1);
plot!(compiled_data.Date, compiled_data.Berkeley_Temp, label="Berkeley Earth", xlabel="Date (monthly)", ylabel="Temperature Anomaly (°C)", title="Global Temperature Anomalies", linewidth=0.5, markershape=:xcross, markersize=1);
plot!(compiled_data.Date, compiled_data.ERA5_Temp, label="ERA5", xlabel="Date (monthly)", ylabel="Temperature Anomaly (°C)", title="Global Temperature Anomalies", linewidth=0.5, markershape=:star, markersize=1);
plot!(legend=:topleft, xticks=(xls[1:180:end], Dates.format.(xls[1:180:end], "Y"))) # Set x-axis ticks every 180 months;
display(p);

# ---- Chunk 20 ----
# Save the plot

savefig("data/Global_Temperature_Anomalies.pdf");
savefig("data/Global_Temperature_Anomalies.png");

# ---- Chunk 21 ----
# Zoom in on the last 30 years of data

compiled_data_zoomed = compiled_data[compiled_data.Date .>= Date(1995, 1, 1), :];

p_zoomed = plot(compiled_data_zoomed.Date, compiled_data_zoomed.HadCRUT_Temp, label="HadCRUT5", xlabel="Date (monthly)", ylabel="Temperature Anomaly (°C)", title="Global Temperature Anomalies (Last 30 Years)", linewidth=0.5, markershape=:circle, markersize=1);
plot!(compiled_data_zoomed.Date, compiled_data_zoomed.GISTEMP_Temp, label="GISTEMP", xlabel="Date (monthly)", ylabel="Temperature Anomaly (°C)", title="Global Temperature Anomalies (Last 30 Years)", linewidth=0.5, markershape=:diamond, markersize=1);
plot!(compiled_data_zoomed.Date, compiled_data_zoomed.NOAA_Temp, label="NOAAGlobalTemp", xlabel="Date (monthly)", ylabel="Temperature Anomaly (°C)", title="Global Temperature Anomalies (Last 30 Years)", linewidth=0.5, markershape=:+, markersize=1);
plot!(compiled_data_zoomed.Date, compiled_data_zoomed.Berkeley_Temp, label="Berkeley Earth", xlabel="Date (monthly)", ylabel="Temperature Anomaly (°C)", title="Global Temperature Anomalies (Last 30 Years)", linewidth=0.5, markershape=:xcross, markersize=1);
plot!(compiled_data_zoomed.Date, compiled_data_zoomed.ERA5_Temp, label="ERA5", xlabel="Date (monthly)", ylabel="Temperature Anomaly (°C)", title="Global Temperature Anomalies (Last 30 Years)", linewidth=0.5, markershape=:star, markersize=1);
plot!(legend=:topleft, xticks=(compiled_data_zoomed.Date[1:60:end], Dates.format.(compiled_data_zoomed.Date[1:60:end], "Y")));
display(p_zoomed);

# ---- Chunk 22 ----
# Save the zoomed plot

savefig("data/Global_Temperature_Anomalies_Last_30_Years.pdf");
savefig("data/Global_Temperature_Anomalies_Last_30_Years.png");

# ---- Chunk 23 ----
# Classify SST anomalies into El Niño, La Niña, and Neutral events

ONI_Anomaly = compiled_data_zoomed.ONI_Anomaly[.!ismissing.(compiled_data_zoomed.ONI_Anomaly)];

T = length(ONI_Anomaly);
indicator = zeros(Int, T);

for i in 1:T
    if ONI_Anomaly[i] >= 0.5
        indicator[i] = 1;
    elseif ONI_Anomaly[i] <= -0.5
        indicator[i] = -1;
    else
        indicator[i] = 0;
    end
end;

# ---- Chunk 24 ----
p_zoomed_oni = p_zoomed;

let i = 1
    while i <= length(indicator)

        current_val = indicator[i];
        if current_val in (-1, 1)

            start_idx = i;
            while i <= length(indicator) && indicator[i] == current_val
                i = i + 1;
            end;
            stop_idx = i - 1;
            if (stop_idx <= start_idx) || (stop_idx - start_idx < 4)
                continue;
            else

                vspan!(p_zoomed_oni, [compiled_data_zoomed.Date[start_idx], compiled_data_zoomed.Date[stop_idx]], color=current_val == 1 ? :red : :blue, alpha=0.1, label="");
            end
        else
            i = i + 1;
        end;
    end;
end;

display(p_zoomed_oni);

# ---- Chunk 25 ----

# Save the plot with ONI events

savefig("data/Global_Temperature_Anomalies_Last_30_Years_ONI.pdf");
savefig("data/Global_Temperature_Anomalies_Last_30_Years_ONI.png");
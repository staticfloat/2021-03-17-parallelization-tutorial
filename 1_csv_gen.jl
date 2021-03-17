@info("Loading packages...")
using CSV, Scratch, DSP, DataFrames, Printf

## Setup parameters
begin
    # We're going to generate a bunch of noisy, random-frequency sinusoids
    # in each file, and we'll do some processing of those sinusoids
    num_files = 30
    num_sinusoids = 200 # Set this to `2000` for the big CSVs
    if num_sinusoids >= 2000
        output_dir = @get_scratch!("generated_csvs")
    else
        output_dir = @get_scratch!("generated_csvs_small")
    end
    num_datapoints = 10000
    fs = 1000
    
    center_frequency = 4
    frequency_randomization_amount = 1.5
    frequency_modulation_amount = 0.5
    noise_amount = 0.05
end

## Helper function to generate a randomly-walking sinusoid
function generate_sinusoid(N, fs, wc, fr_amnt, fm_amnt, noise_amnt)
    t = 2π*(0:(N-1))/fs

    # if we have some frequency modulation, we apply a sinusoidal
    # wobble to the center frequency over time
    ϕ_fm = 2π*rand()
    ω = t .* (wc .+ (rand() - .5)*fr_amnt .+ (fm_amnt .* sin.(0.1*t .+ ϕ_fm)))
    ϕ = 2π*rand()
    return sin.(ω .+ ϕ) .+ (noise_amnt * rand()) .* randn(N)
end

function generate_mod_envelope(N, amnt)
    m = resample(amnt * randn(8) .+ (1 - amnt), N/3)
    return m[1:N]
end

function generate_sin_bundle(N, K, fs, wc, fr_amnt, fm_amnt, noise_amnt)
    # First, generate a modulation envelope that we'll apply to each sinusoid
    m = generate_mod_envelope(N, 0.3)

    # Next, generate as many sinusoids as we've been paid for, applying the modulation envelope:
    sinusoids = Array{Float64}(undef, N, K)
    for k in 1:K
        sinusoids[:, k] = .2*m .+ m .* generate_sinusoid(N, fs, wc, fr_amnt, fm_amnt, noise_amnt)
    end
    return m, sinusoids
end
generate_sin_bundle() = generate_sin_bundle(num_datapoints, num_sinusoids, fs, center_frequency, frequency_randomization_amount, frequency_modulation_amount, noise_amount)

function generate_csv_file(idx)
    m, sinusoids = generate_sin_bundle()
    df = DataFrame(sinusoids, ["trace_$(x)" for x in 1:num_sinusoids])
    # Also add the modulation envelope
    df[!, :modulator] = m
    CSV.write(joinpath(output_dir, @sprintf("%02d.csv", idx)), df)
end

## Write all these CSV files out to disk
for idx in 0:(num_files-1)
    @info("Generating $(idx+1)/$(num_files)")
    generate_csv_file(idx)
end

## To visualize one of these "sin bundles"
using Plots
begin
    m, sinusoids = generate_sin_bundle()
    plot(sinusoids[:, 1:3])
end
# Die if we forgot to set `-t`
if Threads.nthreads() == 1
    error("You forgot to provide threads via -t!")
end

# Load common code
include("common.jl")

# Get list of .CSV's we need to mash up
csv_dir = @get_scratch!("generated_csvs_small")
plot_dir = @get_scratch!("plot_outputs")
csv_files = sort(filter(f -> endswith(f, ".csv"), readdir(csv_dir; join=true)))

# Do one processing round to precompile before we start timing
process_data(load_csv(first(csv_files)))

t_processing = @elapsed begin
    # Use `Threads.@threads` to run embarassingly parallel workloads
    # This only has an effect when `Base.Threads.nthreads() > 1`, which
    # happens when the Julia interpreter has been invoked with `-t N`
    # or `JULIA_NUM_THREADS` has been set to `N`.
    results = []
    Threads.@threads for f in csv_files
        @info("Processing $(basename(f))")
        # Load CSV into memory
        df = load_csv(f)

        # Process data
        m, m̂, best_pair = process_data(df)

        # Our plotting backend doesn't support running on other threads. :(
        # So we save the results, then plot them on a single thread at the end.
        push!(results, (f, df, m, m̂, best_pair))
    end

    for r in results
        plot_data(r...)
    end
end
@info("Finished processing $(length(csv_files)) in $(t_processing) seconds ($(t_processing/length(csv_files)) per file)")
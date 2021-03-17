# Load common code
include("common.jl")

# Get list of .CSV's we need to mash up
csv_dir = @get_scratch!("generated_csvs_small")
plot_dir = @get_scratch!("plot_outputs")
csv_files = sort(filter(f -> endswith(f, ".csv"), readdir(csv_dir; join=true)))

# Do one processing round to precompile before we start timing
process_data(load_csv(first(csv_files)))

t_processing = @elapsed begin
    for f in csv_files
        @info("Processing $(basename(f))")
        # Load CSV into memory
        df = load_csv(f)

        # Process data
        m, m̂, best_pair = process_data(df)

        # Compare output with a `plot()`; save that to a file
        plot_data(f, df, m, m̂, best_pair)
    end
end
@info("Finished processing $(length(csv_files)) in $(t_processing) seconds ($(t_processing/length(csv_files)) per file)")
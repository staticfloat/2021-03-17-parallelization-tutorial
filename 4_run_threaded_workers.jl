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

# start timing now
t_start = time()

# Create task to read in CSVs, push them onto a Channel
data_in = Channel(Threads.nthreads())
@info("Starting data loader task...")
task_csv_loader = Threads.@spawn begin
    # Load the CSVs as fast as possible
    Threads.@threads for f in csv_files
        df = load_csv(f)
        put!(data_in, (f, df))
    end
    @info("Done loading all $(length(csv_files)) files")
    close(data_in)
end

# Next, create `nthreads` tasks to read in these CSVs, process them, then pass
# the results through another channel
results = Channel(100)
task_data_processors = []
@info("Starting processor tasks...")
for thread_idx in 1:Threads.nthreads()
    task = Threads.@spawn begin
        while isopen(data_in)
            # Take a dataframe from our Channel
            f, df = @take_or_break(data_in)

            # Process the data
            m, m̂, best_pair = process_data(df)

            # Push the result onto another Channel
            put!(results, (f, df, m, m̂, best_pair))
        end
    end

    # Build up a list of all the data processor tasks
    push!(task_data_processors, task)
end

# Because we have N threads  reading from `data_in` and writing to `results`,
# we only close `results` once _all_ of the data processor tasks are done
task_result_closer = @async begin
    wait.(task_data_processors)
    @info("Done processing all $(length(csv_files)) files, closing `results`")
    close(results)
end

# Finally, on the main thread, collect all results and plot them out
@info("Awaiting results...")
while isopen(results)
    f, df, m, m̂, best_pair = @take_or_break(results)
    plot_data(f, df, m, m̂, best_pair)
end

# `wait` on all these tasks, to ensure that they have finished cleanly
# All tasks should eventually have a `wait()` or `fetch()` somewhere,
# to ensure that there are no dropped 
wait(task_csv_loader)
wait(task_result_closer)

t_processing = time() - t_start
@info("Finished processing $(length(csv_files)) in $(t_processing) seconds ($(t_processing/length(csv_files)) per file)")
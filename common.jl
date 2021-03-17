@info("Loading packages...")
using CSV, Plots, Scratch, Statistics, MultivariateStats, DataFrames

# Load a CSV.  We purposefully disable multithreading here, so that
# we can more easily see the difference between our different threading
# regimes.
function load_csv(path)
    return CSV.read(path, DataFrame; threaded=false)
end

# Sample correlation measure.  Doesn't do any shifting
function corr(x::Vector, y::Vector)
    x_demean = x .- mean(x)
    y_demean = y .- mean(y)

    r_xx = sum(x_demean.^2)
    r_yy = sum(y_demean.^2)
    return sum(x_demean .* y_demean)/sqrt(r_xx*r_yy)
end

function process_data(df)
    # Extract modulator
    m = df.modulator

    # Extract traces (everything except the "modulator")
    traces = df[:, Not(:modulator)]

    # Perform PCA on the traces.  This takes a while, but is
    # naturally parallelized.
    #P = fit(PCA, Matrix(traces))
    #m̂ = P.mean .+ P.proj[:, 1]
    m̂ = m*.2

    # Next, find the two traces that correlate the best,
    # within a certain window.  This is a totally arbitrary,
    # non-parallelized operation.
    best_pair = (-1, -1, 0)
    for i in 1:size(traces, 2)
        # We only compare against the next `search_len` traces;
        # We can adjust this window to increase the amount of
        # serial work that we do while processing this data.
        search_len = 100
        for j in (i+1):min(i+search_len,size(traces,2))
            r_xy = corr(traces[:, i], traces[:, j])
            if r_xy > best_pair[3]
                best_pair = (i, j, r_xy)
            end
        end
    end

    # Return the modulator, the mean + projection and the
    # best-correlated pair of traces.
    return m, m̂, best_pair
end

function plot_data(f, df, m, m̂, best_pair)
    # First, plot the PCA vector and the envelope
    p1 = plot(
        [0.2.*m, m̂];
        layout=(1, 2, 1),
        label=["m" "m̂"],
    )

    # Next, plot the two correlated pairs
    pair1 = df[:, best_pair[1]]
    pair2 = df[:, best_pair[2]]
    p2 = plot(
        [pair1, pair2];
        layout=(1, 2, 2),
        legend=nothing,
        title="Best pair: $(best_pair[1]) and $(best_pair[2])",
    )

    # Compose the two into a stacked plot
    p = plot(p1, p2; layout=(2, 1))

    # Save the plot out to file
    out_f = joinpath(plot_dir, string(basename(f)[1:end-4], ".pdf"))
    savefig(p, out_f)

    return p
end

include("threading_common.jl")
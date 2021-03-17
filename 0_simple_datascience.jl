using Plots, CSV, MultivariateStats

## Setup parameters
begin
	# Number of observations
	N = 1000

	# First/second feature variances
	σ₁ = 0.5
	σ₂ = 0.1
	θ = π/3
end

## Create `data` that is N observations of 2 different 
begin
	Xform = [σ₁  0;
			 0  σ₂] *
			[cos(θ) -sin(θ);
			sin(θ) cos(θ)]
	data = (randn(N, 2) * Xform)'
	p = scatter(
		data[1, :],
		data[2, :];
		xlim=(-1.5, 1.5),
		ylim=(-1.5, 1.5),
		title="Scatterplot of feature 1 vs. feature 2",
		xlabel="feature 1",
		ylabel="feature 2",
		legend=nothing,
	)
	display(p)
end

## Use PCA to discover vectors of maximal variance
M = fit(PCA, data)

## Plot data with PCA vectors overlaid
begin
	p = scatter(
		data[1, :],
		data[2, :];
		xlim=(-1.5, 1.5),
		ylim=(-1.5, 1.5),
		title="Principal components",
		xlabel="feature 1",
		ylabel="feature 2",
		legend=nothing,
	)
	plot!(p, [M.mean[1], M.mean[1] .+ M.proj[1,1]], [M.mean[2], M.mean[2] .+ M.proj[2,1]]; linewidth=10)
	plot!(p, [M.mean[1], M.mean[1] .+ M.proj[1,2]], [M.mean[2], M.mean[2] .+ M.proj[2,2]]; linewidth=10)
	display(p)
end
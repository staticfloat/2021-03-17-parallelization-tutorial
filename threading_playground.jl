include("threading_common.jl")

# Create channel that can hold 10 items
data_in = Channel(10)
Threads.@spawn begin
    # Send 20 pieces of data through
    for idx in 1:20
        put!(data_in, idx)
        @info("Sent [$(idx)]")
    end

    # Once we're done, close the channel to signify we're done
    # and nothing more is coming down this pipe!
    close(data_in)
end

## Processing 1
p1_to_p2 = Channel()
p1_to_p3 = Channel()
Threads.@spawn begin
    while isopen(data_in)
        data = @take_or_break(data_in)

        # Do some "processing"
        data = data^2

        put!(p1_to_p2, data)
        put!(p1_to_p3, data)
    end
    close(p1_to_p2)
    close(p1_to_p3)
end

# Processing 2
p2_to_p3 = Channel()
Threads.@spawn begin
    while isopen(p1_to_p2)
        data = @take_or_break(p1_to_p2)

        # Do some "processing"
        data = data/2

        put!(p2_to_p3, data)
    end
    close(p2_to_p3)
end

# Processing 3
Threads.@spawn begin
    while isopen(p1_to_p3) && isopen(p2_to_p3)
        data1 = @take_or_break(p1_to_p3)
        data2 = @take_or_break(p2_to_p3)

        @info("Received", data1, data2)
    end
end
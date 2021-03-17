
# Helper macro to allow us to take!() from channels and `continue`
# if we have encountered an InvalidStateException due to the channel
# being closed.
macro take_or_break(ex)
    quote
        try
            take!($(esc(ex)))
        catch e
            if isa(e, InvalidStateException) && e.state == :closed
                break
            end
            rethrow(e)
        end
    end
end
local Sequence = {
    sequence = {}, -- sequence of action
    t = 0, -- time since the start of the sequence,
    t_action = 0, -- time since the start of the current action
    call_action = 0,
    index = 1 -- index of the current action
}

local Sequencer = {
    sequences = {},
    current = 1 -- current sequence creating
}

local sequencer = new(Sequencer)

sequencer.create = function(sequence)
    local s = new(Sequence)
    s.sequence = { sequence }
    table.insert(sequencer.sequences, s)
    sequencer.current = #sequencer.sequences
    return sequencer
end

sequencer.next = function(action)
    table.insert(sequencer.sequences[sequencer.current].sequence, action)
    sequencer.current = #sequencer.sequences
    return sequencer
end

sequencer._update = function()
    for k, sequence in rpairs(sequencer.sequences) do
        local current_action = sequence.sequence[sequence.index]
        if current_action ~= nil then
            local result = current_action(sequence.t, sequence.t_action, sequence.call_action)
            sequence.t = sequence.t + tiny.dt
            sequence.t_action = sequence.t_action + tiny.dt
            sequence.call_action = sequence.call_action + 1
            if result == true then
                sequence.index = sequence.index + 1
                sequence.t_action = 0
                sequence.call_action = 0
            end
            if(sequence.index > #sequence.sequence) then
               table.remove(sequencer.sequences, k)
            end
        end
    end
end

return sequencer

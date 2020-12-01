using StatsBase
using Plotly

function simulate_walk(start_state, t, q_1, q_2, boundary)
    old_state = start_state

    type = 1

    for i in 1:t
        new_state = old_state

        if abs(old_state[1]) != boundary && abs(old_state[2]) != boundary
            # [stay, left, right, up/down]

            probabilities = [1-(2*q_1 + q_2)/3, q_1/3, q_1/3, q_2/3]
            n = sample([1,2,3,4], Weights(probabilities))

            if n == 2
                new_state = [old_state[1]-1, old_state[2]]
            elseif n == 3
                new_state = [old_state[1]+1, old_state[2]]
                type = type*(-1)
            elseif n == 4
                new_state = [old_state[1], old_state[2]+type]
                type = type*(-1)
            end

        else
            if old_state[1] == -boundary
                probabilities = [1-(q_1), q_1/2, q_1/2]
                n = sample([1,2,3], Weights(probabilities))
                if n == 2
                    new_state = [old_state[1] + 1, old_state[2]]
                    type = type*(-1)
                elseif n == 3
                    new_state = [boundary - 1, old_state[2]]
                    type = type*(-1)
                end
            elseif old_state[1] == boundary
                probabilities = [1-(q_1), q_1/2, q_1/2]
                n = sample([1,2,3], Weights(probabilities))
                if n == 2
                    new_state = [old_state[1] - 1, old_state[2]]
                    type = type*(-1)
                elseif n == 3
                    new_state = [-boundary + 1, old_state[2]]
                    type = type*(-1)
                end
            elseif old_state[2] == -boundary
                probabilities = [1-(q_2), q_2/2, q_2/2]
                n = sample([1,2,3], Weights(probabilities))
                if n == 2
                    new_state = [old_state[1], old_state[2] + 1]
                    type = type*(-1)
                elseif n == 3
                    new_state = [old_state[1], boundary - 1]
                    type = type*(-1)
                end
            elseif old_state[2] == boundary
                probabilities = [1-(q_2), q_2/2, q_2/2]
                n = sample([1,2,3], Weights(probabilities))
                if n == 2
                    new_state = [old_state[1], old_state[2]-1]
                    type = type*(-1)
                elseif n == 3
                    new_state = [old_state[1], -boundary + 1]
                    type = type*(-1)
                end
            end
        end
        old_state = new_state
    end
    return old_state
end

function simulate(start_state, t, q_1, q_2, boundary, N)
    states = [start_state]
    for i in 1:N
        s = simulate_walk(start_state, t, q_1, q_2, boundary)
        states = append!(states, [s])
    end
    return states
end

function get_probabilities(states, boundary, N)
    state_probs = []
    for i in -boundary:boundary
        for j in -boundary:boundary
            count = 0

            for k in states
                if k[1] == i && k[2] == j
                    count = count + 1
                end
            end

            state_probs = append!(state_probs, [[i, j, count/N]])
        end
    end
    return state_probs
end

function plot_probabilities(states)
    x = []
    y = []
    z = []

    for i in states
        x = append!(x, [i[1]])
        y = append!(y, [i[2]])
        z = append!(z, [i[3]])
    end

    response = plot(heatmap(x=x, y=y, z=z, aspect_ratio = 1))
    return response
end

states = simulate([0,0], 10, 1, 1, 5, 1000000)
prob = get_probabilities(states, 5, 1000000)
plot_probabilities(prob)

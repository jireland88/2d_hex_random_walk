using StatsBase
using Plots

function simulate_walk(start_state, t, q_1, q_2, boundary)
    old_state = start_state

    for i in 1:t
        new_state = old_state

        if abs(old_state[1]) != boundary && abs(old_state[2]) != boundary
            # [stay, left, right, up, down]
            probabilities = [1-(q_1 + q_2)/2, q_1/4, q_1/4, q_2/4, q_2/4]
            n = sample([1,2,3,4,5], Weights(probabilities))

            if n == 2
                new_state = [old_state[1]-1, old_state[2]]
            elseif n == 3
                new_state = [old_state[1]+1, old_state[2]]
            elseif n == 4
                new_state = [old_state[1], old_state[2]+1]
            elseif n == 5
                new_state = [old_state[1], old_state[2]-1]
            end

        else
            if old_state[1] == -boundary
                probabilities = [1-(q_1), q_1] # not sure if division by 4 is right
                n = sample([1,2], Weights(probabilities))
                if (n == 2) new_state = [old_state[1] + 1, old_state[2]] end
            elseif old_state[1] == boundary
                probabilities = [1-(q_1), q_1] # not sure if division by 4 is right
                n = sample([1,2], Weights(probabilities))
                if (n == 2) new_state = [old_state[1] - 1, old_state[2]] end
            elseif old_state[2] == -boundary
                probabilities = [1-(q_2), q_2] # not sure if division by 4 is right
                n = sample([1,2], Weights(probabilities))
                if (n == 2) new_state = [old_state[1], old_state[2] + 1] end
            elseif old_state[2] == boundary
                probabilities = [1-(q_2), q_2] # not sure if division by 4 is right
                n = sample([1,2], Weights(probabilities))
                if (n == 2) new_state = [old_state[1], old_state[2]-1] end
            end
        end
        old_state = new_state
    end
    return old_state
end

function simulate(start_state, t, q_1, q_2, N, trials)
    boundary = (N / 2) - 1

    states = [start_state]
    for i in 1:trials
        s = simulate_walk(start_state, t, q_1, q_2, boundary)
        states = append!(states, [s])
    end
    return states
end

function get_probabilities(states, N, trials)
    boundary = (N / 2) - 1

    state_probs = []
    for i in -boundary:boundary
        for j in -boundary:boundary
            count = 0

            for k in states
                if k[1] == i && k[2] == j
                    count = count + 1
                end
            end

            state_probs = append!(state_probs, [[i + boundary + 1, j + boundary + 1, count/trials]])
        end
    end
    return state_probs
end

function master_equation(n1, n2, t, N1, N2, n01, n02, q1, q2)
    tot = 0

    for k1 in 0:(N1-1)
        for k2 in 0:(N2-1)
            ak1 = 2
            ak2 = 2
            if (k1 == 0) ak1 = 1 end
            if (k2 == 0) ak2 = 1 end

            part1 = cos((n1 - (1/2))*pi*k1/N1)
            part2 = cos((n01 - (1/2))*pi*k1/N1)*cos((n2 - (1/2))*pi*k2/N2)*cos((n02 - (1/2))*pi*k2/N2)
            part3 = 1 - ((q1 + q2)/2) + (q1/2)*cos(pi*k1/N1) + (q2/2)cos(pi*k2/N2)

            s = ak1*ak2*part1*part2*(part3^t)
            tot = tot + s
        end
    end
    return tot / (N1*N2)
end

function master_equation_all(t, N, n01, n02)
    states = []
    for i in 1:N
        for j in 1:N
            states = append!(states, [[i, j, master_equation(i, j, t, N, N, n01, n02, 1, 1)]])
        end
    end
    return states
end

function plot_heatmap(states)
    N = Int(sqrt(length(states)))

    M = zeros(N, N)

    for i in states
        M[Int(i[2]), Int(i[1])] = i[3]
    end

    plotly()
    p = heatmap(M)
    gui(p)
end

function squared_error(state_prob_1, state_prob_2)
    sum = 0
    for i in 1:size(state_prob_1, 1)
        a = state_prob_1[i][3]
        b = state_prob_2[i][3]

        error = (b - a)^2
        sum = sum + error
    end
    return sqrt(sum/size(state_prob_1, 1))
end

states = simulate([0,0], 10, 1, 1, 12, 1000000)
state_prob = get_probabilities(states, 12, 1000000)
plot_heatmap(state_prob)

states = master_equation_all(10, 12, 6, 6)
plot_heatmap(states)

println(squared_error(state_prob, states))

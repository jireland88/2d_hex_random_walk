using StatsBase
using Plots

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

            state_probs = append!(state_probs, [[i+boundary + 1, j+boundary + 1, count/trials]])
        end
    end
    return state_probs
end

function master_equation(n1, n2, t, N, n01, n02)
    tot = 0
    for m1 in 0:(N-1)
        for m2 in 0:(N-1)
            trig_bit = cos(2*pi*(n1-n01)*m1/N)*cos(2*pi*(n2-n02)*m2/N) - sin(2*pi*(n1-n01)*m1/N)*sin(2*pi*(n2-n02)*m2/N)
            C = sqrt((1 + 4*(cos(2*pi*m1 / N))^2 + 4*cos(2*pi*m1 / N)*cos(2*pi*m2 / N))/9)^t

            tot = tot + (trig_bit * C)
        end
    end

    ans = tot / (N^2)

    return ans
end

function master_all(me, t, N, n01, n02)
    results = []
    for i in 1:N
        for j in 1:N
            p = me(i, j, t, N, n01, n02)

            results = append!(results, [[i,j,p]])
        end
    end
    return results
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

function mean_absolute_error(state_prob_1, state_prob_2)
    sum = 0
    for i in 1:size(state_prob_1, 1)
        a = state_prob_1[i][3]
        b = state_prob_2[i][3]

        error = abs(b - a)
        sum = sum + error
    end
    return sum/size(state_prob_1, 1)
end

function error_plot(sim, eqn)
    N = size(sim, 1)

    errors = []

    for i in 1:N
        error = eqn[i][3] - sim[i][3]

        errors = append!(errors, [error])
    end

    plotly()
    p = histogram(errors, bins=20)
    gui(p)
end

states = simulate([0,0], 10, 1, 1, 22, 1000000)
prob_sim = get_probabilities(states, 22, 1000000)
plot_heatmap(prob_sim)

prob_eqn = master_all(master_equation, 10, 22, 11, 11)
plot_heatmap(prob_eqn)

error_plot(prob_sim, prob_eqn)

println(squared_error(prob_sim, prob_eqn))
println(mean_absolute_error(prob_sim, prob_eqn))

using StatsBase
using DelimitedFiles

function simulate_walk(start_state, t, q_1, q_2, q_3, boundary)
    old_state = start_state
    very_old_state = start_state

    for i in 1:t
        new_state = old_state

        if abs(old_state[1]) != boundary && abs(old_state[2]) != boundary && abs(old_state[3]) != boundary
            probabilities = [1-(q_1 + q_2 + q_3)/3, q_1/6, q_1/6, q_2/6, q_2/6, q_3/6, q_3/6]
            n = sample([1,2,3,4,5,6,7], Weights(probabilities))

            if n == 2
                new_state = [old_state[1]+1, old_state[2], old_state[3]-1]
            elseif n == 3
                new_state = [old_state[1]-1, old_state[2], old_state[3]+1]
            elseif n == 4
                new_state = [old_state[1], old_state[2]+1, old_state[3]-1]
            elseif n == 5
                new_state = [old_state[1], old_state[2]-1, old_state[3]+1]
            elseif n == 6
                new_state = [old_state[1]+1, old_state[2]-1, old_state[3]]
            elseif n == 7
                new_state = [old_state[1]-1, old_state[2]+1, old_state[3]]
            end

        else
            x_diff = abs(old_state[1] - very_old_state[1])
            y_diff = abs(old_state[2] - very_old_state[2])
            z_diff = abs(old_state[3] - very_old_state[3])

            if x_diff == 1 && z_diff == 1
                probabilities = [1-(q_1), q_1]
                n = sample([1,2], Weights(probabilities))
                if (n == 2) new_state = very_old_state end
            elseif y_diff == 1 && z_diff == 1
                probabilities = [1-(q_2), q_2]
                n = sample([1,2], Weights(probabilities))
                if (n == 2) new_state = very_old_state end
            elseif x_diff == 1 && y_diff == 1
                probabilities = [1-(q_3), q_3]
                n = sample([1,2], Weights(probabilities))
                if (n == 2) new_state = very_old_state end
            end
        end
        very_old_state = old_state
        old_state = new_state
    end
    return old_state
end

function simulate(start_state, t, q_1, q_2, q_3, boundary, N)
    states = [start_state]
    for i in 1:N
        s = simulate_walk(start_state, t, q_1, q_2, q_3, boundary)
        states = append!(states, [s])
    end
    return states
end

function get_probabilities(states, boundary, N)
    state_probs = []
    for i in -boundary:boundary
        for j in -boundary:boundary
            for k in -boundary:boundary
                if i + j + k == 0
                    count = 0

                    for l in states
                        if l[1] == i && l[2] == j && l[3] == k
                            count = count + 1
                        end
                    end

                    state_probs = append!(state_probs, [[i, j, k, count/N]])
                end
            end
        end
    end
    return state_probs
end

states = simulate([0,0,0], 5, 1, 1, 1, 5, 10000)
state_prob = get_probabilities(states, 5, 10000)

function state_times(t1, t2, q_1, q_2, q_3, b, N)
    mult_states = []

    for t in t1:t2
        println(t)
        states = simulate([0,0,0], t, q_1, q_2, q_3, b, N)
        state_prob = get_probabilities(states, b, N)
        for i in state_prob
            mult_states = append!(mult_states, [[t, i[1], i[2], i[3], i[4]]])
        end
    end
    return mult_states
end

st = state_times(1, 50, 1, 1, 1, 6, 1000000)

writedlm("hex_prob_t.csv", st, ',')

function master_equation_hex1(n1, n2, t, N)
    tot = 0
    for m1 in 0:(N-1)
        for m2 in 0:(N-1)
            a = cos((2*pi / N)*n1*m1)*cos((2*pi / N)*n2*m2)
            b = sqrt(1 + 8*cos(2*pi*m1 / N)*cos((pi/N)*(m1-m2))*cos((pi/N)*(m1+m2)))

            s = a * ((0.5*((3/b)^t)) - ((-3/b)^t))
            tot = tot + s
        end
    end
    return (1/N^2)*tot
end

function master_equation_hex2(n1, n2, t, N)
    tot = 0
    for m1 in 1:(N-1)
        for m2 in 1:(N-1)
            a = cos((2*pi / N)*n1*m1)*cos((2*pi / N)*n2*m2)
            b = sqrt(1 + 8*cos(2*pi*m1 / N)*cos((pi/N)*(m1-m2))*cos((pi/N)*(m1+m2)))

            s = a * (-0.5((-3/b)^t)+((3/b)^t))
            tot = tot + s
        end
    end
    return (1/N^2)*tot
end

function master_all(N, t)
    results = []
    for i in 1:(N-1)
        for j in 1:(N-1)
            p = master_equation_hex2(i, j, t, N)

            if p >= 0 && p <= 1
                results = append!(results, [[i,j,p]])
            end
        end
    end
    return results
end

println(master_all(10, 5))

#states = master_equation_hex2(6, 6, 10, 11)

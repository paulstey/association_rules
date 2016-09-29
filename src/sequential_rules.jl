
type PrefixNode
    patrn::Array{Array{String,1},1}
    supp::Int64
    seq_extension_children::Array{PrefixNode, 1}
    item_extension_children::Array{PrefixNode, 1}
end


type PNode
    patrn::Array{Array{String,1},1}
    supp::Int64
end


type SequenceRule
    rule::String
    conf::Float64
end



# NOTE: The gen_rules1() function is quite inefficient. In
# particular, it's runtime is O(n*m*2^k) where k is the number
# of elements in the pattern, m is the number of patterns for a
# given pattern length k, and n is the number of different pattern
# lengths. Additionally, though this corresponds to the pseudocode
# Zaki provides in his orginal paper, it is not the implementation
# that appears in the arulesSequence package.

function gen_rules1(F::Array{Array{IDList, 1}, 1}, min_conf)
    supp_cnt = count_patterns(F)
    rules = String[]

    # Check the confidence for all sub-patterns
    # from all of our frequent patterns
    for k = 1:length(F)
        for i = 1:length(F[k])
            sub_patrns = gen_combin_subpatterns(F[k][i].patrn)
            for s in sub_patrns
                if s ≠ ""
                    cnt = get(supp_cnt, s, 0)
                    conf = isfinite(cnt) ? F[k][i].supp_cnt/cnt : -Inf

                    if conf ≥ min_conf
                        push!(rules, "$s => $(pattern_string(F[k][i].patrn))")
                    end
                end
            end
        end
    end
    rules
end

# rules = gen_rules1(res, 0)



function create_children(node::PNode, uniq_items::Array{String,1}, supp_cnt)
    seq_ext_children = Array{PNode,1}(0)
    item_ext_children = Array{PNode,1}(0)

    for item in uniq_items
        seq_patrn = sequence_extension(node.patrn, item)
        itm_patrn = item_extension(node.patrn, item)
        # println(itm_patrn)

        seq_string = pattern_string(seq_patrn)
        seq_supp = 1 #get(supp_cnt, seq_string, 0)
        itm_string = pattern_string(itm_patrn)
        itm_supp = 1 #get(supp_cnt, itm_string, 0)

        seq_extd_child = PNode(seq_patrn, seq_supp)
        item_extd_child = PNode(itm_patrn, itm_supp)

        push!(seq_ext_children, seq_extd_child)
        push!(item_ext_children, item_extd_child)
    end
    return (seq_ext_children, item_ext_children)
end

# pn = PNode([["A", "B"], ["C"]], 1)
# create_children(pn, ["A", "B", "C", "D"], Dict{String, Int}())

function gen_rules_from_root!(root::PNode, uniq_items, rules::Array{SequenceRule,1}, supp_cnt, min_conf)
    seq_ext_children, item_ext_children = create_children(root, uniq_items, supp_cnt)
    pre = root.patrn
    pre_supp = root.supp
    pre_str = pattern_string(pre)

    for nseq in seq_ext_children
        println(nseq)
        seq_children, itm_children = create_children(nseq, uniq_items, supp_cnt)
        child_nodes = [seq_children; itm_children]

        println(child_nodes)

        for l in child_nodes

            conf = isfinite(pre_supp) ? l.supp/pre_supp : -Inf
            println(conf)
            post_str = pattern_string(l.patrn)
            if conf ≥ min_conf
                postfix = extract_postfix(pre_str, post_str)
                new_rule = string(pre_str, " => ", postfix)
                push!(rules, SequenceRule(new_rule, conf))
                println(rules)
            end
        end
    end

    for nseq in seq_ext_children
        gen_rules_from_root!(nseq, uniq_items, rules, supp_cnt, min_conf)
    end

    for nseq in item_ext_children
        gen_rules_from_root!(nseq, uniq_items, rules, supp_cnt, min_conf)
    end
end

# pn = PNode([String[]], 1)
#
# srules = SequenceRule[]
# gen_rules_from_root!(pn, ["A", "B", "C", "D"], srules, Dict{String, Int}(), 0.01)










# function build_ptree(F::Array{Array{IDList,1},1}, min_conf, num_uniq_sids)
#     supp_cnt = count_patterns(F)
#     uniq_items = String[]
#
#     for k = 1:length(F)
#         for i = 1:length(F[k])
#             if F[k][i] ∉ uniq_items
#                 push!(uniq_items, F[k][i])
#             end
#         end
#     end
#     node = PrefixNode("{}", num_uniq_sids, uniq_items, uniq_items)
#     rules = String[]
#
#     gen_rules_from_root!(node, F, rules, supp_cnt, min_conf)

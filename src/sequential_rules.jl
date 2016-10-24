# NOTE: This code is meant to be used to generate sequential rules
# from the frequent sequences generated by the SPADE algorithm.


type PrefixNode
    patrn::Array{Array{String,1},1}
    supp::Int64
    parent::PrefixNode

    seq_extension_children::Array{PrefixNode, 1}
    item_extension_children::Array{PrefixNode, 1}

    PrefixNode(patrn, supp, parent) = new(patrn, supp, parent)      # incomplete initialization
end


type PNode
    patrn::Array{Array{String,1},1}
    supp::Int64
end


type SequenceRule
    rule::String
    conf::Float64
end


==(x::SequenceRule, y::SequenceRule) = x.rule == y.rule && x.conf == y.conf

function unique(v::Array{SequenceRule, 1})
    out = Array{SequenceRule, 1}(0)
    for i = 1:length(v)
        if !in(v[i], out)
            push!(out, v[i])
        end
    end
    return out
end


type SeqRule
    prefix::Array{Array{String,1},1}
    postfix::Array{Array{String,1},1}
    conf::Float64
end


==(x::SeqRule, y::SeqRule) = x.prefix == y.prefix && x.postfix == y.postfix && x.conf == y.conf

function unique(v::Array{SeqRule, 1})
    out = Array{SeqRule, 1}(0)
    for i = 1:length(v)
        if !in(v[i], out)
            push!(out, v[i])
        end
    end
    return out
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
        itm_string = pattern_string(itm_patrn)
        seq_supp = get(supp_cnt, seq_string, 0)
        itm_supp = get(supp_cnt, itm_string, 0)

        seq_extd_child = PNode(seq_patrn, seq_supp)
        item_extd_child = PNode(itm_patrn, itm_supp)

        push!(seq_ext_children, seq_extd_child)
        push!(item_ext_children, item_extd_child)
    end
    return (seq_ext_children, item_ext_children)
end

# pn = PNode([["A", "B"], ["C"]], 1)
# create_children(pn, ["A", "B", "C", "D"], Dict{String, Int}())




# NOTE: The function below is adapted from pseudocode
# in IMSR_PreTree paper by Van, Bo, and Le (2014)

function gen_rules_from_root!(root::PNode, uniq_items, rules::Array{SequenceRule,1}, supp_cnt, min_conf)
    pre = root.patrn

    seq_ext_children, item_ext_children = create_children(root, uniq_items, supp_cnt)
    pre_supp = root.supp
    pre_str = pattern_string(pre)



    for nseq in seq_ext_children

        println(pre_str, " :::: ", pattern_string(nseq.patrn))

        if nseq.supp == 0
            continue
        end
        conf = isfinite(pre_supp) ? nseq.supp/pre_supp : -Inf
        post_str = pattern_string(nseq.patrn)
        if conf ≥ min_conf
            postfix = extract_postfix(pre_str, post_str)
            new_rule = string(pre_str, " => ", postfix)

            println("New rule from outer loop: ", new_rule)

            push!(rules, SequenceRule(new_rule, conf))
        end


        seq_children, itm_children = create_children(nseq, uniq_items, supp_cnt)
        child_nodes = [seq_children; itm_children]

        for l in child_nodes
            if l.supp == 0
                continue
            end
            conf = isfinite(pre_supp) ? l.supp/pre_supp : -Inf
            post_str = pattern_string(l.patrn)

            println(pre_str, " ==== ", post_str)
            if conf ≥ min_conf
                postfix = extract_postfix(pre_str, post_str)
                new_rule = string(pre_str, " => ", postfix)

                println("New rule from inner: ", new_rule)

                push!(rules, SequenceRule(new_rule, conf))
            end


            # gen_rules_from_root!(l, uniq_items, rules, supp_cnt, min_conf)
        end
    end

    for nseq in seq_ext_children
        if nseq.supp == 0
            continue
        end
        gen_rules_from_root!(nseq, uniq_items, rules, supp_cnt, min_conf)
    end

    for nseq in item_ext_children
        if nseq.supp == 0
            continue
        end
        gen_rules_from_root!(nseq, uniq_items, rules, supp_cnt, min_conf)
    end
end

# pn = PNode([String[]], 1)
#
# srules = SequenceRule[]
# gen_rules_from_root!(pn, ["A", "B", "C", "D"], srules, Dict{String, Int}(), 0.1)


function generate_sr_from_tree_root!(sp_root, uniq_items, rules, supp_cnt, min_conf)
    seq_ext_children, item_ext_children = create_children(sp_root, uniq_items, supp_cnt)

    for pseq in seq_ext_children

        println(pseq)

        seq_children, itm_children = create_children(pseq, uniq_items, supp_cnt)
        subtree = [pseq; seq_children; itm_children]
        for x in subtree
            println(x)
        end
        generate_sr_from_subtree!(sp_root, subtree, rules, min_conf)
    end
    for pitems in item_ext_children
        if pitems.supp == 0
            continue
        end
        generate_sr_from_tree_root!(pitems, uniq_items, rules, supp_cnt, min_conf)
    end
end


function generate_sr_from_subtree!(pre, subtree, rules, min_conf)
    n_pre = pre.supp
    pre_str = pattern_string(pre.patrn)

    for cn in subtree
        # if cn.supp == 0
        #     continue
        # end

        conf = isfinite(pre.supp) ? cn.supp/pre.supp : -Inf
        sp = pattern_string(cn.patrn)

        if conf ≥ min_conf
            post = extract_postfix(pre_str, sp)
            new_rule = string(pre_str, " => ", post)

            println("New rule: ", new_rule)

            push!(rules, SequenceRule(new_rule, conf))
        end
    end
end



function build_ptree(F::Array{Array{IDList,1},1}, min_conf)
    supp_cnt = count_patterns(F)
    uniq_items = String[]

    for k = 1:length(F)
        for i = 1:length(F[k])
            for j = 1:length(F[k][i].patrn)
                for l = 1:length(F[k][i].patrn[j])
                    if F[k][i].patrn[j][l] ∉ uniq_items
                        push!(uniq_items, F[k][i].patrn[j][l])
                    end
                end
            end
        end
    end
    rules = SequenceRule[]

    for itm in uniq_items
        # treat each single item as its own "root"
        single_item_root = PNode([[itm]], supp_cnt[pattern_string(itm)])

        warn("Single item root: $itm")

        # gen_rules_from_root!(single_item_root, uniq_items, rules, supp_cnt, min_conf)
        generate_sr_from_tree_root!(single_item_root, uniq_items, rules, supp_cnt, min_conf)
    end

    return rules
end

# @time build_ptree(res2, 0.01)
















function build_prefix_tree(F::Array{Array{IDList,1},1}, min_conf)
    supp_cnt = count_patterns(F)
    uniq_items = String[]

    for k = 1:length(F)
        for i = 1:length(F[k])
            for j = 1:length(F[k][i].patrn)
                for l = 1:length(F[k][i].patrn[j])
                    if F[k][i].patrn[j][l] ∉ uniq_items
                        push!(uniq_items, F[k][i].patrn[j][l])
                    end
                end
            end
        end
    end
    rules = SequenceRule[]

    for itm in uniq_items
        # treat each single item as its own "root"
        single_item_root = PrefixNode([[itm]], supp_cnt[pattern_string(itm)], [[""]])

        warn("Single item root: $itm")

        # gen_rules_from_root!(single_item_root, uniq_items, rules, supp_cnt, min_conf)
        generate_sr_from_tree_root2!(single_item_root, uniq_items, rules, supp_cnt, min_conf)
    end

    return rules
end



# Pseudo code for generating a prefix tree
# (1) Given a node (root or otherwise), generate its sequence-extended children and item-extended children.
# (2) For all sequence-extended children from (1)

function create_children2(node::Array{Array{String,1},1}, uniq_items::Array{String,1})
    seq_ext_children = Array{Array{Array{String,1},1},1}(0)
    item_ext_children = Array{Array{Array{String,1},1},1}(0)

    for item in uniq_items
        seq_patrn = sequence_extension(node, item)
        itm_patrn = item_extension(node, item)

        ## computing support
        # seq_string = pattern_string(seq_patrn)
        # itm_string = pattern_string(itm_patrn)
        # seq_supp = get(supp_cnt, seq_string, 0)
        # itm_supp = get(supp_cnt, itm_string, 0)

        # seq_extd_child = PNode(seq_patrn, seq_supp)
        # item_extd_child = PNode(itm_patrn, itm_supp)

        push!(seq_ext_children, seq_patrn)
        push!(item_ext_children, itm_patrn)
    end
    return (seq_ext_children, item_ext_children)
end


function growtree!(root, tree, uniq_items, depth = 0, maxdepth = 1)
    seq_ext_children, item_ext_children = create_children2(root, uniq_items)

    children = [seq_ext_children; item_ext_children]

    for child in children
        push!(tree, child)

        if depth+1 < maxdepth
            growtree!(child, tree, uniq_items, depth+1, maxdepth)
        end
    end
end


function build_tree(uniq_items, maxdepth)
    tree = []
    for itm in uniq_items
        push!(tree, [[itm]])
        growtree!([[itm]], tree, uniq_items, 1, maxdepth)
    end
    tree
end

build_tree(["A", "B", "C"], 2)







# iterating from the above toy example

type PreNode
    pattern::Array{Array{String,1},1}
    # parent::PreNode
    seq_ext_children::Array{PreNode,1}
    item_ext_children::Array{PreNode,1}
    support::Int64

    PreNode(pattern) = new(pattern)
end


function create_children3(node::PreNode, uniq_items::Array{String,1}, supp_cnt)
    seq_ext_children = Array{PreNode,1}(0)
    item_ext_children = Array{PreNode,1}(0)

    for item in uniq_items
        seq_patrn = sequence_extension(node.pattern, item)

        ## computing support
        seq_string = pattern_string(seq_patrn)
        seq_supp = get(supp_cnt, seq_string, 0)

        # only append children with non-zero support
        if seq_supp > 0
            seq_extd_child = PreNode(seq_patrn)
            seq_extd_child.support = seq_supp
            push!(seq_ext_children, seq_extd_child)
        end

        # seq_extd_child.parent = node
        # item_extd_child.parent = node


        itm_patrn = item_extension(node.pattern, item)
        itm_string = pattern_string(itm_patrn)
        itm_supp = get(supp_cnt, itm_string, 0)

        # We only create an item-extended child if this item
        # doesn't already appear in the last array of our our
        # parent (i.e., `node`). Otherwise, we would either be
        # duplicating an entry in the last array, or be making
        # an exact duplicate of our parent (assuming we only allow
        # unique entries in the pattern's arrays).
        if itm_supp > 0 && item ∉ node.pattern[end]

            item_extd_child = PreNode(itm_patrn)
            item_extd_child.support = itm_supp
            push!(item_ext_children, item_extd_child)
        end
    end
    return (seq_ext_children, item_ext_children)
end


function growtree!(root, uniq_items, supp_cnt, depth = 0, maxdepth = 1)
    root.seq_ext_children, root.item_ext_children = create_children3(root, uniq_items, supp_cnt)
    allchildren = [root.seq_ext_children; root.item_ext_children]

    for child in allchildren
        # push!(tree, child)

        if depth+1 < maxdepth
            growtree!(child, uniq_items, supp_cnt, depth+1, maxdepth)
        end
    end
end


function build_tree(F::Array{Array{IDList,1},1}, maxdepth)
    supp_cnt = count_patterns(F)
    uniq_items = String[]

    # NOTE: This loop is an embarassment. This is all to get the unique items
    # from the frequent sequences. The same unique item vector is created by
    # the spade() function. It should be passed to here.
    for k = 1:length(F)
        for i = 1:length(F[k])
            for j = 1:length(F[k][i].patrn)
                for l = 1:length(F[k][i].patrn[j])
                    if F[k][i].patrn[j][l] ∉ uniq_items
                        push!(uniq_items, F[k][i].patrn[j][l])
                    end
                end
            end
        end
    end

    rules = SequenceRule[]
    root = PreNode([[""]])
    root.seq_ext_children = PreNode[]

    for itm in uniq_items
        child_node1 = PreNode([[itm]])
        child_node1.support = supp_cnt[pattern_string(itm)]
        push!(root.seq_ext_children, child_node1)
        growtree!(child_node1, uniq_items, supp_cnt, 1, maxdepth)
    end
    return root
end

t = build_tree(res2, 6)







a = [["a"], ["b"]]
b = [["a"], ["b"], ["cd"], ["e"]]

function postfix(root, descendant)
    post = Array{Array{String,1},1}(0)
    n = length(root)
    m = length(descendant)
    i = 1

    while i ≤ n
        if root[i] == descendant[i]
            i += 1
        else
            error("Prefix of root doesn't matach descendant")
        end
    end
    for j = i:m
        push!(post, descendant[j])
    end
    post
end

postfix(a, b)




























function generate_sr_from_tree_root!(sp_root::PreNode, rules, min_conf)
    if isdefined(sp_root, :seq_ext_children)
        for seq_child in sp_root.seq_ext_children
            # println(seq_child)

            generate_sr_from_subtree!(sp_root, seq_child, rules, min_conf)
        end
    end

    if isdefined(sp_root, :item_ext_children)
        for itm_child in sp_root.item_ext_children
            generate_sr_from_tree_root!(itm_child, rules, min_conf)
        end
    end
end


function generate_sr_from_subtree!(pre, seq_child, rules, min_conf, one_elem_consq = true)
    conf = seq_child.support/pre.support

    if conf ≥ min_conf
        post = postfix(pre.pattern, seq_child.pattern)
        if one_elem_consq
            if length(post) == 1
                push!(rules, SeqRule(pre.pattern, post, conf))
            end
        elseif !one_elem_consq
            push!(rules, SeqRule(pre.pattern, post, conf))
        end



        if isdefined(seq_child, :seq_ext_children)
            if !isempty(seq_child.seq_ext_children)


                for grandchild in seq_child.seq_ext_children

                    # adding this very speculative (and based on a guess)
                    generate_sr_from_subtree!(seq_child, grandchild, rules, min_conf)


                    generate_sr_from_subtree!(pre, grandchild, rules, min_conf)
                end
            end
        end

        # display(seq_child)
        if isdefined(seq_child, :item_ext_children)
            if !isempty(seq_child.item_ext_children)
                for grandchild in seq_child.item_ext_children
                    generate_sr_from_subtree!(pre, grandchild, rules, min_conf)
                end
            end
        end
    end
end











t = build_tree(res, 10)

xrules = []
generate_sr_from_tree_root!(t.seq_ext_children[1], xrules, 0.01)


function sequential_rules(F, min_conf, maxdepth = 15)
    root = build_tree(F, maxdepth)

    rules = Array{SeqRule,1}(0)

    for i = 1:length(root.seq_ext_children)
        generate_sr_from_tree_root!(root.seq_ext_children[i], rules, min_conf)
    end
    rules
end

sr = sequential_rules(res, 0.01)


# In order to see why the above sequential_rules() function generates
# fewer rules than R, we will convert our output to match R's and then
# do a set difference on the string vectors to see what we aren't getting.

function as_set_string(vect::Vector)
    out = "{"
    n = length(vect)
    for (i, x) in enumerate(vect)
        out *= x
        if i ≠ n
            out *= ","
        end
        if i == n
            out *= "}"
        end
    end
    out
end



function as_r_string(r::SeqRule)
    out = "<"
    n = length(r.prefix)
    for (i, timepoint) in enumerate(r.prefix)
        out *= as_set_string(timepoint)
        if i ≠ n
            out *= ","
        end
        if i == n
            out *= ">"
        end
    end
    out *= " => <"

    m = length(r.postfix)
    for (i, timepoint) in enumerate(r.postfix)
        out *= as_set_string(timepoint)
        if i ≠ m
            out *= ","
        end
        if i == m
            out *= ">"
        end
    end
    out
end


function as_r_string(seq::Array{Array{String,1},1})
    out = "<"
    n = length(seq)
    for (i, timepoint) in enumerate(seq)
        out *= as_set_string(timepoint)
        if i ≠ n
            out *= ","
        end
        if i == n
            out *= ">"
        end
    end
    out
end


function rules_to_dataframe(rules::Array{SeqRule,1})
    df = DataFrame()
    n = length(rules)

    df[:rules] = Array{String,1}(n)
    for i = 1:n
        df[i, :rules] = as_r_string(rules[i])
    end
    df
end




function children(node::PreNode, child_type = "all")
    if child_type == "sequence"
        res = node.seq_ext_children
    elseif child_type == "item"
        res = node.item_ext_children
    elseif child_type == "all"
        res = [node.seq_ext_children; node.item_ext_children]
    end
    return res
end

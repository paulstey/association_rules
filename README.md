# AssociationRules
[![Build Status](https://travis-ci.org/bcbi/AssociationRules.jl.svg?branch=master)](https://travis-ci.org/bcbi/AssociationRules.jl)
[![codecov](https://codecov.io/gh/bcbi/AssociationRules.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/AssociationRules.jl)



## Description
This package implements algorithms for association rule mining and sequential pattern mining. In particular, we have currently implemented the _Apriori_ algorithm (Agrawal & Srikant, 1994) and the SPADE algorithm (Zaki, 2001). The former is used for association rule mining (e.g., "market basket" analysis), and the latter is used for identifying sequential patterns when the data possess a temporal ordering. The algorithms are written in pure Julia.


Note that a portion of our implementation of the _Apriori_ algorithm was adapted from the earlier work of [toddleo](https://github.com/toddleo/ARules.jl).


## Initial Setup
```{Julia}
Pkg.clone("https://github.com/paulstey/association_rules")
```

## Examples
Several examples below illustrate the use and features of the `apiori()` function and the `spade()` function.

### Ex. 1 (_Apriori_ algorithm):
Here we are generating association rules using `apriori()` function.
```{Julia}
using AssociationRules

# simulate transactions
groceries = ["milk", "bread", "eggs", "apples", "oranges", "beer"]
transactions = [sample(groceries, 4, replace = false) for x in 1:1000]

# minimum support of 0.1, minimum confidence of 0.4
rules = apriori(transactions, 0.1, 0.4)
```


Note that by default our `apriori()` function generates multi-item consequents. However, it can be made to mimic the `apriori()` function in R's _arules_ package and generate only single-item consequents.
```{Julia}
groceries = ["milk", "bread", "eggs", "apples", "oranges", "beer"]
transactions = [sample(groceries, 4, replace = false) for x in 1:1000]

# fourth argument prevents multi-item consequents
rules = apriori(transactions, 0.1, 0.4, false)
```


We can also use the `frequent()` function to generate the frequent item sets based on some minimum support threshold. Note that this function is called internally by the `apriori()` function when generating association rules.
```{Julia}
groceries = ["milk", "bread", "eggs", "apples", "oranges", "beer"]
transactions = [sample(groceries, 4, replace = false) for x in 1:1000]

# item sets with minimum support of 0.1
fk = frequent(transactions, 0.1)
```



### Ex. 2 (_Apriori_ algorithm with tabular data)
The more common scenario will be the one in which we start with tabular data from a two-dimensional array or a `DataFrame` object.
```{Julia}
adult = readcsv("adult.csv")

# convert tabular data
transactions = make_transactions(adult[1:1000, :])       # use only first 1000 rows

rules = apriori(transactions, 0.1, 0.4)
```



### Ex. 3 (SPADE algorithm with tabular data)
The more common scenario will be the one in which we start with tabular data from a two-dimensional array or a `DataFrame` object.
```{Julia}
zaki_data = readcsv("../data/zaki_data.csv", skipstart = 1)

# convert tabular data
seqs = make_sequences(zaki_data, 2, 3, 1)

# generate frequent sequential patterns with minimum
# support of 0.1 and maximum of 6 elements
res = spade(seqs, 0.2, 6)
```

## Current Algorithms
- _Apriori_ Algortihm (Agrawal & Srikant, 1994)
- SPADE Algorithm (Zaki, 2001)


## In progress
- Sequential rule induction algorithm based on prefix trees
- Update _Apriori_ to take advantage of multi-threaded parallelism


## To do
- FP-growth algorithm for association rules
- Add measures of interestingness for rules generated by the _Apriori_ algorithm

## _Caveats_
- The current rule-induction algorithm for sequential patterns runs in exponential time, and thus, is both slow and memory inefficient.
- This package is under active development. Please notify us of bugs or proposed improvements by submitting an issue or pull request.

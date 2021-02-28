
[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Signed
by](https://img.shields.io/badge/Keybase-Verified-brightgreen.svg)](https://keybase.io/hrbrmstr)
![Signed commit
%](https://img.shields.io/badge/Signed_Commits-100%25-lightgrey.svg)
[![Linux build
Status](https://travis-ci.org/hrbrmstr/brimr.svg?branch=master)](https://travis-ci.org/hrbrmstr/brimr)  
![Minimal R
Version](https://img.shields.io/badge/R%3E%3D-3.6.0-blue.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

# brimr

Tools to Work with Brim and zqd

## Description

Brim (<https://github.com/brimsec/brim>) enables efficient query
operations on large packqet captures and log sources, such as Zeek.
Tools are provided to with with Brim components, including the Brim zqd
query back-end.

## What’s Inside The Tin

The following functions are implemented:

-   `brim_ast`: Turn a Brim ZQL query into an abstract syntax tree
-   `brim_host`: Retrieve the Brim host URL
-   `brim_search_raw`: Post a ZQL query to the given Brim instance and
    retrieve results in raq ZJSON format
-   `brim_search`: Post a ZQL query to the given Brim instance and
    retrieve processed results
-   `brim_spaces`: Retrieve active Brim spaces from the specified Brim
    instance

## Installation

``` r
remotes::install_git("https://git.rud.is/hrbrmstr/brimr.git")
# or
remotes::install_gitlab("hrbrmstr/brimr")
# or
remotes::install_bitbucket("hrbrmstr/brimr")
```

NOTE: To use the ‘remotes’ install options you will need to have the
[{remotes} package](https://github.com/r-lib/remotes) installed.

## Usage

``` r
library(brimr)
library(tibble)

# current version
packageVersion("brimr")
## [1] '0.1.0'
```

``` r
brim_spaces()
## # A tibble: 1 x 4
##   id                 name                              data_path                                            storage_kind
## * <chr>              <chr>                             <chr>                                                <chr>       
## 1 sp_1p6pwLgtsESYBT… 2021-02-17-Trickbot-gtag-rob13-i… file:///Users/hrbrmstr/Library/Application%20Suppor… filestore

zql <- '_path=conn | count() by id.orig_h, id.resp_h, id.resp_p | sort id.orig_h, id.resp_h, id.resp_p'

cat(jsonlite::toJSON(jsonlite::fromJSON(brim_ast(zql)), pretty = TRUE))
## {
##   "op": ["SequentialProc"],
##   "procs": [
##     {
##       "op": "FilterProc",
##       "filter": {
##         "op": "CompareField",
##         "comparator": "=",
##         "field": {
##           "op": "BinaryExpr",
##           "operator": ".",
##           "lhs": {
##             "op": "RootRecord"
##           },
##           "rhs": {
##             "op": "Identifier",
##             "name": "_path"
##           }
##         },
##         "value": {
##           "op": "Literal",
##           "type": "string",
##           "value": "conn"
##         }
##       },
##       "keys": {},
##       "reducers": {},
##       "fields": {}
##     },
##     {
##       "op": "GroupByProc",
##       "filter": {
##         "field": {
##           "lhs": {},
##           "rhs": {}
##         },
##         "value": {}
##       },
##       "limit": 0,
##       "keys": [
##         {
##           "op": "Assignment",
##           "rhs": {
##             "op": "BinaryExpr",
##             "operator": ".",
##             "lhs": {
##               "op": "BinaryExpr",
##               "operator": ".",
##               "lhs": {
##                 "op": "RootRecord"
##               },
##               "rhs": {
##                 "op": "Identifier",
##                 "name": "id"
##               }
##             },
##             "rhs": {
##               "op": "Identifier",
##               "name": "orig_h"
##             }
##           }
##         },
##         {
##           "op": "Assignment",
##           "rhs": {
##             "op": "BinaryExpr",
##             "operator": ".",
##             "lhs": {
##               "op": "BinaryExpr",
##               "operator": ".",
##               "lhs": {
##                 "op": "RootRecord"
##               },
##               "rhs": {
##                 "op": "Identifier",
##                 "name": "id"
##               }
##             },
##             "rhs": {
##               "op": "Identifier",
##               "name": "resp_h"
##             }
##           }
##         },
##         {
##           "op": "Assignment",
##           "rhs": {
##             "op": "BinaryExpr",
##             "operator": ".",
##             "lhs": {
##               "op": "BinaryExpr",
##               "operator": ".",
##               "lhs": {
##                 "op": "RootRecord"
##               },
##               "rhs": {
##                 "op": "Identifier",
##                 "name": "id"
##               }
##             },
##             "rhs": {
##               "op": "Identifier",
##               "name": "resp_p"
##             }
##           }
##         }
##       ],
##       "reducers": [
##         {
##           "op": "Assignment",
##           "rhs": {
##             "op": "Reducer",
##             "operator": "count"
##           }
##         }
##       ],
##       "fields": {}
##     },
##     {
##       "op": "SortProc",
##       "filter": {
##         "field": {
##           "lhs": {},
##           "rhs": {}
##         },
##         "value": {}
##       },
##       "keys": {},
##       "reducers": {},
##       "fields": [
##         {
##           "op": "BinaryExpr",
##           "operator": ".",
##           "lhs": {
##             "op": "BinaryExpr",
##             "operator": ".",
##             "lhs": {
##               "op": "RootRecord"
##             },
##             "rhs": {
##               "op": "Identifier",
##               "name": "id"
##             }
##           },
##           "rhs": {
##             "op": "Identifier",
##             "name": "orig_h"
##           }
##         },
##         {
##           "op": "BinaryExpr",
##           "operator": ".",
##           "lhs": {
##             "op": "BinaryExpr",
##             "operator": ".",
##             "lhs": {
##               "op": "RootRecord"
##             },
##             "rhs": {
##               "op": "Identifier",
##               "name": "id"
##             }
##           },
##           "rhs": {
##             "op": "Identifier",
##             "name": "resp_h"
##           }
##         },
##         {
##           "op": "BinaryExpr",
##           "operator": ".",
##           "lhs": {
##             "op": "BinaryExpr",
##             "operator": ".",
##             "lhs": {
##               "op": "RootRecord"
##             },
##             "rhs": {
##               "op": "Identifier",
##               "name": "id"
##             }
##           },
##           "rhs": {
##             "op": "Identifier",
##             "name": "resp_p"
##           }
##         }
##       ],
##       "sortdir": 1,
##       "nullsfirst": false
##     }
##   ]
## }

space <- "2021-02-17-Trickbot-gtag-rob13-infection-in-AD-environment.pcap"

r <- brim_search(space, zql)

str(r, 2)
## List of 5
##  $ :List of 2
##   ..$ type   : chr "TaskStart"
##   ..$ task_id: int 0
##  $ :List of 3
##   ..$ type      : chr "SearchRecords"
##   ..$ channel_id: int 0
##   ..$ records   :'data.frame':   74 obs. of  4 variables:
##  $ :List of 3
##   ..$ type      : chr "SearchEnd"
##   ..$ channel_id: int 0
##   ..$ reason    : chr "eof"
##  $ :List of 7
##   ..$ type           : chr "SearchStats"
##   ..$ start_time     :List of 2
##   ..$ update_time    :List of 2
##   ..$ bytes_read     : int 238052
##   ..$ bytes_matched  : int 54486
##   ..$ records_read   : int 1082
##   ..$ records_matched: int 384
##  $ :List of 2
##   ..$ type   : chr "TaskEnd"
##   ..$ task_id: int 0
```

## brimr Metrics

| Lang | \# Files |  (%) | LoC |  (%) | Blank lines |  (%) | \# Lines |  (%) |
|:-----|---------:|-----:|----:|-----:|------------:|-----:|---------:|-----:|
| R    |        3 | 0.38 |  53 | 0.39 |          25 | 0.27 |       41 | 0.29 |
| Rmd  |        1 | 0.12 |  15 | 0.11 |          21 | 0.23 |       30 | 0.21 |
| SUM  |        4 | 0.50 |  68 | 0.50 |          46 | 0.50 |       71 | 0.50 |

clock Package Metrics for brimr

## Code of Conduct

Please note that this project is released with a Contributor Code of
Conduct. By participating in this project you agree to abide by its
terms.

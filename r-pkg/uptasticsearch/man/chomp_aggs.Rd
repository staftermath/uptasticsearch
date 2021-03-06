% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/elasticsearch_parsers.R
\name{chomp_aggs}
\alias{chomp_aggs}
\title{Aggs query to data.table}
\usage{
chomp_aggs(aggs_json = NULL)
}
\arguments{
\item{aggs_json}{A character vector. If its length is greater than 1, its elements will be pasted 
together. This can contain a JSON returned from a \code{aggs} query in Elasticsearch, or
a filepath or URL pointing at one. Most commonly, this JSON will be the direct result of 
running \code{\link[elastic]{Search}} with \code{raw = TRUE}.}
}
\description{
Given some JSON from an aggs query in Elasticsearch, parse the
             aggregations into a data.table.
}
\examples{
\dontrun{
##=== Example 1: Basic groupby ===#

# Get result from Elasticsearch
aggs_query <- "{'aggs': {'source': {'terms': {'field': 'pmt_method'}}}}"
result <- uptasticsearch:::.search_request(es_host = "http://es.custdb.mycompany.com:9200"
                                           , es_index = "ticket_sales"
                                           , query_body = aggs_query
                                           , trailing_args = "size=0")

# Parse into a data.table
aggDT <- chomp_aggs(aggs_json = result)

###=== Example 2: Time series features ===#

# Create query that will give you daily summary stats for revenue
query_body <- '{"query": {"filtered": {"filter": {
       "bool": {"must": [{"exists": {"field": "pmt_amount"}}]}}}},
               "aggs": {"timestamp": {"date_histogram": {"field": "timestamp", 
                                                       "interval": "day"},
              "aggs": {"revenue" : {"extended_stats": {"field": 
                                     "pmt_amount"}}}}},
               "size": 0
               }'
               
# Execute the query and get the result
result <- es_search(es_host = "http://es.custdb.mycompany.com:9200"
                    , es_index = 'ticket_sales'
                    , query_body = query_body)
                          
# Parse to a data.table                          
statDT <- chomp_aggs(aggs_json = result)

}
}

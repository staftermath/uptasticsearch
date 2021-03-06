
#' @title Examine the distribution of distinct values for a field in Elasticsearch
#' @name get_counts
#' @description For a given field, return a data table with its unique values
#' @importFrom data.table := data.table setnames setkeyv
#' @importFrom httr content POST
#' @importFrom purrr transpose
#' @export
#' @param field A valid field in whatever Elasticsearch index you are querying
#' @param es_host A string identifying an Elasticsearch host. This should be of the form 
#'        [transfer_protocol][hostname]:[port]. For example, 'http://myindex.thing.com:9200'.
#' @param es_index The name of an Elasticsearch index to be queried.
#' @param start_date A character date of the form "yyyy-mm-dd", indicating the earliest
#'        date from which to show documents. Set to NULL if you are looking at an index
#'        for which limiting results by time is irrelevant. Default is "now-1w".
#' @param end_date A character date of the form "yyyy-mm-dd", indicating the most recent
#'        date from which to show documents. Default is 10 "now". Set to NULL if you are 
#'        looking at an index for which limiting results by time is irrelevant.
#' @param use_na Argument to control handling of missing values in the result. Options are
#'        "always" to give a row in the table for NAs even if there are none, "ifany" to
#'        include a count of missing values if there are any. If neither of these is passed
#'        in, NAs will not be included in the result.
#' @param max_terms What is the maximum number of unique terms to return? Many production
#'                 Elasticsearch deployments limit this to a small number by default.
#' @param time_field Name of the date/time field in the target index that you want to filter on.
#' @examples
#' \dontrun{
#' # Count number of customers by payment method
#' recoDT <- get_counts(field = "pmt_method"
#'                     , es_host = "http://es.custdb.mycompany.com:9200"
#'                     , es_index = "ticket_sales"
#'                     , start_date = "now-2w"
#'                     , end_date = "now")
#' }
get_counts <- function(field
                      , es_host
                      , es_index
                      , start_date = "now-1w"
                      , end_date = "now"
                      , use_na = "always"
                      , max_terms = 1000
                      , time_field
){
    
    # Input checking
    es_host <- .ValidateAndFormatHost(es_host)
    
    #===== Format and execute query =====#
    
    # Support un-dated queries
    if (is.null(start_date)){
        start_date <- "null"
    } else {
        start_date <- paste0('"', start_date, '"')  
    }
    if (is.null(end_date)){
        end_date <- "null"
    } else {
        end_date <- paste0('"', end_date, '"')  
    }
    
    # Build query
    aggsQuery <- paste0('{"query": {"filtered": {"filter": {"bool": {"must": [
                        {"range": {"', time_field, '": {"gte":', start_date, ',"lte":', end_date, '}}}
                        ]}}}}, "aggs": {"', field, '": {"terms": {"field": "', field, '", "size":', max_terms,'}}}}')
    
    #===== Build search URL =====#
    searchURL  <- paste0(es_host, "/", es_index, "/_search?size=0")
    result     <- httr::POST(url = searchURL, body = aggsQuery)
    counts     <- httr::content(result, as = "parsed")[["aggregations"]][[field]][["buckets"]]
    
    #===== Get data =====#
    # Deal w/ case where the field doesn't exist for any records
    if (length(counts) == 0) {
        resultDT = data.table::data.table(keyval = character(0), count = integer(0))
    } else {
        # Get into a data.table
        countsT  <- purrr::transpose(counts)
        resultDT <- data.table::data.table(keyval = unlist(countsT[["key"]]), count = unlist(countsT[["doc_count"]]))
    }
    
    # Reformat
    data.table::setnames(resultDT, "keyval", field)
    
    #===== Return now if we're not dealing with NAs =====#
    if (is.null(use_na) || !use_na %in% c("always", "ifany")){
        return(resultDT)
    }
    
    #===== Find the number of missing records =====#
    # Build Query
    missingQuery <- paste0('{"query": {"filtered": {"filter": {"bool": {"must": [
        {"range": {"', time_field, '": {"gte":', start_date, ', "lte":', end_date, '}}},
        {"missing": {"field": "', field, '"}}]}}}}}')
    
    # Get result
    result      <- httr::POST(url = searchURL, body = missingQuery)
    numMissings <- httr::content(result, as = "parsed")[["hits"]][["total"]]
    
    # Return now if user asked to only see NAs if there are any
    if (numMissings == 0 & use_na == "ifany"){
        return(resultDT)
    }
    
    # Append count of NAs to the data table
    naDT <- data.table::data.table(keyval = NA, count = numMissings)
    
    # Reformat
    data.table::setnames(naDT, "keyval", field)
    
    # Return
    return(rbind(naDT, resultDT))
    
}


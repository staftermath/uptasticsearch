% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/elasticsearch_parsers.R
\name{parse_date_time}
\alias{parse_date_time}
\title{Parse date-times from Elasticsearch records}
\usage{
parse_date_time(input_df, date_cols, assume_tz = "UTC")
}
\arguments{
\item{input_df}{a data.table with one or more dateTime columns you want to convert}

\item{date_cols}{Character vector of column names to convert. Columns should have
string dates of the form "2016-07-25T22:15:19Z".}

\item{assume_tz}{Timezone to convert to if parsing fails. Default is UTC}
}
\description{
Given a data.table with date-time strings,
             this function converts those dates-times to type POSIXct with the appropriate
             time zone. Assumption is that dates are of the form "2016-07-25T22:15:19Z"
             where T is just a separator and the last letter is a military timezone.
}
\examples{
\dontrun{

# Get some data
result <- es_search(es_host = "http://es.custdb.mycompany.com:9200"
                 , es_index = 'cust_details')
          
# Note that the date field is character right now
class(someDT$timestamp)

# Let's fix that!
someDT <- parse_date_time(someDT, date_cols = "timestamp")
class(someDT$timestamp)

}
}
\references{
\url{https://www.timeanddate.com/time/zones/military}

\url{https://en.wikipedia.org/wiki/List_of_tz_database_time_zones}
}

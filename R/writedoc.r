#' Write documents to a database.
#'
#' @export
#' @inheritParams ping
#' @param dbname Database name3
#' @param doc Document content
#' @param docid Document ID
#' @param apicall If TRUE, write with json format e.g.:
#'    {
#'      "baseurl" : "http://alm.plos.org/api/v3/articles",
#'      "yourqueryargs" : "doi=10.1371/journal.pone.0060590",
#'      "response": "response_from_the_api"
#'    }
#' @param baseurl Base url for the web API call
#' @param queryargs Web API query arguments to pass in to json with document
#' @param username Your cloudant or iriscouch username
#' @param pwd Your cloudant or iriscouch password
#' @examples \donttest{
#' # write a document WITH a name (uses PUT)
#' doc1 <- '{"name":"drink","beer":"IPA"}'
#' writedoc(dbname="sofadb", doc=doc1, docid="abeer")
#' getdoc(dbname = "sofadb", docid = "abeer")
#'
#' # write a json document WITHOUT a name (uses POST)
#' doc2 <- '{"name":"food","icecream":"rocky road"}'
#' writedoc(dbname="sofadb", doc=doc2)
#'
#' doc3 <- '{"planet":"mars","size":"smallish"}'
#' writedoc(dbname="sofadb", doc=doc3)
#'
#' # write an xml document WITH a name (uses PUT). xml is written as xml in
#' # couchdb, just wrapped in json, when you get it out it will be as xml
#' doc4 <- "<top><a/><b/><c><d/><e>bob</e></c></top>"
#' writedoc(dbname="sofadb", doc=doc4, docid="somexml")
#' getdoc(dbname = "sofadb", docid = "somexml")
#'
#' # write a document using web api storage format
#' doc <- '{"downloads":10,"pageviews":5000,"tweets":300}'
#' writedoc(dbname="sofadb", doc=doc, docid="asdfg", apicall=TRUE, baseurl="http://things...",
#'    queryargs="some args")
#' getdoc(dbname = "sofadb", docid = "asdfg")
#' }

writedoc <- function(endpoint="localhost", port=5984, dbname, doc, docid=NULL, apicall=FALSE,
  baseurl, queryargs, username=NULL, pwd=NULL, ...)
{
  endpoint <- match.arg(endpoint,choices=c("localhost","cloudant","iriscouch"))

  if(endpoint=="localhost"){
    call_ <- sprintf("http://127.0.0.1:%s/%s", port, dbname)
  } else
    if(endpoint=="cloudant"){
      auth <- get_pwd(username,pwd,"cloudant")
      call_ <- sprintf('https://%s:%s@%s.cloudant.com/%s', auth[[1]], auth[[2]], auth[[1]], dbname)
    } else
    {
      auth <- get_pwd(username,pwd,"iriscouch")
      call_ <- sprintf('https://%s.iriscouch.com/%s', auth[[1]], dbname)
    }

  if(apicall){
    doc2 <- paste('{"baseurl":', '"', baseurl, '",', '"queryargs":',
                  toJSON(queryargs, collapse=""), ',', '"response":', doc, "}", sep="")
    if(!is.null(docid)){
      call_ <- paste0(call_, "/", docid)
      sofa_PUT(call_, body=doc2, ...)
    } else {
      sofa_POST(call_, body=doc2, content_type_json(), ...)
    }
  } else {
    doc2 <- doc
    if(grepl("<[A-Za-z]+>", doc)) doc2 <- paste('{"xml":', '"', doc, '"', '}', sep="")
    if(!is.null(docid)){
      sofa_PUT(paste0(call_, "/", docid), body=doc2, ...)
    } else {
      sofa_POST(call_, body=doc2, content_type_json(), ...)
    }
  }
}

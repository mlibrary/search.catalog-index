require "sinatra/base"
require "sinatra/namespace"
require "puma"
require "mlibrary_search_parser"
require_relative "lib/services"
require "yaml"
require "debug"
require "active_support"
require "active_support/core_ext/hash/indifferent_access"

module SearchParser
  CATALOG_CONFIG = YAML.safe_load_file("./config/catalog.yaml", aliases: true)
  CATALOG_BUILDER = MLibrarySearchParser::SearchBuilder.new(CATALOG_CONFIG)
  FACETS = CATALOG_CONFIG["facets"]

  def self.catalog_config
    CATALOG_CONFIG
  end

  def self.build(query)
    CATALOG_BUILDER.build(query)
  end

  def self.misc
    {}
  end

  def self.facet_params
    result = {}
    FACETS.map do |field|
      result["f.#{field}.facet.limit"] = "50"
      result["f.#{field}.facet.mincount"] = "1"
      result["f.#{field}.facet.offset"] = "0"
      result["f.#{field}.facet.sort"] = "count"
    end
    result["facet.field"] = FACETS
    result["fl"] = "*,score"
    result["facet"] = true

    result
  end

  # copied from: https://github.com/rsolr/rsolr/blob/a60ec42b58f3b068f23537e49d0b6510bb12ee17/lib/rsolr.rb#L25
  # backslash escape characters that have special meaning to Solr query parser
  # per http://lucene.apache.org/core/4_0_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html#Escaping_Special_Characters
  #  + - & | ! ( ) { } [ ] ^ " ~ * ? : \ /
  # see also http://svn.apache.org/repos/asf/lucene/dev/tags/lucene_solr_4_9_1/solr/solrj/src/java/org/apache/solr/client/solrj/util/ClientUtils.java
  #   escapeQueryChars method
  # @return [String] str with special chars preceded by a backslash
  def self.solr_escape(str)
    # note that the gsub will parse the escaped backslashes, as will the ruby code sending the query to Solr
    # so the result sent to Solr is ultimately a single backslash in front of the particular character
    str.gsub(/([+\-&|!(){}\[\]\^"~*?:\\\/])/, '\\\\\1')
  end

  def self.solr_query(query:, rows: 10, start: 0)
    # how to handle fq:
    # fq":["topicStr:(Motion\\ pictures)","institution:(UM\\ Ann\\ Arbor\\ Libraries)","+(new_availability:physical OR new_availability:hathi_trust_full_text_or_electronic_holding)"]
    # sort comes from config/sorts.yml
    lp = MLibrarySearchParser::Transformer::Solr::LocalParams.new(build(query))
    result = {
      rows: rows,
      start: start
    }.merge(facet_params).merge(lp.params).with_indifferent_access
    result["qt"] = "standard" unless ["edismax", "dismax"].include?(result["qt"]) # code from spectrum so I don't forget. Don't know if we need this.
    result["qq"] = '"' + solr_escape(result["q"]) + '"'
    result["sort"] = "score desc"
    result["fq"] = ["institution:(UM\\ Ann\\ Arbor\\ Libraries)", "+(new_availability:physical OR new_availability:hathi_trust_full_text_or_electronic_holding)"]

    result
  end
end

class SearchParser::Application < Sinatra::Base
  register Sinatra::Namespace
  namespace "/catalog" do
    get "/search" do
      content_type :json
      query_params = {
        query: params["query"] || "",
        rows: params["rows"] || 10,
        start: params["start"] || 0
      }
      S.solr_conn.get("solr/#{S.solr_core}/select", SearchParser.solr_query(**query_params)).body.to_json
    end
  end
end

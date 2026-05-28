require "sinatra/base"
require "sinatra/namespace"
require "puma"
require "mlibrary_search_parser"
require "yaml"
require "active_support"
require "active_support/core_ext/hash/indifferent_access"
require_relative "lib/services"
require_relative "lib/metrics"
require "debug" if S.app_env == "development"

Metrics::Yabeda.configure!

module SearchParser
  CATALOG_CONFIG = YAML.safe_load_file("./config/catalog.yaml", aliases: true).freeze
  CATALOG_BUILDER = MLibrarySearchParser::SearchBuilder.new(CATALOG_CONFIG)
  FACETS = CATALOG_CONFIG["facets"].freeze

  def self.build(query)
    CATALOG_BUILDER.build(query)
  end

  def self.facets
    FACETS
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

  def self.solr_query(query:, rows:, start:, sort:, fq:)
    # how to handle fq:
    # fq":["topicStr:(Motion\\ pictures)","institution:(UM\\ Ann\\ Arbor\\ Libraries)","+(new_availability:physical OR new_availability:hathi_trust_full_text_or_electronic_holding)"]
    # sort comes from config/sorts.yml
    lp = MLibrarySearchParser::Transformer::Solr::LocalParams.new(build(query))

    result = {
      rows: rows,
      start: start,
      sort: sort,
      fq: fq
    }.merge(facet_params).merge(lp.params).with_indifferent_access

    result["qt"] = "standard" unless ["edismax", "dismax"].include?(result["qt"]) # code from spectrum so I don't forget. Don't know if we need this.
    result["qq"] = '"' + solr_escape(result["q"]) + '"'

    result
  end

  def self.academic_discipline_solr_query(query:, sort:, fq:)
    # how to handle fq:
    # fq":["topicStr:(Motion\\ pictures)","institution:(UM\\ Ann\\ Arbor\\ Libraries)","+(new_availability:physical OR new_availability:hathi_trust_full_text_or_electronic_holding)"]
    # sort comes from config/sorts.yml
    lp = MLibrarySearchParser::Transformer::Solr::LocalParams.new(build(query))

    {
      rows: 100,
      start: 0,
      sort: sort,
      fq: fq,
      fl: "hlb3Str"
    }.merge(lp.params).with_indifferent_access
  end
end

class SearchParser::Application < Sinatra::Base
  register Sinatra::Namespace
  set :host_authorization, {permitted_hosts: []}
  namespace "/catalog" do
    get "/search" do
      headers "metrics.route" => "catalog/search"
      content_type :json
      query_params = {
        query: params["query"] || "",
        rows: params["rows"] || 10,
        start: params["start"] || 0,
        sort: params["sort"] || "score desc",
        fq: params["fq"] || ["institution:(UM\\ Ann\\ Arbor\\ Libraries)", "+(availability:physical OR availability:hathi_trust_full_text_or_electronic_holding)"]
      }
      #      response = nil
      solr_params = SearchParser.solr_query(**query_params)
      #      Yabeda.catalog_solr_query_duration.measure do
      response = S.solr_conn.get("solr/#{S.solr_core}/select", solr_params)
      #      end
      response.body.to_json
    end

    get "/academic_disciplines" do
      headers "metrics.route" => "catalog/academic_disciplines"
      content_type :json
      query_params = {
        query: params["query"] || "",
        sort: params["sort"] || "score desc",
        fq: params["fq"] || ["institution:(UM\\ Ann\\ Arbor\\ Libraries)", "+(availability:physical OR availability:hathi_trust_full_text_or_electronic_holding)"]
      }
      solr_params = SearchParser.academic_discipline_solr_query(**query_params)

      response = S.solr_conn.get("solr/#{S.solr_core}/select", solr_params)

      response.body.to_json
    end
  end
end

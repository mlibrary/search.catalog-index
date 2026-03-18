RSpec.describe "requests" do
  context "get /catalog/search" do
    it "calls solr with the given query parameters" do
      solr_stub = stub_request(:get, "#{S.solr_url}/solr/biblio/select").with(query: hash_including({
        q1: "blah",
        start: "0",
        rows: "10",
        sort: "score desc",
        fl: "*,score",
        facet: "true"
      }))
      get "/catalog/search", {query: "blah"}
      expect(solr_stub).to have_been_requested
    end
    it "includes solr quoted string for qq" do
      solr_stub = stub_request(:get, "#{S.solr_url}/solr/biblio/select").with(query: hash_including({qq: /^"_query_/, q: /^_query_/, start: "0", rows: "10"}))
      get "/catalog/search", {query: "blah"}
      expect(solr_stub).to have_been_requested
    end
    SearchParser.facets.each do |facet|
      context "#{facet} parameters" do
        it "has the expected facet parameters" do
          solr_stub = stub_request(:get, "#{S.solr_url}/solr/biblio/select").with(query: hash_including({
            "f.#{facet}.facet.limit" => "50",
            "f.#{facet}.facet.mincount" => "1",
            "f.#{facet}.facet.offset" => "0",
            "f.#{facet}.facet.sort" => "count"
          }))
          get "/catalog/search"
          expect(solr_stub).to have_been_requested
        end
      end
    end
  end
end

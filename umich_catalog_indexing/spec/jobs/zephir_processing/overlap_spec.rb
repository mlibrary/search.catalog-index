describe Jobs::ZephirProcessing::Overlap do
  context ".umich_oclc_nums" do
    it "returns a list of oclc numbers that are in the overlap file" do
      S.overlap_db[:overlap].insert(oclc: 111)
      S.overlap_db[:overlap].insert(oclc: 111)
      S.overlap_db[:overlap].insert(oclc: 123)
      S.overlap_db[:overlap].insert(oclc: 555)
      S.overlap_db[:overlap].insert(oclc: 555)
      expect(described_class.umich_oclc_nums([222, 333, 111, 123])).to contain_exactly(111, 123)
    end
  end
end

module HathifilesDatabaseActions
  class Full < Modifier
    def hathifile
      "hathi_full_#{@date_str}.txt.gz"
    end

    def command
      @connection.start_from_scratch "#{@scratch_dir}/#{hathifile}", destination_dir: scratch_dir
    end
  end
end

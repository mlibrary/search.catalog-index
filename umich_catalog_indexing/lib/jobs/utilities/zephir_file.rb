module Jobs
  module Utilities
    class ZephirFile
      def self.latest_monthly_full(today=Date.today)
        prev_month = today.prev_month
        last_day_of_last_month = Date.new(prev_month.year, prev_month.month, -1)
        "zephir_full_#{format_date(last_day_of_last_month)}_vufind.json.gz"
      end
      def self.latest_daily_update(today=Date.today)
        "zephir_upd_#{format_date(today.prev_day)}.json.gz"
      end
      def self.daily_update(date)
        latest_daily_update(date)
      end
      def self.format_date(date)
        date.strftime("%Y%m%d")
      end
    end
  end
end

#!/usr/local/bin/ruby
require "date"
require_relative "../lib/jobs"
require "logger"
require "byebug"

logger = S.logger
logger.info 'Start Prep for full reindex of HT metadata'

#zephir_file = "zephir_upd_20220301.json.gz"
zephir_file = "zephir_full_20240229_vufind_04.json.gz"

S.logger.measure_info("zephir processing") do
  Jobs::ZephirProcessing.run(full_zephir_file: zephir_file, batch_size: 200)
end


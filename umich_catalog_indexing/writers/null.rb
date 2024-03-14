require "traject"
require "traject/null_writer"

settings do
  store "writer_class_name", "Traject::NullWriter"
  store "output_file", "debug.json"
  provide "processing_thread_pool", ENV.fetch("NUM_THREADS", 1)
  provide "log.batch_size", 50_000
end

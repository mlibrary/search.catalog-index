require "./app"
require "./lib/structured_access_logging_middleware"

use Rack::Deflater
use StructuredAccessLoggingMiddleware

run SearchParser::Application

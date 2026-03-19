require "./app"
require "./lib/structured_access_logging_middleware"

use Metrics::Middleware
use Rack::Deflater
use StructuredAccessLoggingMiddleware

run SearchParser::Application

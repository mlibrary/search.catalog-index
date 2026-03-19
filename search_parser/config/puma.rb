require_relative "../lib/metrics"

activate_control_app(Metrics::PumaConfig.control_app_url, Metrics::PumaConfig.control_app_opts)
plugin :yabeda
plugin :yabeda_prometheus # This sets up metrics on port 9394
prometheus_exporter_url(Metrics::PrometheusConfig.exporter_url)

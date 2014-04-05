require 'test_helper'

require 'metriks/librato_metrics_reporter'

class LibratoMetricsReporterTest < Test::Unit::TestCase
  def build_reporter(options={})
    Metriks::LibratoMetricsReporter.new('user', 'password', { :registry => @registry }.merge(options))
  end

  def setup
    @registry = Metriks::Registry.new
    @reporter = build_reporter
  end

  def teardown
    @reporter.stop
    @registry.stop
  end

  def test_write
    @registry.meter('meter.testing').mark
    @registry.counter('counter.testing').increment
    @registry.timer('timer.testing').update(1.5)
    @registry.histogram('histogram.testing').update(1.5)
    @registry.utilization_timer('utilization_timer.testing').update(1.5)
    @registry.gauge('gauge.testing') { 123 }

    @reporter.expects(:submit)

    @reporter.write

    @reporter.data.detect { |(k,v)| k =~ /gauges\[\d+\]\[name\]/ && v == 'gauge.testing' } &&
      @reporter.data.detect { |(k,v)| k =~ /gauges\[\d+\]\[value\]/ && v.to_s == '123' }
  end

  def test_empty_write
    @reporter.expects(:submit).never
    @reporter.write
  end
end

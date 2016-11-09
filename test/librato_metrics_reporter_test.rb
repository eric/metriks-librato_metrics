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

  def test_raises_on_invalid_keys
    err = Metriks::LibratoMetricsReporter::InvalidKeyError
    %w[invalid.utf8—key invalid.ascii?key invalid.punctuation/key].each do |key|
      assert_raise(err, "error on invalid key #{key}") do
        @registry.counter(key)
        @reporter.write
      end
    end
  end

  def test_sanitizes_by_string
    @reporter = build_reporter(:sanitize => ".")
    @registry.counter("invalid.ascii?key")
    @reporter.expects(:submit)
    @reporter.write
    assert_equal(@reporter.data["gauges[0][name]"], "invalid.ascii.key")
  end

  def test_sanitizes_by_proc
    @reporter = build_reporter(:sanitize => Proc.new { |key| "bats" })
    @registry.counter("invalid.ascii?key")
    @reporter.expects(:submit)
    @reporter.write
    assert_equal(@reporter.data["gauges[0][name]"], "bats")
  end

  def test_raises_on_invalid_sanitized_key
    @reporter = build_reporter(:sanitize => Proc.new { |key| "bats" * 100 })
    assert_raise Metriks::LibratoMetricsReporter::InvalidKeyError do
      @registry.counter("invalid.ascii?key")
      @reporter.write
    end
  end

  def test_write_with_source_unset
    @registry.meter('meter.testing').mark

    @reporter.expects(:submit)
    @reporter.write

    assert @reporter.data.none? { |(k,v)| k =~ /gauges\[\d+\]\[source\]/ }
  end

  def test_write_with_source_set
    @reporter = build_reporter(:source => "localhost")
    @registry.meter('meter.testing').mark

    @reporter.expects(:submit)
    @reporter.write

    assert @reporter.data.detect { |(k,v)| k =~ /gauges\[\d+\]\[source\]/ && v == "localhost" }
  end
end

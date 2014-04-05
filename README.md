# Metriks reporter for Librato Metrics

This is the [metriks](https://github.com/eric/metriks) reporter for Librato Metrics.

## How to use it

Sends metrics to Librato Metrics every 60 seconds.

``` ruby
  reporter = Metriks::LibratoMetricsReporter.new('email', 'token')
  reporter.start
```

# License

Copyright (c) 2012 Eric Lindvall

Published under the MIT License, see LICENSE
require "flexible_retry/version"

module FlexibleRetry
  def retry_if(options = {}, &block)
    RetryProxy.new(self, options.merge(expected_logical_value: false), &block)
  end

  def retry_unless(options = {}, &block)
    RetryProxy.new(self, options.merge(expected_logical_value: true), &block)
  end

  class RetryProxy
    def initialize(subject,  expected_logical_value: false,retry_count: 5, interval: 1, &block)
      @expected_logical_value = expected_logical_value
      @subject                = subject
      @interval               = interval
      @retry_count            = retry_count
      @checker                = block
    end

    def method_missing(name, *args, &block)
      (1 + @retry_count).times do |i|
        result = @subject.send(name, *args, &block)

        to_retry = begin
                     @expected_logical_value ^ @checker.call(result)
                   rescue => e
                     true
                   end

        if to_retry && i < @retry_count
          warn "retry: #{i+1}" if ENV["DEBUG"] == "1"
          sleep @interval
          next
        else
          return result
        end
      end
    end
  end
end

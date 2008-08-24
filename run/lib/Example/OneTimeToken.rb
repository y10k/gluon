require 'thread'

class Example
  class OneTimeToken
    include Gluon::Web::OneTimeToken

    class Count
      def initialize
	@lock = Mutex.new
	@value = 0
      end

      def value
	@lock.synchronize{ @value }
      end

      def succ!
	@lock.synchronize{ @value += 1 }
	self
      end
    end

    COUNT = Count.new

    def initialize
      super                     # for Gluon::Web::OneTimeToken
      @c = nil
      @errors = Gluon::Web::ErrorMessages.new
      @count = COUNT.value
      @now = Time.now
    end

    attr_writer :c
    attr_reader :errors
    attr_reader :count

    def now
      @now.to_s
    end

    def page_start
      unless (one_time_token_valid?) then
        @errors << 'No reload!'
        @c.validation = false
      end
    end

    def count_up
      COUNT.succ!
      @count = COUNT.value
    end
    gluon_export :count_up
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

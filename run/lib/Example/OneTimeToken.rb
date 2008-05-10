require 'thread'

class Example
  class OneTimeToken
    include Gluon::Web::OneTimeToken

    attr_writer :c

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

    def page_start
      one_time_token_setup      # for Gluon::Web::OneTimeToken
      @count = COUNT.value
      @now = Time.now
    end

    # default page_check is defined by Gluon::Web::OneTimeToken

    attr_reader :count

    def count_up
      sleep(5)
      COUNT.succ!
      @count = COUNT.value
    end

    def now
      @now.to_s
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

require 'thread'

class Example
  class OneTimeToken
    include Gluon::Controller
    include Gluon::ERBView
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

    def page_start
      @errors = Gluon::Web::ErrorMessages.new
      @count = COUNT.value
      @now = Time.now
    end

    #def page_get
    #def page_post
    def page_import
      if (one_time_token_valid?) then
        @c.validation = true
      else
        @c.validation = false
        @errors << 'Not reload!'
      end
    end

    def action_path
      @c.class2path(OneTimeToken, @c.path_info)
    end

    attr_reader :errors
    attr_reader :count

    def now
      @now.to_s
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

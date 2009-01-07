require 'thread'

class Example
  class PageCache
    include Gluon::Controller
    include Gluon::ERBView

    class Counter
      def initialize
        @lock = Mutex.new
        @value = 0
      end

      def up
        @lock.synchronize{
          @value += 1
        }
      end

      def value
        @lock.synchronize{
          @value
        }
      end
    end

    COUNT = Counter.new

    def __if_modified__(cache_tag)
      if (@c.req.post?) then
        :no_cache
      else
        COUNT.value != cache_tag
      end
    end

    def page_start
      @c.cache_tag = COUNT.value
      @created_time = Time.now
    end

    def page_get
    end

    def page_post
      @c.validation = true
    end

    def action_path
      @c.class2path(PageCache)
    end

    attr_reader :created_time

    def page_cache?
      @c.req.env['gluon.page_cache']
    end

    def expire
      COUNT.up
    end
    gluon_export :expire
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

require 'forwardable'

class Example
  class Session
    extend Forwardable

    attr_accessor :c
    def_delegator :c, :session_id

    def page_start
      if (@session = @c.session_get(false)) then
        @session[:count] += 1
      end
    end

    def new_session
      @c.session_delete
      @session = @c.session_get(true)
      @session[:created_time] = Time.now
      @session[:count] = 0
      nil
    end

    def clear_session
      @c.session_delete
      @session = nil
      nil
    end

    def reload
      return ExamplePanel, :path_info => @c.path_info
    end

    def has_session?
      @session != nil
    end

    def created_time
      @session[:created_time]
    end

    def count
      @session[:count]
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

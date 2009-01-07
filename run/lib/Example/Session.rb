require 'forwardable'

class Example
  class Session
    extend Forwardable
    include Gluon::Controller
    include Gluon::ERBView

    def_delegator :@c, :session_id

    def page_start
      if (@session = @c.session_get(false)) then
        @session[:count] += 1
      end
    end

    #def page_get
    #def page_post
    def page_import
      @c.validation = true
    end

    def action_path
      @c.class2path(ExamplePanel, Session)
    end

    def new_session
      @c.session_delete
      @session = @c.session_get(true)
      @session[:created_time] = Time.now
      @session[:count] = 0
      nil
    end
    gluon_export :new_session

    def clear_session
      @c.session_delete
      @session = nil
      nil
    end
    gluon_export :clear_session

    def reload
      return ExamplePanel, :path_args => [ Session ]
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

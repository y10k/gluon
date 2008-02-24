# mock

require 'forwardable'
require 'gluon/rs'
require 'rack'

module Gluon
  class Mock
    # for ident(1)
    CVS_ID = '$Id$'

    extend Forwardable

    def initialize(url_map=[])
      @dispatcher = Dispatcher.new(url_map)
      @session_man = MockSessionManager.new
      @session = nil
    end

    attr_reader :dispatcher

    def new_request(env)
      req = Rack::Request.new(env)
      res = Rack::Response.new
      @session = @session_man.new_mock_session(req, res)
      Gluon::RequestResponseContext.new(req, res, @session, @dispatcher)
    end

    def_delegator :@session, :get_for_mock, :session_get
    def_delegator :@session, :session_next

    def close_response
      @session.save_all
      @session = nil
    end
  end

  class MockSessionManager < SessionManager
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize
      super(:auto_expire => false,
	    :store => MemoryStore.new)
    end

    def new_mock_session(req, res)
      MockSessionHandler.new(self, req, res)
    end
  end

  class MockSessionHandler < SessionHandler
    # for ident(1)
    CVS_ID = '$Id$'

    def get_for_mock(options={})
      get(false, options)
    end

    def next(env)
      env['HTTP_COOKIE'] = @sessions.map{|key, (id, *others)| "#{key}=#{id}" }.join('; ')
      env
    end
  end
end

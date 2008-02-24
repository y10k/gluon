# mock session

require 'gluon/rs'
require 'rack'

module Gluon
  class Mock
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(url_map=[])
      @dispatcher = Dispatcher.new(url_map)
    end

    attr_reader :dispatcher

    def new_request(env)
      req = Rack::Request.new(env)
      res = Rack::Response.new
      session = Object.new	# dummy
      Gluon::RequestResponseContext.new(req, res, session, @dispatcher)
    end
  end
end

# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

require 'forwardable'
require 'gluon/renderer'
require 'gluon/rs'
require 'rack'

module Gluon
  # = mock request-response
  class Mock
    # for ident(1)
    CVS_ID = '$Id$'

    extend Forwardable

    def initialize(options={})
      @url_map = URLMap.new
      (options[:url_map] || []).each do |page_type, location, path_filter|
	@url_map.mount(page_type, location, path_filter)
      end
      @url_map.setup

      @session_man = MockSessionManager.new
      @session = nil

      plugin = options[:plugin] || {}
      @plugin_maker = PluginMaker.new
      for name, value in plugin
	@plugin_maker.add(name, value)
      end
      @plugin_maker.setup

      @view_dir = options[:view_dir] || Dir.getwd
      @renderer = ViewRenderer.new(@view_dir)
    end

    attr_reader :url_map

    def new_request(env)
      req = Rack::Request.new(env)
      res = Rack::Response.new
      @session = @session_man.new_mock_session(req, res)
      plugin = @plugin_maker.new_plugin
      Gluon::RequestResponseContext.new(req, res, @session,
					@url_map, plugin, @renderer)
    end

    def_delegator :@session, :get_for_mock, :session_get

    def close_response(next_env={})
      @session.next_session(next_env)
      @session.save_all
      next_env
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

    def next_session(env)
      env['HTTP_COOKIE'] = @sessions.map{|key, (id, *others)| "#{key}=#{id}" }.join('; ')
      env
    end
  end
end

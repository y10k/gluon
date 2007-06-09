# application builder

require 'gluon/action'
require 'gluon/dispatcher'
require 'gluon/po'
require 'rack'

module Gluon
  class Builder
    # for ident(1)
    CVS_ID = '$Id$'

    def self.require_path(lib_dir)
      unless ($:.include? lib_dir) then
	$: << lib_dir
      end
      nil
    end

    def initialize(options={})
      if (options.key? :lib_dir) then
	Builder.require_path(options[:lib_dir])
      end
      @view_dir = options[:view_dir]
      @access_log = nil
      @url_map = []
    end

    def access_log(path)
      @access_log = path
      nil
    end

    def mount(page_type, path)
      @url_map << [ path, page_type ]
      nil
    end

    def load_conf(path)
      script = IO.read(path)
      eval(script, binding, path)
      nil
    end

    def build
      dispatcher = Dispatcher.new(@url_map)
      app = proc{|env|
	req = Rack::Request.new(env)
	res = Rack::Response.new
	if (page_type = dispatcher.look_up(req.path_info)) then
	  page = page_type.new
	  action = Action.new(page, req, res)
	  po = PresentationObject.new(page, req, res)
	  context = ERBContext.new(po, req, res)

	  action.apply{
	    erb_script = IO.read(File.join(@view_dir, po.view_name))
	    res.write(Gluon::ERBContext.render(context, erb_script))
	  }

	  res.finish
	else
	  [ 404, { "Content-Type" => "text/plain" }, [ "Not Found: #{req.path_info}" ] ]
	end
      }

      app = Rack::ShowExceptions.new(app)
      if (@access_log) then
	logger = File.open(@access_log, 'a')
	logger.binmode
	logger.sync = true
	app = Rack::CommonLogger.new(app, logger)
      else
	app = Rack::CommonLogger.new(app)
      end

      app
    end
  end
end

# application builder

require 'gluon/action'
require 'gluon/dispatcher'
require 'gluon/po'
require 'gluon/renderer'
require 'gluon/version'
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
      @base_dir = options[:base_dir]
      @view_dir = options[:view_dir]
      @conf_path = options[:conf_path]
      @access_log = nil
      @port = 9202
      @url_map = []
    end

    attr_reader :base_dir
    attr_reader :view_dir
    attr_reader :conf_path

    def access_log(path)
      @access_log = path
      nil
    end

    def port(num)
      @port = num
      nil
    end

    def mount(page_type, path)
      @url_map << [ path, page_type ]
      nil
    end

    def load_conf
      script = IO.read(@conf_path)
      eval(script, binding, @conf_path)
      nil
    end

    def build
      dispatcher = Dispatcher.new(@url_map)
      renderer = ViewRenderer.new(@view_dir)
      app = proc{|env|
        req = Rack::Request.new(env)
        res = Rack::Response.new
        page_type, gluon_path_info = dispatcher.look_up(req.path_info)
        if (page_type) then
          req.env['gluon.version'] = VERSION
          req.env['gluon.curr_page'] = page_type
          req.env['gluon.path_info'] = gluon_path_info
          page = page_type.new
          action = Action.new(page, req, res)
          po = PresentationObject.new(page, req, res, dispatcher, renderer)
          context = ERBContext.new(po, req, res)
          action.apply{ res.write(renderer.render(context)) }
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

      { :application => app, :port => @port }
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

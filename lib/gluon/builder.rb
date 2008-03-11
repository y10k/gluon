# application builder

require 'forwardable'
require 'gluon/action'
require 'gluon/dispatcher'
require 'gluon/plugin'
require 'gluon/po'
require 'gluon/renderer'
require 'gluon/rs'
require 'gluon/version'
require 'rack'
require 'thread'

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
      @session_conf = SessionConfig.new
      @access_log = File.join(@base_dir, 'access.log')
      @port = 9202
      @page_cache = false
      @url_map = []
      @plugin_maker = PluginMaker.new
      @finalizer = proc{}
    end

    attr_reader :base_dir
    attr_reader :view_dir
    attr_reader :conf_path
    attr_reader :session_conf

    attr_accessor :access_log
    attr_accessor :port
    attr_accessor :page_cache

    def mount(page_type, path)
      @url_map << [ path, page_type ]
      nil
    end

    def find(path)
      (entry = @url_map.assoc(path)) && entry[1]
    end

    def plugin_get(name)
      name = name.to_sym
      plugin = @plugin_maker.new_plugin
      if (block_given?) then
        yield(plugin[name])
      else
        plugin[name]
      end
    end

    def plugin_set(args)
      if (block_given?) then
        name = args.to_sym
        @plugin_maker.add(name, yield)
      else
        case (args)
        when Hash
          for name, value in args
            name = name.to_sym
            @plugin_maker.add(name, value)
          end
        else
          raise "unknown arguments: #{args.inspect}"
        end
      end
      nil
    end

    class SessionConfig
      def initialize
        @options = {}
      end

      attr_reader :options

      def default_key(value)
        @options[:default_key] = value
      end

      def default_domain(value)
        @options[:default_domain] = value
      end

      def default_path(value)
        @options[:default_path] = value
      end

      def id_max_length(value)
        @options[:id_max_length] = value
      end

      def time_to_live(value)
        @options[:time_to_live] = value
      end

      def auto_expire(value)
        @options[:auto_expire] = value
      end

      def digest(value)
        @options[:digest] = value
      end

      def store(value)
        @options[:store] = value
      end
    end

    def initial(&block)
      InitialContext.new(self).instance_eval(&block)
      nil
    end

    def final(&block)
      @finalizer = block
      nil
    end

    def session(&block)
      SessionContext.new(self).instance_eval(&block)
    end

    class Context
      extend Forwardable

      def initialize(builder)
        @builder = builder
      end

      def_delegator :@builder, :base_dir
      def_delegator :@builder, :view_dir
      def_delegator :@builder, :conf_path
    end

    class TopLevelContext < Context
      def_delegator :@builder, :access_log=, :access_log
      def_delegator :@builder, :port=, :port
      def_delegator :@builder, :page_cache=, :page_cache
      def_delegator :@builder, :mount
      def_delegator :@builder, :initial
      def_delegator :@builder, :final
      def_delegator :@builder, :session
    end

    class InitialContext < Context
      def_delegator :@builder, :plugin_set, :plugin
    end

    class FinalContext < Context
      def_delegator :@builder, :plugin_get, :plugin
    end

    class SessionContext < Context
      def_delegator '@builder.session_conf', :default_key
      def_delegator '@builder.session_conf', :default_domain
      def_delegator '@builder.session_conf', :default_path
      def_delegator '@builder.session_conf', :id_max_length
      def_delegator '@builder.session_conf', :time_to_live
      def_delegator '@builder.session_conf', :auto_expire
      def_delegator '@builder.session_conf', :digest
      def_delegator '@builder.session_conf', :store
    end

    def context_binding(_)
      _.instance_eval{ binding }
    end
    private :context_binding

    def eval_conf(expr, *options)
      context = TopLevelContext.new(self)
      eval(expr, context_binding(context), *options)
      nil
    end

    def load_conf
      eval_conf(IO.read(@conf_path), @conf_path)
      nil
    end

    def build
      @dispatcher = Dispatcher.new(@url_map)
      @renderer = ViewRenderer.new(@view_dir)
      @session_man = SessionManager.new(@session_conf.options)
      @plugin_maker.setup

      cache = {}
      c_lock = Mutex.new

      @app = proc{|env|
        req = Rack::Request.new(env)
        res = Rack::Response.new
        page_type, gluon_path_info = @dispatcher.look_up(req.path_info)
        if (page_type) then
          @session_man.transaction(req, res) {|session|
            req.env['gluon.version'] = VERSION
            req.env['gluon.curr_page'] = page_type
            req.env['gluon.path_info'] = gluon_path_info
            plugin = @plugin_maker.new_plugin
            rs_context = RequestResponseContext.new(req, res, session, @dispatcher, plugin)
            begin
              page = page_type.new
              action = Action.new(page, rs_context).setup
              po = PresentationObject.new(page, rs_context, @renderer, action)
              erb_context = ERBContext.new(po, rs_context)
              page_type = RequestResponseContext.switch_from{
                c_key = [ page_type, req.path_info ]
                if (c_entry = c_lock.synchronize{ cache[c_key] }) then
                  cache_result = nil
                  if (c_entry[:lock].synchronize{
                        cache_result = c_entry[:result] # save in lock
                        action.modified? c_entry[:cache_tag]
                      })
                  then
                    # update cache
                    result = action.apply{ @renderer.render(erb_context) }
                    c_entry[:lock].synchronize{
                      c_entry[:cache_tag] = rs_context.cache_tag
                      c_entry[:result] = result
                    }
                    res.write(result)
                  else
                    # use cache
                    res.write(cache_result)
                  end
                else
                  result = action.apply{ @renderer.render(erb_context) }
                  if (@page_cache && rs_context.cache_tag) then
                    # create cache
                    c_lock.synchronize{
                      c_entry = cache[c_key] || { :lock => Mutex.new }
                      c_entry[:lock].synchronize{
                        c_entry[:cache_tag] = rs_context.cache_tag
                        c_entry[:result] = result
                      }
                      cache[c_key] = c_entry
                    }
                  end
                  res.write(result)
                end
              }
            end while (page_type)
          }
          res.finish
        else
          [ 404, { "Content-Type" => "text/plain" }, [ "404 Not Found: #{req.env['REQUEST_URI']}" ] ]
        end
      }

      @app = Rack::ShowExceptions.new(@app)
      if (@access_log) then
        @logger = File.open(@access_log, 'a')
        @logger.binmode
        @logger.sync = true
        @app = Rack::CommonLogger.new(@app, @logger)
      else
        @app = Rack::CommonLogger.new(@app)
      end

      { :port => @port }
    end

    def run(handler, *opts)
      begin
        handler.run(@app, *opts)
      ensure
        @logger.close if @logger
        @session_man.shutdown
        FinalContext.new(self).instance_eval(&@finalizer)
      end
      nil
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

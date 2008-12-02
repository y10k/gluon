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
require 'gluon/application'
require 'gluon/backend'
require 'gluon/errmap'
require 'gluon/nolog'
require 'gluon/plugin'
require 'gluon/renderer'
require 'gluon/rs'
require 'gluon/urlmap'
require 'gluon/version'
require 'logger'
require 'rack'
require 'thread'

module Gluon
  # = auto-reload decorator for Rack application
  class AutoReloader
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(app)
      @app = app
      @lock = Mutex.new
      @loaded = {}
    end

    def search_library(name)
      for lib_dir in $:
        lib_path = File.join(lib_dir, name)
        next unless (File.file? lib_path)
        return lib_path
      end
    end
    private :search_library

    def reload
      for lib_name in $"
        next unless (lib_name =~ /\.rb$/)
        lib_path = search_library(lib_name) or raise "not found a loaded library: #{lib_name}"
        mtime = File.stat(lib_path).mtime
        if (@loaded.key? lib_path) then
          if (@loaded[lib_path] != mtime) then
            load(lib_name)
          end
        end
        @loaded[lib_path] = mtime
      end
      nil
    end
    private :reload

    def call(env)
      @lock.synchronize{
        reload
        @app.call(env)
      }
    end
  end

  class Builder
    # for ident(1)
    CVS_ID = '$Id$'

    def self.require_path(lib_dir)
      unless ($:.include? lib_dir) then
        $: << lib_dir
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

    def initialize(options={})
      if (options.key? :lib_dir) then
        Builder.require_path(options[:lib_dir])
      end
      @base_dir = options[:base_dir]
      @view_dir = options[:view_dir]
      @conf_path = options[:conf_path]
      @session_conf = SessionConfig.new
      @log_file = File.join(@base_dir, 'gluon.log')
      @log_level = Logger::INFO
      @access_log = File.join(@base_dir, 'access.log')
      @port = 9202
      @page_cache = false
      @auto_reload = false
      @default_handler = nil
      @error_map = ErrorMap.new
      @url_map = URLMap.new
      @plugin_maker = PluginMaker.new
      @backend_service_man = BackendServiceManager.new
      @finalizer = proc{}
      @rack_builder = Rack::Builder.new
    end

    attr_reader :base_dir
    attr_reader :view_dir
    attr_reader :conf_path
    attr_reader :session_conf

    attr_accessor :log_file
    attr_accessor :log_level

    attr_accessor :access_log
    attr_accessor :port
    attr_accessor :page_cache
    attr_accessor :auto_reload

    attr_accessor :default_handler

    def error_handler(exception_type, page_type)
      @error_map.error_handler(exception_type, page_type)
      nil
    end

    def mount(page_type, location, *args)
      @url_map.mount(page_type, location, *args)
      nil
    end

    def find(path)
      (entry = @url_map.lookup(path)) && entry[0]
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

    def backend_service(adaptor=nil)
      if (adaptor) then
        if (block_given?) then
          raise 'no need for block'
        end
        @backend_service_man.register(adaptor)
      else
        @backend_service_man.register(yield)
      end

      nil
    end

    def rackup_use(middleware, *args, &block)
      @rack_builder.use(middleware, *args, &block)
      nil
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
      def_delegator :@builder, :log_file=, :log_file
      def_delegator :@builder, :log_level=, :log_level
      def_delegator :@builder, :access_log=, :access_log
      def_delegator :@builder, :port=, :port
      def_delegator :@builder, :page_cache=, :page_cache
      def_delegator :@builder, :auto_reload=, :auto_reload
      def_delegator :@builder, :default_handler=, :default_handler
      def_delegator :@builder, :error_handler
      def_delegator :@builder, :mount
      def_delegator :@builder, :initial
      def_delegator :@builder, :final
      def_delegator :@builder, :session
      def_delegator :@builder, :backend_service
      def_delegator :@builder, :rackup
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

    class RackupContext < Context
      def_delegator :@builder, :rackup_use, :use
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
      nil
    end

    def rackup(&block)
      RackupContext.new(self).instance_eval(&block)
      nil
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
      if (@log_file) then
        @logger = Logger.new(@log_file, 1)
        @logger.level = @log_level
      else
        @logger = NoLogger.instance
      end
      @logger.info("new logger: loggin level -> #{@logger.level}")

      @logger.info("#{self}.build() - start")

      begin
        @logger.info("#{@error_map}.setup()")
        @error_map.setup
        if (@logger.debug?) then
          for exception_type, page_type in @error_map
            @logger.debug("Error mapping: #{exception_type} -> #{page_type}")
          end
        end

        @logger.info("#{@url_map}.setup()")
        @url_map.setup
        if (@logger.debug?) then
          for location, path_filter, page_type in @url_map
            @logger.debug("URL mapping: #{location};#{path_filter} -> #{page_type}")
          end
        end

        @logger.info("new #{ViewRenderer} -> #{@view_dir}")
        @renderer = ViewRenderer.new(@view_dir)

        @logger.info("new #{SessionManager}")
        if (@logger.debug?) then
          for key, value in @session_conf.options
            @logger.debug("#{SessionManager} option: #{key} -> #{value}")
          end
        end
        @session_man = SessionManager.new(@session_conf.options)

        @logger.info("#{@plugin_maker}.setup()")
        @plugin_maker.setup
        
        @logger.info("#{@backend_service_man}.apply_around_hook()")
        @backend_service_man.apply_around_hook{
          @logger.info("#{@backend_service_man}.setup()")
          @backend_service_man.setup

          @rack_builder.use(Rack::ShowExceptions)

          if (@access_log) then
            @logger.debug("open access log -> #{@access_log}") if @logger.debug?
            @access_logger = File.open(@access_log, 'a')
            @access_logger.binmode
            @access_logger.sync = true
            @rack_builder.use(Rack::CommonLogger, @access_logger)
          else
            @rack_builder.use(Rack::CommonLogger)
          end

          @logger.debug("auto_reload -> #{@auto_reload}") if @logger.debug?
          if (@auto_reload) then
            @rack_builder.use(AutoReloader)
          end

          @logger.info("new #{Application}")
          app = Application.new
          app.logger = @logger
          app.url_map = @url_map
          app.error_map = @error_map
          app.renderer = @renderer
          app.session_man = @session_man
          app.plugin_maker = @plugin_maker
          app.backend_service_man = @backend_service_man
          @logger.debug("#{app}.page_cache = #{@page_cache}") if @logger.debug?
          app.page_cache = @page_cache
          app.default_handler = @default_handler
          @logger.debug("#{app}.default_handler = #{@default_handler}") if @logger.debug?
          @rack_builder.run(app)
          @app = @rack_builder.to_app

          @logger.info("#{self}.build() - end")

          yield
        }
      ensure
        if (@access_logger) then
          @logger.info("close access log")
          begin
            @access_logger.close if @access_logger
          rescue
            @logger.error('failed to close access log')
            @logger.error($!)
          end
        end

        if (@backend_service_man) then
          @logger.info("#{@backend_service_man}.shutdown()")
          begin
            @backend_service_man.shutdown
          rescue
            @logger.error("failed to shutdown `#{@backend_service_man}'")
            @logger.error($!)
          end
        end

        @logger.info("evaluate final context")
        begin
          FinalContext.new(self).instance_eval(&@finalizer)
        rescue
          @logger.error('failed to evaluate final context')
          @logger.error($!)
        end

        if (@session_man) then
          @logger.info("#{@session_man}.shutdown()")
          begin
            @session_man.shutdown
          rescue
            @logger.error("failed to shutdown `#{@session_man}'")
            @logger.error($!)
          end
        end

        @logger.info('close logger')
        @logger.close
      end

      nil
    end

    def run(handler, options={})
      @logger.info("#{self}.run() - start")
      if (@logger.debug?) then
        @logger.debug("#{self}.run(): handler -> #{handler}")
        for key, value in options
          @logger.debug("#{self}.run() option: #{key} -> #{value}")
        end
      end
      begin
        handler.run(@app, options)
      ensure
        @logger.info("#{self}.run() - end")
      end
      nil
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

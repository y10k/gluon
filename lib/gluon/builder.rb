# -*- coding: utf-8 -*-
# = gluon - component based web application framework
# == license
#   :include:../LICENSE
#

require 'forwardable'
require 'gluon/application'
require 'gluon/backend'
require 'gluon/cmap'
require 'gluon/rs'
require 'gluon/template'
require 'gluon/version'
require 'logger'
require 'rack'

module Gluon
  class Builder
    def self.require_path(lib_dir)
      unless ($:.include? lib_dir) then
        $: << lib_dir
      end
      nil
    end

    def initialize(base_dir, options={})
      @base_dir = base_dir
      @lib_dir = options[:lib_dir] || File.join(base_dir, 'lib')
      @view_dir = options[:view_dir] || File.join(base_dir, 'view')
      @config_rb = options[:config_rb] || File.join(base_dir, 'config.rb')
      @logger = NoLogger.instance
      @cmap = ClassMap.new
      @template_engine = TemplateEngine.new(@view_dir)
      @builder = Rack::Builder.new
      @builder.use(Root)
      @service_man = BackendServiceManager.new
    end

    def enable_local_library
      Builder.require_path(@lib_dir)
    end

    attr_reader :base_dir
    attr_reader :lib_dir
    attr_reader :view_dir
    attr_reader :config_rb

    def use(middleware, *args, &block)
      @builder.use(middleware, *args, &block)
      nil
    end

    class MapEntry
      def initialize(logger, cmap, app, location)
        @logger = logger
        @cmap = cmap
        @app = app
        @location = location
        @builder = Rack::Builder.new
      end

      def use(middleware, *args, &block)
        @builder.use(middleware, *args, &block)
        nil
      end

      def run(app)
        @app.run(app)
        nil
      end

      def mount(page_type, *init_args)
        @cmap.mount(page_type, @location)
        @app.mount(page_type, *init_args)
        nil
      end

      def _to_app
        @builder.run(@app)
        @builder.to_app
      end
    end

    def map(location)
      app = Application.new(@logger, @cmap, @template_engine, @service_man)
      entry = MapEntry.new(@logger, @cmap, app, location)
      yield(entry)
      @builder.map(location) { run(entry._to_app) }
      nil
    end

    class ServiceEntry
      def initialize(logger, service_man, name)
        @logger = logger
        @service_man = service_man
        @name = name
      end

      def start
        @value = yield
        nil
      end

      def stop(&block)
        @finalizer = block
        nil
      end

      def _add_service
        @service_man.add(@name, @value, &@finalizer)
        nil
      end
    end

    def backend_service(name)
      entry = ServiceEntry.new(@logger, @service_man, name)
      yield(entry)
      entry._add_service
      nil
    end

    class DSL
      extend Forwardable

      def initialize(builder)
        @builder = builder
      end

      def_delegator :@builder, :base_dir
      def_delegator :@builder, :lib_dir
      def_delegator :@builder, :view_dir
      def_delegator :@builder, :config_rb
      def_delegator :@builder, :use
      def_delegator :@builder, :map
      def_delegator :@builder, :backend_service
    end

    def dsl_binding
      _ = DSL.new(self)
      _.instance_eval{ binding }
    end
    private :dsl_binding

    def eval_conf(expr, *args)
      r = eval(expr, dsl_binding, *args)
      @service_man.setup
      r                         # eval-result for debug.
    end

    def load_conf
      eval_conf(IO.read(@config_rb), @config_rb)
      nil
    end

    def to_app
      @builder.to_app
    end

    def shutdown
      @service_man.shutdown
      nil
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

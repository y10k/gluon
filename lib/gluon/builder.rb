# -*- coding: utf-8 -*-

require 'forwardable'
require 'gluon/application'
require 'gluon/cmap'
require 'gluon/rs'
require 'gluon/template'
require 'gluon/version'
require 'logger'
require 'rack'

module Gluon
  BUILDER_ATTRS = Struct.new(:base_dir, :lib_dir, :view_dir).new

  class << self
    def base_dir
      BUILDER_ATTRS.base_dir or raise "not initialized `Gluon.base_dir'"
    end

    def lib_dir
      BUILDER_ATTRS.lib_dir or raise "not initialized `Gluon.lib_dir'"
    end

    def view_dir
      BUILDER_ATTRS.view_dir or raise "not initialized `Gluon.view_dir'"
    end
  end

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
      @middleware_setup = proc{|builder, logger, options| builder }
      @mount_tab = {}
      @mod_config = {}
      @service = {}
    end

    def enable_local_library
      Builder.require_path(@lib_dir)
    end

    attr_reader :base_dir
    attr_reader :lib_dir
    attr_reader :view_dir
    attr_reader :config_rb
    attr_writer :logger

    def use(middleware, *args, &block)
      parent = @middleware_setup
      @middleware_setup = proc{|builder, logger, options|
        new_builder = parent.call(builder, logger, options)
        logger.info "use #{middleware}"
        new_builder.use(middleware, *args, &block)
        new_builder
      }
      nil
    end

    class MapEntry
      def initialize
        @builder = Rack::Builder.new
        @app_builder = proc{|location, logger, options|
          Application.new(logger,
                          options[:cmap],
                          options[:template_engine],
                          options[:config],
                          options[:service])
        }
      end

      def use(middleware, *args, &block)
        parent = @app_builder
        @app_builder = proc{|location, logger, options|
          app = parent.call(location, logger, options)
          logger.info "use #{middleware} for location: #{location}"
          @builder.use(middleware, *args, &block)
          app
        }
      end

      def run(rack_app)
        parent = @app_builder
        @app_builder = proc{|location, logger, options|
          app = parent.call(location, logger, options)
          logger.info "run #{rack_app} for location: #{location}"
          app.run rack_app
        }
        nil
      end

      def mount(page_type)
        parent = @app_builder
        @app_builder = proc{|location, logger, options|
          app = parent.call(location, logger, options)
          logger.info "mount #{page_type} at location: #{location}"
          options[:cmap].mount(page_type, location)
          app.mount(page_type)
        }
        nil
      end

      def _to_builder
        proc{|location, logger, options|
          @builder.run @app_builder.call(location, logger, options)
          @builder.to_app
        }
      end
    end

    def map(location)
      entry = MapEntry.new
      yield(entry)
      @mount_tab[location] = entry._to_builder
      nil
    end

    def config(mod)
      conf = mod.create_config
      yield(conf)
      @mod_config[mod] = conf.freeze
      nil
    end

    def service_create(klass, &block)
      entry = {
        :object => nil,
        :create => proc{|logger, options|
          logger.info "service start: #{klass}"
          obj = block.call(klass)
          entry[:object] = obj
          options[:service][klass] = obj
          logger.info "create service object: #{entry[:object]}"
          nil
        },
        :destroy => nil
      }

      @service[klass] = entry
      service_destroy(klass) {|obj|
        # nothing to do.
      }

      nil
    end

    def service_destroy(klass, &block)
      entry = @service[klass] or raise "not initialized service of `#{klass}'."
      entry[:destroy] = proc{|logger|
        entry[:object] or raise "not created service of `#{klass}'."
        logger.info "destroy service object: #{entry[:object]}"
        block.call(entry[:object])
        logger.info "service stop: #{klass}"
        nil
      }

      nil
    end

    class ServiceEntry
      def initialize(klass, parent)
        @class = klass
        @parent = parent
      end

      def create(&block)
        @parent.service_create(@class, &block)
      end

      def destroy(&block)
        @parent.service_destroy(@class, &block)
      end
    end

    def service(klass)
      service_create(klass) {|c| c.new }
      if (block_given?) then
        entry = ServiceEntry.new(klass, self)
        yield(entry)
      end
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
      def_delegator :@builder, :logger=, :logger
      def_delegator :@builder, :use
      def_delegator :@builder, :map
      def_delegator :@builder, :config
      def_delegator :@builder, :service
    end

    def dsl_binding
      _ = DSL.new(self)
      _.instance_eval{ binding }
    end
    private :dsl_binding

    def eval_conf(expr, *args)
      eval(expr, dsl_binding, *args) # return eval-result for debug.
    end

    def load_conf
      eval_conf(IO.read(@config_rb), @config_rb)
      nil
    end

    def to_app
      BUILDER_ATTRS.base_dir = @base_dir
      BUILDER_ATTRS.lib_dir = @lib_dir
      BUILDER_ATTRS.view_dir = @view_dir

      options = {
        :cmap => ClassMap.new,
        :template_engine => TemplateEngine.new(@view_dir),
        :config => @mod_config,
        :service => {}
      }

      @logger.info 'gluon start.'
      for mod, conf in @mod_config
        @logger.info("config #{mod}: #{conf}")
      end
      @service.each_value do |entry|
        entry[:create].call(@logger, options)
      end
      builder = Rack::Builder.new
      builder.use Root, @logger
      @middleware_setup.call(builder, @logger, options)
      for location, app_builder in @mount_tab
        logger = @logger
        builder.map location do
          run app_builder.call(location, logger, options)
        end
      end

      builder.to_app
    end

    def shutdown
      last_error = nil
      @service.each_value do |entry|
        begin
          entry[:destroy].call(@logger)
        rescue
          last_error = $!
          @logger.error($!)
        end
      end
      raise if last_error

      @logger.info 'gluon stop.'
      @logger.close
      nil
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

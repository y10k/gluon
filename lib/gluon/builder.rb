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
    extend Forwardable

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
      @middleware_setup = proc{|builder| builder }
      @mount_tab = {}
      @svc_tab = {}
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
      parent = @middleware_setup
      @middleware_setup = proc{|builder, options|
        new_builder = parent.call(builder, options)
        new_builder.use(middleware, *args, &block)
        new_builder
      }
      nil
    end

    class MapEntry
      extend Forwardable

      def initialize
        @builder = Rack::Builder.new
        @app_builder = proc{|location, options|
          Application.new(options[:logger],
                          options[:cmap],
                          options[:template_engine],
                          options[:service_man])
        }
      end

      def_delegator :@builder, :use

      def run(rack_app)
        parent = @app_builder
        @app_builder = proc{|location, options|
          parent.call(location, options).run rack_app
        }
        nil
      end

      def mount(page_type)
        parent = @app_builder
        @app_builder = proc{|location, options|
          options[:cmap].mount(page_type, location)
          parent.call(location, options).mount(page_type)
        }
        nil
      end

      def _to_builder
        proc{|location, options|
          @builder.run @app_builder.call(location, options)
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

    class ServiceEntry
      def start(&block)
        @initializer = block
        nil
      end

      def stop(&block)
        @finalizer = block
        nil
      end

      def _to_setup
        proc{|service_man, service_name, options|
          service_man.add(service_name, @initializer.call, &@finalizer)
        }
      end
    end

    def backend_service(name)
      entry = ServiceEntry.new
      yield(entry)
      @svc_tab[name] = entry._to_setup
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
      eval(expr, dsl_binding, *args) # return eval-result for debug.
    end

    def load_conf
      eval_conf(IO.read(@config_rb), @config_rb)
      nil
    end

    def to_app
      options = {
        :logger => NoLogger.instance,
        :cmap => ClassMap.new,
        :template_engine => TemplateEngine.new(@view_dir),
        :service_man => @service_man
      }

      for svc_name, svc_setup in @svc_tab
        svc_setup.call(@service_man, svc_name, options)
      end
      @service_man.setup

      builder = Rack::Builder.new
      builder.use Root
      @middleware_setup.call(builder, options)
      for location, app_builder in @mount_tab
        builder.map location do
          run app_builder.call(location, options)
        end
      end

      builder.to_app
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

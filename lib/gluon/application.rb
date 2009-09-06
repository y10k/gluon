# -*- coding: utf-8 -*-
# = gluon - component based web application framework
# == license
#   :include:../LICENSE
#

require 'gluon/controller'
require 'gluon/po'
require 'gluon/rs'
require 'rack'

module Gluon
  class Root
    def initialize(app, logger)
      @app = app
      @logger = logger
    end

    # for debug
    def inner
      @app
    end

    def call(env)
      begin
        env[:gluon_root_script_name] = env['SCRIPT_NAME']
        @app.call(env)
      rescue
        @logger.error($!)
        raise
      end
    end
  end

  # = application for Rack
  class Application
    def initialize(logger, cmap, template_engine, service_man)
      @logger = logger
      @cmap = cmap
      @template_engine = template_engine
      @service_man = service_man
      @page_list = []
      @default_app = nil
    end

    def mount(page_type)
      @page_list.push [
        Controller.find_path_filter(page_type) || %r"^/?$",
        page_type
      ]

      self                      # for Gluon::Builder::MapEntry
    end

    def run(app)
      @default_app = app
      self                      # for Gluon::Builder::MapEntry
    end

    def find_page(path_info)
      for path_filter, page_type in @page_list
        if (path_info =~ path_filter) then
          path_args = $~.to_a
          path_args.shift
          return page_type, path_args
        end
      end

      nil
    end

    def call(env)
      # renew request object to refresh SCRIPT_NAME and PATH_INFO
      # generated by Rack::URLMap.
      env.delete('rack.request')

      r = RequestResponseContext.new(Rack::Request.new(env), Rack::Response.new)
      r.logger = @logger
      r.cmap = @cmap
      r.backend_service = @service_man.new_services

      @logger.debug "script_name(#{r.equest.script_name.inspect}) + path_info(#{r.equest.path_info.inspect})"
      page_type, r.path_args = find_page(r.equest.path_info)
      unless (page_type) then
        if (@default_app) then
          @logger.debug "run default application: #{@default_app}" if @logger.debug?
          return @default_app.call(env)
        else
          raise "not found an application for `#{r.equest.url}'"
        end
      end
      @logger.debug "page_type(#{page_type}) + path_args(#{r.path_args.map{|s| s.inspect }.join(', ')})" if @logger.debug?

      r.esponse['Content-Type'] = "text/html; charset=#{page_type.page_encoding}"
      c = page_type.new
      r.controller = c
      c.r = r
      po = PresentationObject.new(c, r, @template_engine)
      page_result = nil

      if (@logger.debug?) then
        @logger.debug "controller: #{c}"
        @logger.debug "#{c}: page_around start."
      end
      c.page_around{
        @logger.debug "#{c}: page_start." if @logger.debug?
        c.page_start
        begin
          @logger.debug "#{c}: page_validation_preprocess." if @logger.debug?
          c.page_validation_preprocess
          @logger.debug "#{c}: set form parameters." if @logger.debug?
          Controller.set_form_params(c, r.equest.params)
          @logger.debug "#{c}: page_request." if @logger.debug?
          c.page_request(*r.path_args)
          if (action = Controller.find_first_action(c, r.equest.params)) then
            @logger.debug "#{c}: validation is #{r.validation.inspect}." if @logger.debug?
            if (r.validation) then
              @logger.debug "#{c}: call action: #{action.name}" if @logger.debug?
              action.call
            else
              @logger.debug "#{c}: not validated action: #{action.name}" if @logger.debug?
              if (r.validation.nil?) then
                raise "not validated page of `#{c}'"
              end
            end
          else
            @logger.debug "#{c}: no action." if @logger.debug?
          end
          page_result = c.class.process_view(po)
        ensure
          @logger.debug "#{c}: page_end." if @logger.debug?
          c.page_end
        end
      }
      @logger.debug "#{c}: page_around end." if @logger.debug?

      if (@logger.debug?) then
        @logger.debug "#{c}: content-length: #{page_result.bytesize}"
        @logger.debug "#{c}: content-type: #{r.esponse['Content-Type']}"
      end

      r.esponse.write(page_result)
      r.esponse.finish
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

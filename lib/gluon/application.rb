# -*- coding: utf-8 -*-

require 'gluon/controller'
require 'gluon/po'
require 'gluon/rs'
require 'rack'

module Gluon
  # 1. save <tt>SCRIPT_NAME</tt> for Gluon::RequestResponseContext#oot_script_name.
  # 2. error logging of framework.
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
      ensure
        @logger.error($!) if $!
      end
    end
  end

  # = application for Rack
  class Application
    def initialize(logger, cmap, template_engine, config, service)
      @logger = logger
      @cmap = cmap
      @template_engine = template_engine
      @config = config
      @service = service
      @page_list = []
      @default_app = nil
    end

    def mount(page_type)
      @page_list.push [
        Controller.find_path_match_pattern(page_type) || %r"^/?$",
        page_type
      ]

      self                      # for Gluon::Builder::MapEntry
    end

    def run(app)
      @default_app = app
      self                      # for Gluon::Builder::MapEntry
    end

    def find_page(path_info)
      for path_match_pattern, page_type in @page_list
        if (path_info =~ path_match_pattern) then
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
      r.config = @config
      r.service = @service

      @logger.debug "script_name(#{r.equest.script_name.inspect}) + path_info(#{r.equest.path_info.inspect})" if @logger.debug?
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

      page_result = nil
      c = page_type.new
      begin
        c = catch(:GLUON_CONTROLLER_SWITCH_TO) {
          page_result = process_controller(c, r)
          nil
        }
      end while (c)

      r.esponse.write(page_result) if (page_result.bytesize > 0)
      r.esponse.finish
    end

    def self.controller_switch_to(c)
      throw(:GLUON_CONTROLLER_SWITCH_TO, c)
    end

    def ascii_8bit?(penc)
      case (penc)
      when String, Symbol
        penc = Encoding.find(penc)
      end
      penc == Encoding::ASCII_8BIT
    end
    private :ascii_8bit?

    def process_controller(c, r)
      if (ascii_8bit? c.class.page_encoding) then
        r.esponse['Content-Type'] = 'application/octet-stream'
      else
        r.esponse['Content-Type'] = "text/html; charset=#{c.class.page_encoding}"
      end
      r.controller = c
      c.r = r
      po = PresentationObject.new(c, r, @template_engine)
      page_result = nil

      if (@logger.debug?) then
        @logger.debug "controller: #{c}"
        @logger.debug "#{c}: __addon_around__ start."
      end

      c.__addon_around__{
        @logger.debug "#{c}: __addon_init__." if @logger.debug?
        c.__addon_init__
        begin
          @logger.debug "#{c}: page_around start." if @logger.debug?
          c.page_around{
            @logger.debug "#{c}: page_start(#{r.path_args.map{|s| s.inspect }.join(', ')})" if @logger.debug?
            c.page_start(*r.path_args)
            begin
              @logger.debug "#{c}: page_validation_preprocess." if @logger.debug?
              c.page_validation_preprocess
              @logger.debug "#{c}: set form parameters." if @logger.debug?
              Controller.set_form_params(c, r.equest.params)
              @logger.debug "#{c}: page_request" if @logger.debug?
              c.page_request
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
              @logger.debug "#{c}: process_view." if @logger.debug?
              page_result = c.class.process_view(po)
            ensure
              @logger.debug "#{c}: page_end." if @logger.debug?
              c.page_end
            end
          }
          @logger.debug "#{c}: page_around end." if @logger.debug?
        ensure
          @logger.debug "#{c}: __addon_final__." if @logger.debug?
          c.__addon_final__
        end
      }

      if (@logger.debug?) then
        @logger.debug "#{c}: __addon_around__ end."
        @logger.debug "#{c}: content-length: #{page_result.bytesize}"
        @logger.debug "#{c}: content-type: #{r.esponse['Content-Type']}"
      end

      page_result
    end
    private :process_controller
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

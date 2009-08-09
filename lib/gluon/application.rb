# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

require 'gluon/controller'
require 'gluon/po'
require 'gluon/rs'
require 'rack'

module Gluon
  class Root
    def initialize(app)
      @app = app
    end

    def call(env)
      env[:gluon_root_script_name] = env['SCRIPT_NAME']
      @app.call(env)
    end
  end

  # = application for Rack
  class Application
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(logger, cmap, template_engine)
      @logger = logger
      @cmap = cmap
      @template_engine = template_engine
      @page_list = []
      @default_app = nil
    end

    def mount(page_type, *init_args)
      @page_list.push [
        Controller.find_path_filter(page_type) || %r"^/?$",
        page_type,
        init_args
      ]
      nil
    end

    def run(app)
      @default_app = app
      nil
    end

    def find_page(path_info)
      for path_filter, page_type, init_args in @page_list
        if (path_info =~ path_filter) then
          path_args = $~.to_a
          path_args.shift
          return page_type, init_args, path_args
        end
      end

      nil
    end

    def call(env)
      r = RequestResponseContext.new(Rack::Request.new(env), Rack::Response.new)
      r.logger = @logger
      r.cmap = @cmap

      page_type, init_args, path_args = find_page(r.equest.path_info)
      unless (page_type) then
        if (@default_app) then
          return @default_app.call(env)
        else
          raise "not found an application for `#{r.equest.url}'"
        end
      end

      r.esponse['Content-Type'] = "text/html; charset=#{page_type.page_encoding}"
      c = page_type.new(*init_args)
      r.controller = c
      c.r = r
      po = PresentationObject.new(c, r, @template_engine)
      page_result = nil

      c.page_around{
        c.page_start
        begin
          Controller.set_form_params(c, r.equest)
          c.page_request(*path_args)
          Controller.apply_first_action(c, r.equest)
          page_result = c.class.process_view(po)
        ensure
          c.page_end
        end
      }

      r.esponse.write(page_result)
      r.esponse.finish
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

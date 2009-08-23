# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

require 'singleton'

module Gluon
  # = fake logger
  class NoLogger
    include Singleton

    def debug?
      false
    end

    def debug(messg)
    end

    def info(messg)
    end

    def warn(messg)
    end

    def error(messg)
    end

    def fatal(messg)
    end

    def close
    end
  end

  class RequestResponseContext
    # for idnet(1)
    CVS_ID = '$Id$'

    def initialize(request, response)
      @req = request
      @res = response
      @req.env[:gluon_logger] = NoLogger.instance
    end

    # alias for self
    def r
      self
    end
    private :r

    # usage: r.equest, @r.equest
    def equest
      @req
    end

    # usage: r.esponse, @r.esponse
    def esponse
      @res
    end

    # usage: r.oot_script_name, @r.oot_script_name
    #
    # request attribute of <tt>:gluon_root_script_name</tt> is set by
    # rack-middleware of Rack::Root.
    #
    def oot_script_name
      @req.env[:gluon_root_script_name]
    end

    def logger
      @req.env[:gluon_logger]
    end

    def logger=(logger)
      @req.env[:gluon_logger] = logger
    end

    def controller
      @req.env[:gluon_controller]
    end

    def controller=(controller)
      @req.env[:gluon_controller] = controller
    end

    def path_args
      @req.env[:gluon_path_args]
    end

    def path_args=(path_args)
      @req.env[:gluon_path_args] = path_args
    end

    def cmap=(cmap)
      @req.env[:gluon_class_map] = cmap
    end

    def class2path(page_type, *path_args)
      r.oot_script_name + @req.env[:gluon_class_map].class2path(page_type, *path_args)
    end

    def location(path, status=302)
      @logger.debug("#{self}.location() -> #{path}") if @logger.debug?
      @res['Location'] = path
      @res.status = status
      self
    end

    def redirect_to(page_type, *path_args)
      location(class2path(page_type, *path_args))
    end

    def backend_service
      @req.env[:gluon_backend_service]
    end

    def backend_service=(backend_service)
      @req.env[:gluon_backend_service] = backend_service
    end

    alias svc backend_service
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

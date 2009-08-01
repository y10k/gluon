# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

require 'gluon/nolog'

module Gluon
  class RequestResponseContext
    # for idnet(1)
    CVS_ID = '$Id$'

    def initialize(request, response)
      @req = request
      @res = response
      @logger = NoLogger.instance
    end

    # usage: @r.equest
    def equest
      @req
    end

    # usage: @r.esponse
    def esponse
      @res
    end

    attr_accessor :logger
    attr_writer :cmap

    def script_name
      @req.env[:gluon_script_name]
    end

    def class2path(page_type, *path_args)
      script_name + @cmap.class2path(page_type, *path_args)
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

    attr_accessor :backend_service
    alias svc backend_service
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

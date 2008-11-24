# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../../LICENSE
#

require 'gluon/controller'
require 'gluon/erbview'

module Gluon
  module Web
    class NotFoundErrorPage
      include Controller

      # for ident(1)
      CVS_ID = '$Id$'

      def page_start(*args)
        @c.res.status = 404
        @c.res['Content-Type'] = 'text/html'
        @uri = @c.req.env['REQUEST_URI']
      end

      def page_get
      end

      def page_post
      end

      attr_reader :uri

      def page_render(po)
        template = File.join(File.dirname(__FILE__), '404.rhtml')
        @c.view_render(ERBView, template, po)
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

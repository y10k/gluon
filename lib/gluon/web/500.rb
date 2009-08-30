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
    class InternalServerErrorPage
      include Controller

      def initialize(exception)
        @exception = exception
      end

      def page_start(*args)
        @c.res.status = 500
        @c.res['Content-Type'] = 'text/html'
      end

      def page_get
      end

      def page_post
      end

      attr_reader :exception

      def page_render(po)
        template = File.join(File.dirname(__FILE__), '500.rhtml')
        @c.view_render(ERBView, template, po)
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

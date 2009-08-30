# -*- coding: utf-8 -*-
# = gluon - component based web application framework
# == license
#   :include:../LICENSE
#

module Gluon
  # = namespace for web components
  module Web
    autoload :ErrorMessages, 'gluon/web/error'
    autoload :InternalServerErrorPage, 'gluon/web/500'
    autoload :NotFoundErrorPage, 'gluon/web/404'
    autoload :OneTimeToken, 'gluon/web/token'
    autoload :Table, 'gluon/web/table'
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

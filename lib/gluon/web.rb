# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

module Gluon
  # = namespace for web components
  module Web
    # for ident(1)
    CVS_ID = '$Id$'

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

# = gluon - simple web application framework
#
# == license
# see <tt>gluon.rb</tt> or <tt>LICENSE</tt> file.
#

module Gluon
  # = namespace for web components
  module Web
    # for ident(1)
    CVS_ID = '$Id$'

    autoload :ErrorMessages, 'gluon/web/error'
    autoload :OneTimeToken, 'gluon/web/token'
    autoload :Table, 'gluon/web/table'
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

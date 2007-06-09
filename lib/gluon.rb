# gluon - simple web application framework

module Gluon
  # for ident(1)
  CVS_ID = '$Id$'

  autoload :Action, 'gluon/action'
  autoload :Builder, 'gluon/builder'
  autoload :Dispatcher, 'gluon/dispatcher'
  autoload :ERBContext, 'gluon/po'
  autoload :PresentationObject, 'gluon/po'
  autoload :Setup, 'gluon/setup'
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

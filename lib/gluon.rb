# gluon - simple web application framework

require 'gluon/version'

module Gluon
  # for ident(1)
  CVS_ID = '$Id$'

  autoload :Action, 'gluon/action'
  autoload :Builder, 'gluon/builder'
  autoload :Dispatcher, 'gluon/dispatcher'
  autoload :ERBContext, 'gluon/po'
  autoload :PresentationObject, 'gluon/po'
  autoload :MemoryStore, 'gluon/rs'
  autoload :SessionManager, 'gluon/rs'
  autoload :SessionHandler, 'gluon/rs'
  autoload :RequestResponseContext, 'gluon/rs'
  autoload :Setup, 'gluon/setup'
  autoload :ViewRenderer, 'gluon/renderer'
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

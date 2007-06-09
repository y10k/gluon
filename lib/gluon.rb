# gluon - simple web application framework

module Gluon
  # for ident(1)
  CVS_ID = '$Id$'

  autoload :Action, 'gluon/action'
  autoload :Builder, 'gluon/builder'
  autoload :Dispatcher, 'gluon/dispatcher'
  autoload :PresentationObject, 'gluon/po'
  autoload :ERBContext, 'gluon/po'
end

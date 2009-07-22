# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:LICENSE
#

require 'gluon/version'
require 'gluon/controller'      # to define gluon controller syntax

# = gluon - simple web application framework
# == license
#
# BSD style license.
#   :include:LICENSE
#
module Gluon
  # for ident(1)
  CVS_ID = '$Id$'

  #autoload :Controller, 'gluon/controller'
  autoload :Action, 'gluon/action'
  autoload :BackendServiceAdaptor, 'gluon/backend'
  autoload :BackendServiceManagerTest, 'gluon/backend'
  autoload :Builder, 'gluon/builder'
  autoload :CKView, 'gluon/ckview'
  autoload :ClassMap, 'gluon/cmap'
  autoload :ERBView, 'gluon/erbview'
  autoload :ErrorMap, 'gluon/errmap'
  autoload :FileStore, 'gluon/fstore'
  autoload :HTMLEmbeddedView, 'gluon/htmlview'
  autoload :MemoryStore, 'gluon/rs'
  autoload :Mock, 'gluon/mock'
  autoload :NoLogger, 'gluon/nolog'
  autoload :PluginMaker, 'gluon/plugin'
  autoload :PresentationObject, 'gluon/po'
  autoload :RequestResponseContext, 'gluon/rs'
  autoload :SessionHandler, 'gluon/rs'
  autoload :SessionManager, 'gluon/rs'
  autoload :Setup, 'gluon/setup'
  autoload :URLMap, 'gluon/urlmap'
  autoload :Validation, 'gluon/validation'
  autoload :Validator, 'gluon/validation'
  autoload :ViewRenderer, 'gluon/renderer'
  autoload :Web, 'gluon/web'
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

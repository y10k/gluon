# -*- coding: utf-8 -*-

require 'gluon/version'

# = gluon - component based web application framework
# == license
#
# BSD style license.
#   :include:../LICENSE
#
module Gluon
  autoload :Application, 'gluon/application'
  autoload :BackendServiceManager, 'gluon/backend'
  autoload :Builder, 'gluon/builder'
  autoload :ClassMap, 'gluon/cmap'
  autoload :Component, 'gluon/controller'
  autoload :Controller, 'gluon/controller'
  autoload :ERBView, 'gluon/erbview'
  autoload :Memoization, 'gluon/memoize'
  autoload :NoLogger, 'gluon/rs'
  autoload :PresentationObject, 'gluon/po'
  autoload :RequestResponseContext, 'gluon/rs'
  autoload :Root, 'gluon/application'
  autoload :Setup, 'gluon/setup'
  autoload :SingleMemoization, 'gluon/memoize'
  autoload :TemplateEngine, 'gluon/template'
  autoload :Validation, 'gluon/validation'
  autoload :Validator, 'gluon/validation'
  autoload :Web, 'gluon/web'

  def self.use_memoization
    Controller.memoize :find_path_filter
    Controller.memoize :find_path_block
    Controller.memoize :find_view_export
    Controller.memoize :find_form_export
    Controller.memoize :find_action_export
    TemplateEngine.class_eval{ memoize :create_engine }
    nil
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

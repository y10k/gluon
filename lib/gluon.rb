# -*- coding: utf-8 -*-

require 'gluon/version'

# = gluon - component based web application framework
# == features
# * need for ruby 1.9 or later. ruby 1.8 is not usable.
# * component based. one component is one class. one page is composed
#   of one or more components.
# * simple view command. view command is one kind of
#   <tt>gluon</tt>. the behavior of <tt>gluon</tt> command is
#   controlled by controller.
# * project local rubygems repository. you can have the rubygems
#   environment only for your project.
#
# == example
# :include:../EXAMPLE
#
# == license
# BSD style license.
#   :include:../LICENSE
#
module Gluon
  autoload :Application, 'gluon/application'
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
    Controller.extend SingleMemoization
    Controller.memoize :find_path_match_pattern
    Controller.memoize :find_path_match_block
    Controller.memoize :find_view_export
    Controller.memoize :find_form_export
    Controller.memoize :find_action_export

    TemplateEngine.class_eval{
      extend Memoization
      memoize :create_engine
    }

    nil
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

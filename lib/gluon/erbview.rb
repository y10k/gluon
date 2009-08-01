# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

require 'erb'
require 'gluon/template'

module Gluon
  module ERBView
    # for ident(1)
    CVS_ID = '$Id$'

    class Engine < TemplateEngine::Skeleton
      alias _block_result block_result
      undef block_result

      def gluon(name, value=nil, &block)
        if (block_given?) then
          @stdout << @po.gluon(name, value) { _block_result(&block) }
        else
          @stdout << @po.gluon(name, value)
        end

        nil
      end
      private :gluon

      def content(&block)
        if (block_given?) then
          @stdout << @po.content{ _block_result(&block) }
        else
          @stdout << @po.content
        end

        nil
      end
      private :content
    end

    def engine_skeleton
      Engine
    end
    module_function :engine_skeleton

    def compile(template)
      ERB.new(template, nil, nil, '@stdout').src
    end
    module_function :compile
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

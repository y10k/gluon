# = gluon - simple web application framework
#
# Author:: $Author$
# Date:: $Date$
# Revision:: $Revision$
#
# == license
#   :include:../LICENSE
#

require 'erb'
require 'thread'
require 'forwardable'

module Gluon
  module ERBView
    class Context
      # for ident(1)
      CVS_ID = '$Id$'

      extend Forwardable
      include ERB::Util

      class << self
        def __init__
          @lock = Mutex.new
          @only_once = true
          nil
        end

        def only_once
          r = nil
          @lock.synchronize{
            if (@only_once) then
              r = yield
              @only_once = false
            end
          }
          r
        end
      end

      def_delegator 'self.class', :only_once

      def initialize(po, rs_context)
        @po = po
        @c = rs_context
        @_erbout = ''
      end

      # for Gluon::PresentationObject#cond
      def neg(operand)
        PresentationObject::NegativeCondition.new(operand)
      end

      alias NOT neg

      attr_reader :po
      attr_reader :c

      def_delegator :@po, :value
      def_delegator :@po, :cond
      def_delegator :@po, :foreach
      def_delegator :@po, :link
      def_delegator :@po, :action
      def_delegator :@po, :frame
      def_delegator :@po, :import
      def_delegator :@po, :text
      def_delegator :@po, :password
      def_delegator :@po, :submit
      def_delegator :@po, :hidden
      def_delegator :@po, :checkbox
      def_delegator :@po, :radio
      def_delegator :@po, :select
      def_delegator :@po, :textarea

      def block_result
        out_save = @_erbout
        @_erbout = ''
        begin
          yield
          result = @_erbout
        ensure
          @_erbout = out_save
        end
        result
      end
      private :block_result

      def link_tag(*args)
        @_erbout << link(*args) {|out|
          out << block_result{ yield }
        }
        nil
      end

      def action_tag(*args)
        @_erbout << action(*args) {|out|
          out << block_result{ yield }
        }
        nil
      end

      def import_tag(*args)
        @_erbout << import(*args) {|out|
          out << block_result{ yield }
        }
        nil
      end
    end

    class Handler
      # for ident(1)
      CVS_ID = '$Id$'

      class << self
        attr_accessor :context
      end

      def initialize(po, rs_context)
        @context = self.class.context.new(po, rs_context)
      end

      def call
        @context.__render__
      end
    end

    # for ident(1)
    CVS_ID = '$Id$'

    SUFFIX = '.erb'

    class << self
      def compile(template_path)
        ERB.new(IO.read(template_path), nil, nil, '@_erbout').src
      end

      def evaluate(compiled_view, filename='__evaluate__')
        context = Class.new(Context)
        context.__init__
        context.class_eval("def __render__\n#{compiled_view}\nend", filename, 0)
        handler = Class.new(Handler)
        handler.context = context
        handler
      end
    end

    def page_render(po)
      @c.view_render(ERBView, @c.default_template(self) + SUFFIX, po)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

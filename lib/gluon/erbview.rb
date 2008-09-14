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

module Gluon
  class ERBContext
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
    def_delegator :@po, :link_uri
    def_delegator :@po, :action
    def_delegator :@po, :frame
    def_delegator :@po, :frame_uri
    def_delegator :@po, :import
    def_delegator :@po, :text
    def_delegator :@po, :password
    def_delegator :@po, :submit
    def_delegator :@po, :hidden
    def_delegator :@po, :checkbox
    def_delegator :@po, :radio
    def_delegator :@po, :select
    def_delegator :@po, :textarea
  end

  module ERBView
    COMPILE_TEMPLATE = <<-'EOF'
__view_context__ = Class.new(%c)
__view_context__.__init__
__view_context__.instance_eval do
  define_method :__render__ do

# begin of `%p'
%s
# end of `%p'

  end
end

__view_type__ = Class.new
__view_type__.instance_eval do
  VIEW_CONTEXT = __view_context__
  define_method :initialize do |*args|
    @view_context = VIEW_CONTEXT.new(*args)
  end
  define_method :call do
    @view_context.__render__
  end
end

__view_type__
    EOF

    SUFFIX = '.rhtml'

    def self.compile(template_path)
      COMPILE_TEMPLATE.gsub(/%./) {|special|
        case (special)
        when '%c'
          ERBContext.to_s
        when '%p'
          template_path
        when '%s'
          ERB.new(IO.read(template_path)).src
        else
          raise "unknown special symbol: #{special}"
        end
      }
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

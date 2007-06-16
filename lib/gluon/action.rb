# action

module Gluon
  class Action
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(page, rs_context, parent_name=nil)
      @parent_name = parent_name
      @page = page
      @c = rs_context
    end

    def funcall(name, *args)
      if (@page.respond_to? name) then
        @page.__send__(name, *args)
      end
    end
    private :funcall

    def funcall_hook(name, *args)
      if (@page.respond_to? name) then
        @page.__send__(name, *args) {
          yield
        }
      else
        yield
      end
    end
    private :funcall_hook

    def apply
      funcall(:c=, @c)
      funcall_hook(:page_hook) {
        funcall(:page_start)
        begin
          yield
        ensure
          funcall(:page_end)
        end
      }
      self
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

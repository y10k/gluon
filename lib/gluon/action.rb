# action

module Gluon
  class Action
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(page, rs_context, parent_name=nil)
      @parent_name = parent_name
      @page = page
      @c = rs_context
      @object_methods = {}
      Object.instance_methods.each do |name|
        @object_methods[name] = true
      end
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

    def call_actions
      if (@parent_name) then
        parent_name = "#{@parent_name}."
      else
        parent_name = ''
      end

      @c.req.params.find_all{|n, v|
        n[0, parent_name.length] == parent_name && n =~ /\(\)$/
      }.map{|n, v|
        n[parent_name.length..-3]
      }.reject{|n, v|
        @object_methods[n] || n.index(?.)
      }.each do |name, value|
        funcall("#{name}_action")
      end
    end
    private :call_actions

    def apply
      funcall(:c=, @c)
      funcall_hook(:page_hook) {
        funcall(:page_start)
        begin
          call_actions
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

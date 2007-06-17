# action

module Gluon
  class Action
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(page, rs_context, plugin, parent_name=nil)
      @page = page
      @c = rs_context
      @plugin = plugin
      @parent_name = parent_name
      @object_methods = {}
      Object.instance_methods.each do |name|
        @object_methods[name] = true
      end
    end

    def new(page, rs_context, parent_name=nil)
      Action.new(page, rs_context, @plugin, parent_name)
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

    def set_plugin
      for name, value in @plugin
        funcall("#{name}=", value)
      end
    end
    private :set_plugin

    def set_params
      if (@parent_name) then
        parent_name = "#{@parent_name}."
      else
        parent_name = ''
      end

      @c.req.params.keys.find_all{|n|
        n[0, parent_name.size] == parent_name && n[-1] != ?] && n[-1] != ?)
      }.map{|n|
        n[parent_name.size..-1]
      }.reject{|n|
        n.index(?.) ||
          (@plugin.key? n) || (@plugin.key? n.to_sym) ||
          (@object_methods.key? n)
      }.each do |name|
        value, = @c.req[name]
        funcall("#{name}=", value)
      end
    end
    private :set_params

    def call_actions
      if (@parent_name) then
        parent_name = "#{@parent_name}."
      else
        parent_name = ''
      end

      @c.req.params.keys.find_all{|n|
        n[0, parent_name.size] == parent_name && n =~ /\(\)$/
      }.map{|n|
        n[parent_name.size..-3] + '_action'
      }.reject{|n|
        n.index(?.) || (@object_methods.key? n)
      }.each do |name|
        funcall(name)
      end
    end
    private :call_actions

    def apply
      funcall(:c=, @c)
      set_plugin
      set_params
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

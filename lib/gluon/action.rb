# action

module Gluon
  class Action
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(page, rs_context, plugin, prefix='')
      @page = page
      @c = rs_context
      @plugin = plugin
      @prefix = prefix
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
      is_bool = {}
      bools = @c.req.params['@bool']
      unless (bools.kind_of? Array) then
        bools = [ bools ]
      end
      for name in bools
        is_bool[name] = true
      end

      @c.req.params.find_all{|n, v|
        n[0, @prefix.size] == @prefix && n !~ /\]$/ && n !~ /\)$/
      }.map{|n, v|
        [ n[@prefix.size..-1], v ]
      }.reject{|n, v|
        n.index(?.) ||
          (@plugin.key? n) || (@plugin.key? n.to_sym) ||
          (@object_methods.key? n)
      }.each do |name, value|
        if (is_bool[name]) then
          funcall("#{name}=", true)
          is_bool.delete(name)
        else
          funcall("#{name}=", value)
        end
      end

      is_bool.each_key do |name|
        funcall("#{name}=", false)
      end
    end
    private :set_params

    def call_actions
      @c.req.params.keys.find_all{|n|
        n[0, @prefix.size] == @prefix && n =~ /\(\)$/
      }.map{|n|
        n[@prefix.size..-3]
      }.reject{|n|
        n.index(?.) || (@object_methods.key? n)
      }.each do |name|
        @page.__send__(name)
      end
    end
    private :call_actions

    def apply
      funcall(:c=, @c)
      set_plugin
      funcall_hook(:page_hook) {
        funcall(:page_start)
        begin
          set_params
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

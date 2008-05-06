# presentation object

require 'erb'
require 'forwardable'
require 'gluon/action'

module Gluon
  class PresentationObject
    # for ident(1)
    CVS_ID = '$Id$'

    extend Forwardable

    def initialize(controller, rs_context, renderer, action)
      @controller = controller
      @c = rs_context
      @renderer = renderer
      @action = action
      @stack = []
    end

    def_delegator :@controller, :class, :page_type

    def view_explicit?
      @controller.respond_to? :__view__
    end

    def __view__
      if (view_explicit?) then
        @controller.__view__
      else
        @controller.class.name.gsub(/::/, '/') + '.rhtml'
      end
    end

    def __default_view__
      if (@controller.respond_to? :__default_view__) then
        @controller.__default_view__
      else
        nil
      end
    end

    def self.query(params)
      s = ''
      sep = ''
      for name, value_list in params
        unless (value_list.kind_of? Array) then
          value_list = [ value_list ]
        end
        for value in value_list
          s << sep
          s << ERB::Util.url_encode(name)
          s << '=' << ERB::Util.url_encode(value) if value
          sep = '&'
        end
      end
      s
    end

    def prefix
      s = @action.prefix.dup
      for prefix, child in @stack
        s << prefix << '.'
      end
      s
    end
    private :prefix

    def getopts(options, default_options)
      for key, value in default_options
        unless (options.key? key) then
          options[key] = value
        end
      end
      options
    end
    private :getopts

    def merge_opts(*opts_list)
      opts_list = opts_list.compact
      if (opts_list.length == 1) then
        return opts_list[0]
      end

      options = {}
      opts_list.reverse_each do |o|
        options.update(o)
      end

      query = nil
      opts_list.map{|opts| opts[:query] }.compact.reverse_each do |q|
        query = {} unless query
        query.update(q)
      end
      options[:query] = query if query

      options
    end
    private :merge_opts

    def funcall(name, *args)
      @stack.reverse_each do |prefix, child|
        if (child.respond_to? name) then
          return child.__send__(name, *args)
        end
      end
      @controller.__send__(name, *args)
    end
    private :funcall

    def value(name=:to_s, options={})
      getopts(options, :escape => true)
      s = funcall(name).to_s
      s = ERB::Util.html_escape(s) if options[:escape]
      s
    end

    class NegativeCondition
      def initialize(operand)
        @operand = operand
      end

      attr_reader :operand
    end

    def cond(name, options={})
      getopts(options, :negate => false)
      if (name.kind_of? NegativeCondition) then
        name = name.operand
        options[:negate] = true
      end
      unless (options[:negate]) then
        if (funcall(name)) then
          yield
        end
      else
        unless (funcall(name)) then
          yield
        end
      end
      nil
    end

    def foreach(name=:to_a, options={})
      funcall(name).each_with_index do |child, i|
        @stack.push [ "#{name}[#{i}]", child ]
        begin
          case (child)
          when Array, Numeric, String, Struct, Symbol, Time
            # skip action for ruby primitive
          else
            next_prefix_list = @stack.map{|prefix, child| prefix }
            @action.new_action(child, @c, next_prefix_list, prefix).call_actions
          end
          yield(i)
        ensure
          @stack.pop
        end
      end
      nil
    end

    def mkelem_start(name, options={})
      elem = "<#{name}"
      for name in [ :id, :class ]
        if (options.key? name) then
          elem << ' ' << name.to_s << '="' << ERB::Util.html_escape(options[:id]) << '"'
        end
      end
      if (options.key? :attrs) then
        for name, value in options[:attrs]
          elem << ' ' << name.to_s << '="' << ERB::Util.html_escape(options[:attrs][name]) << '"'
        end
      end
      elem
    end
    private :mkelem_start

    def mkpath(path, options={})
      path = path.dup
      path << options[:path_info] if (options.key? :path_info)
      path = '/' if path.empty?
      path << '?' << PresentationObject.query(options[:query]) if (options.key? :query)
      path << '#' << ERB::Util.html_escape(options[:fragment]) if (options.key? :fragment)
      path
    end
    private :mkpath

    def mklink(href, options={})
      elem = mkelem_start('a', options)
      elem << ' href="' << ERB::Util.html_escape(mkpath(href, options)) << '"'
      elem << ' target="' << ERB::Util.html_escape(options[:target]) << '"' if (options.key? :target)
      elem << '>'
      if (options.key? :text) then
        case (options[:text])
        when Symbol
          text = funcall(options[:text])
        when String
          text = options[:text]
        else
          raise "unknown link text type: #{options[:text].class}"
        end
        elem << ERB::Util.html_escape(text)
      elsif (block_given?) then
        out = ''
        yield(out)
        elem << out
      else
        elem << ERB::Util.html_escape(href)
      end
      elem << '</a>'
    end
    private :mklink

    def expand_path(name)
      case (name)
      when Class
        @c.class2path(name) or raise "not mounted: #{name}"
      else
        name
      end
    end
    private :expand_path

    def link(name, options={}, &block)
      name, options2 = funcall(name) if (name.kind_of? Symbol)
      path = expand_path(name)
      options = merge_opts(options, options2)
      unless (path.kind_of? String) then
        raise "unknon link name type: #{name.class}"
      end
      mklink(@c.req.script_name + path, options, &block)
    end

    def link_uri(path, options={}, &block)
      path, options2 = funcall(path) if (path.kind_of? Symbol)
      options = merge_opts(options, options2)
      unless (path.kind_of? String) then
        raise "unknon link path type: #{path.class}"
      end
      mklink(path, options, &block)
    end

    def action(name, options={}, &block)
      options[:query] = {} unless (options.key? :query)
      options[:query]["#{prefix}#{name}()"] = nil
      options[:text] = name.to_s unless (options.key? :text)
      if (page = options[:page]) then
        path = expand_path(page)
        unless (path.kind_of? String) then
          raise "unknown action page type: #{path.class}"
        end
        path = @c.req.script_name + path
      else
        path = @c.req.script_name + @c.req.env['PATH_INFO']
      end
      mklink(path, options, &block)
    end

    def mkframe(src, options={})
      elem = mkelem_start('frame', options)
      elem << ' src="' << ERB::Util.html_escape(mkpath(src, options)) << '"'
      elem << ' name="' << ERB::Util.html_escape(options[:name]) << '"' if (options.key? :name)
      elem << ' />'
    end
    private :mkframe

    def frame(name, options={})
      name, options2 = funcall(name) if (name.kind_of? Symbol)
      src = expand_path(name)
      options = merge_opts(options, options2)
      unless (src.kind_of? String) then
        raise "unknown frame src type: #{name.class}"
      end
      mkframe(@c.req.script_name + src, options)
    end

    def frame_uri(src, options={})
      src, options2 = funcall(src) if (src.kind_of? Symbol)
      options = merge_opts(options, options2)
      unless (src.kind_of? String) then
        raise "unknown frame src type: #{src.class}"
      end
      mkframe(src, options)
    end

    def import(name, options={})
      case (name)
      when Symbol
        value = funcall(name)
      else
        value = name
      end

      case (value)
      when Class
        controller = value.new
      else
        controller = value
      end

      case (name)
      when Symbol
        curr_prefix = name.to_s
      else
        curr_prefix = controller.class.to_s
      end
      prefix = prefix() + curr_prefix + '.'
      next_prefix_list = @stack.map{|prefix, child| prefix } + [ curr_prefix ]

      action = @action.new_action(controller, @c, next_prefix_list, prefix)
      action.setup.apply(@renderer)
    end

    def form_value(name)
      if (@stack.empty?) then
        @controller.__send__(name)
      else
        prefix, child = @stack[01]
        child.__send__(name)
      end
    end
    private :form_value

    def mkinput(type, name, options)
      elem = mkelem_start('input', options)
      elem << ' type="' << ERB::Util.html_escape(type) << '"'
      if (options[:direct]) then
        elem << ' name="' << ERB::Util.html_escape(name) << '"'
      else
        elem << ' name="' << ERB::Util.html_escape("#{prefix}#{name}") << '"'
      end
      elem << ' value="' << ERB::Util.html_escape(options[:value]) << '"' if (options.key? :value)
      elem << ' size="' << ERB::Util.html_escape(options[:size]) << '"' if (options.key? :size)
      elem << ' checked="checked"' if options[:checked]
      for attr_key in [ :disabled, :readonly ]
        if (options.key? attr_key) then
          value = options[attr_key]
          value = form_value(value) if (value.kind_of? Symbol)
          elem << ' ' << attr_key.to_s << '="' << attr_key.to_s << '"' if value
        end
      end
      elem << ' />'
    end
    private :mkinput

    def text(name, options={})
      mkinput('text', name, options.dup.update(:value => form_value(name)))
    end

    def password(name, options={})
      mkinput('password', name, options.dup.update(:value => form_value(name)))
    end

    def submit(name, options={})
      mkinput('submit', "#{name}()", options)
    end

    def hidden(name, options={})
      mkinput('hidden', name, options.dup.update(:value => form_value(name)))
    end

    def make_hidden(name, value)
      %Q'<input type="hidden" name="#{ERB::Util.html_escape(name)}" value="#{ERB::Util.html_escape(value)}" />'
    end
    private :make_hidden

    def checkbox(name, options={})
      options = options.dup
      options[:value] = 'true' unless (options.key? :value)
      options[:checked] = form_value(name) ? true : false
      name = "#{prefix}#{name}" unless options[:direct]
      options[:direct] = true
      make_hidden("#{name}@type", 'bool') << mkinput('checkbox', name, options)
    end

    def radio(name, value, options={})
      options = options.dup
      options[:value] = value
      options[:checked] = value == form_value(name)
      mkinput('radio', name, options)
    end

    def select(name, list, options={})
      name2 = "#{prefix}#{name}" unless options[:direct]

      if (options[:multiple]) then
        elem = make_hidden("#{name2}@type", 'list')
      else
        elem = ''
      end

      elem << mkelem_start('select', options)
      elem << ' name="' << ERB::Util.html_escape(name2) << '"'
      elem << ' size="' << ERB::Util.html_escape(options[:size]) << '"' if (options.key? :size)
      elem << ' multiple="multiple"' if options[:multiple]
      if (options.key? :disabled) then
        value = options[:disabled]
        value = form_value(value) if (value.kind_of? Symbol)
        elem << ' disabled="disabled"' if value
      end
      elem << '>'

      list = form_value(list) if (list.kind_of? Symbol)
      selects = form_value(name)
      selects = [ selects ] unless (selects.kind_of? Array)
      selected = {}
      for value in selects
        selected[value] = true
      end

      for value, text in list
        text = value unless text
        elem << '<option value="' << ERB::Util.html_escape(value) << '"'
        elem << ' selected="selected"' if selected[value]
        elem << '>'
        elem << ERB::Util.html_escape(text)
        elem << '</option>'
      end

      elem << '</select>'
    end

    def textarea(name, options={})
      elem = mkelem_start('textarea', options)
      if (options[:direct]) then
        elem << ' name="' << ERB::Util.html_escape(name) << '"'
      else
        elem << ' name="' << ERB::Util.html_escape("#{prefix}#{name}") << '"'
      end
      elem << ' rows="' << ERB::Util.html_escape(options[:rows]) << '"' if (options.key? :rows)
      elem << ' cols="' << ERB::Util.html_escape(options[:cols]) << '"' if (options.key? :cols)
      for attr_key in [ :disabled, :readonly ]
        if (options.key? attr_key) then
          value = options[attr_key]
          value = form_value(value) if (value.kind_of? Symbol)
          elem << ' ' << attr_key.to_s << '="' << attr_key.to_s << '"' if value
        end
      end
      elem << '>'
      elem << ERB::Util.html_escape(form_value(name))
      elem << '</textarea>'
    end
  end

  class ERBContext
    # for ident(1)
    CVS_ID = '$Id$'

    extend Forwardable
    include ERB::Util

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
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

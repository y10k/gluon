# presentation object

require 'erb'
require 'forwardable'

module Gluon
  class PresentationObject
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(page, rs_context, renderer, action, prefix='')
      @page = page
      @c = rs_context
      @renderer = renderer
      @action = action
      @prefix = prefix
      @stack = []
    end

    def __view__
      if (@page.respond_to? :__view__) then
        @page.__view__
      else
        @page.class.name.gsub(/::/, '/') + '.rhtml'
      end
    end

    def self.query(params)
      s = ''
      sep = ''
      for name, value_or_list in params
        case (value_or_list)
        when Array
          list = value_or_list
        else
          list = [ value_or_list ]
        end
        for value in list
          s << sep
          s << ERB::Util.url_encode(name)
          s << '=' << ERB::Util.url_encode(value) if value
          sep = '&'
        end
      end
      s
    end

    def prefix
      s = @prefix.dup
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
      @page.__send__(name, *args)
    end
    private :funcall

    def value(name=:to_s, options={})
      getopts(options, :escape => true)
      s = funcall(name).to_s
      s = ERB::Util.html_escape(s) if options[:escape]
      s
    end

    def cond(name, options={})
      getopts(options, :not => false)
      unless (options[:not]) then
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

    def cond_not(name, options={})
      options[:not] = true
      cond(name, options) {
        yield
      }
    end

    def foreach(name=:to_a, options={})
      funcall(name).each_with_index do |child, i|
        @stack.push [ "#{name}[#{i}]", child ]
        begin
          action = @action.new(child, @c, prefix)
          action.apply{ yield(i) }
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
      path = '/' if path.empty?
      if (options.key? :query) then
        path + '?' + PresentationObject.query(options[:query])
      else
        path
      end
    end
    private :mkpath

    def mklink(href, options={})
      href += options[:path_info] if (options.key? :path_info)
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
        path = @c.req.env['SCRIPT_NAME'] + path
      else
        path = @c.req.env['SCRIPT_NAME'] + @c.req.env['PATH_INFO']
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
      curr_prefix = name.to_s
      name = funcall(name) if (name.kind_of? Symbol)
      unless (name.kind_of? Class) then
        raise "unknown import name type: #{name.class}"
      end
      prefix = prefix() + curr_prefix + '.'
      page = name.new
      action = @action.new(page, @c, prefix)
      po = PresentationObject.new(page, @c, @renderer, action, prefix)
      context = ERBContext.new(po, @c)

      result = nil
      action.apply{ result = @renderer.render(context) }
      result
    end

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
      elem << ' />'
    end
    private :mkinput

    def form_value(name)
      if (@stack.empty?) then
        @page.__send__(name)
      else
        @stack[-1].__send__(name)
      end
    end
    private :form_value

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

    def checkbox(name, options={})
      options = options.dup
      options[:value] = 't' unless (options.key? :value)
      options[:checked] = form_value(name) ? true : false
      mkinput('checkbox', name, options)
    end

    def radio(name, value, options={})
      options = options.dup
      options[:value] = value
      options[:checked] = value == form_value(name)
      mkinput('radio', name, options)
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

    attr_reader :po
    def_delegator :@c, :req
    def_delegator :@c, :res
    def_delegator :@po, :value
    def_delegator :@po, :cond
    def_delegator :@po, :cond_not
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
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

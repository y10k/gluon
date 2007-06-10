# presentation object

require 'erb'
require 'forwardable'

module Gluon
  class PresentationObject
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(page, req, res)
      @page = page
      @req = req
      @res = res
      @stack = []
    end

    def view_name
      if (@page.respond_to? :view_name) then
        @page.view_name
      else
        @page.class.name.gsub(/::/, '/') + '.rhtml'
      end
    end

    def getopts(options, default_options)
      for key, value in default_options
        unless (options.key? key) then
          options[key] = value
        end
      end
      options
    end
    private :getopts

    def funcall(name, *args)
      @stack.reverse_each do |c|
        if (c.respond_to? name) then
          return c.__send__(name, *args)
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

    def not_cond(name)
      cond(name, :not => true) {
        yield
      }
    end

    def foreach(name, options={})
      funcall(name).each_with_index do |child, i|
        @stack.push(child)
        begin
          yield(i)
        ensure
          @stack.pop
        end
      end
      nil
    end

    def link(prefix, name, options={})
      case (name)
      when Symbol
        href = prefix + funcall(name)
      when String
        href = prefix + name
      else
        raise "unknon link name type: #{name.class}"
      end

      elem = '<a'
      elem << ' id="' << ERB::Util.html_escape(options[:id]) << '"' if (options.key? :id)
      elem << ' href="' << ERB::Util.html_escape(href) << '"'
      elem << ' target="' << ERB::Util.html_escape(options[:target]) << '"' if (options.key? :target)
      elem << '>'
      if (options.key? :text) then
        case (options[:text])
        when Symbol
          text = funcall(options[:text])
        when String
          text = options[:text]
        else
          raise "unknown link text type: #{name.class}"
        end
        elem << ERB::Util.html_escape(text)
      else
        elem << ERB::Util.html_escape(href)
      end
      elem << '</a>'
    end
    private :link

    def link_uri(name, options={})
      link('', name, options)
    end

    def link_path(name, options={})
      link(@req.script_name, name, options)
    end

    def frame(prefix, name, options={})
      case (name)
      when Symbol
        src = prefix + funcall(name)
      when String
        src = prefix + name
      else
        raise "unknown frame src type: #{src.class}"
      end

      elem = '<frame'
      elem << ' id="' << ERB::Util.html_escape(options[:id]) << '"' if (options.key? :id)
      elem << ' src="' << ERB::Util.html_escape(src) << '"'
      elem << ' name="' << ERB::Util.html_escape(options[:name]) << '"' if (options.key? :name)
      elem << ' />'
    end
    private :frame

    def frame_uri(name, options={})
      frame('', name, options)
    end

    def frame_path(name, options={})
      frame(@req.script_name, name, options)
    end
  end

  class ERBContext
    # for ident(1)
    CVS_ID = '$Id$'

    extend Forwardable
    include ERB::Util

    class << self
      def context_binding(_)
        _.instance_eval{ binding }
      end

      def render(context, eruby_script)
        b = context_binding(context)
        erb = ERB.new(eruby_script)
        erb.result(b)
      end
    end

    def initialize(po, req, res)
      @po = po
      @req = req
      @res = res
    end

    attr_reader :po
    attr_reader :req
    attr_reader :res

    def_delegator :@po, :value
    def_delegator :@po, :cond
    def_delegator :@po, :not_cond
    def_delegator :@po, :foreach
    def_delegator :@po, :link_uri
    def_delegator :@po, :link_path
    def_delegator :@po, :frame_uri
    def_delegator :@po, :frame_path
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

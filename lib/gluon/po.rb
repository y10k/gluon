# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

require 'erb'
require 'gluon/controller'

module Gluon
  class PresentationObject
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(controller, req_res, template_engine, prefix='', &block)
      @c_stack = [ controller ]
      @radio_stack = []
      @r = req_res
      @template_engine = template_engine
      @prefix = prefix
      @parent_block = block
      @export = Hash.new{|hash, page_type|
        hash[page_type] = Controller.find_view_export(page_type)
      }
    end

    def controller
      @c_stack[0]
    end

    def template_render(view, encoding, template_path)
      @template_engine.render(self, @r, view, encoding, template_path)
    end

    def content
      if (@parent_block) then
        @parent_block.call
      elsif (block_given?) then
        yield
      else
        raise 'not defined content.'
      end
    end

    def find_controller(name)
      @c_stack.reverse_each do |c|
        if (@export[c.class].key? name) then
          return c
        end
      end

      nil
    end
    private :find_controller

    def gluon(name, &block)
      if (c = find_controller(name)) then
        export_entry = @export[c.class][name]
        case (export_entry[:type])
        when :value
          value(c, name, export_entry[:options], &block)
        when :cond
          cond(c, name, export_entry[:options], &block)
        when :foreach
          foreach(c, name, export_entry[:options], &block)
        when :link
          link(c, name, export_entry[:options], &block)
        when :action
          action(c, name, export_entry[:options], &block)
        when :frame
          frame(c, name, export_entry[:options], &block)
        when :import
          import(c, name, export_entry[:options], &block)
        when :submit
          submit(c, name, export_entry[:options], &block)
        when :text
          text(c, name, export_entry[:options], &block)
        when :passwd
          passwd(c, name, export_entry[:options], &block)
        when :hidden
          hidden(c, name, export_entry[:options], &block)
        when :checkbox
          checkbox(c, name, export_entry[:options], &block)
        when :radio_group
          radio_group(c, name, export_entry[:options], &block)
        when :radio_button
          radio_button(c, name, export_entry[:options], &block)
        when :select
          select(c, name, export_entry[:options], &block)
        when :textarea
          textarea(c, name, export_entry[:options], &block)
        else
          raise "unknown view export type: #{name}"
        end
      else
        raise ArgumentError, "no view export: #{name}"
      end
    end

    def getopt(key, options, c)
      case (value = options[key])
      when Symbol
        c.__send__(value)
      else
        value
      end
    end
    private :getopt

    def value(c, name, options)
      s = c.__send__(name)
      s = ERB::Util.html_escape(s) if getopt(:escape, options, c)
      s
    end
    private :value

    def cond(c, name, options)
      if (c.__send__(name)) then
        yield
      else
        ''
      end
    end
    private :cond

    def foreach(c, name, options)
      s = ''
      save_prefix = @prefix
      begin
        c.__send__(name).each_with_index do |child, i|
          @prefix = "#{save_prefix}#{name}(#{i})."
          @c_stack.push(child)
          begin
            s << yield
          ensure
            @c_stack.pop
          end
        end
      ensure
        @prefix = save_prefix
      end

      s
    end
    private :foreach

    def mkpath(c, name)
      path, *args = c.__send__(name)
      if (path.is_a? Class) then
        path = @r.class2path(path, *args)
      end
      ERB::Util.html_escape(path)
    end
    private :mkpath

    def mkattrs(c, options)
      s = ''
      if (attrs = getopt(:attrs, options, c)) then
        for name, value in attrs
          if (value.is_a? Symbol) then
            value = c.__send__(value)
          end

          case (value)
          when TrueClass
            s << ' ' << name << '="' << name << '"'
          when FalseClass, NilClass
            s << ''
          else
            s << ' ' << name << '="' << ERB::Util.html_escape(value) << '"'
          end
        end
      end

      s
    end
    private :mkattrs

    def anchor_content(options, c, &block)
      if (block_given?) then
        yield
      elsif (content = getopt(:text, options, c)) then
        ERB::Util.html_escape(content)
      else
        ''
      end
    end
    private :anchor_content

    def link(c, name, options, &block)
      s = '<a'
      s << ' href="' << mkpath(c, name) << '"'
      s << mkattrs(c, options)
      s << '>'
      s << anchor_content(options, c, &block)
      s << '</a>'
    end
    private :link

    def action(c, name, options, &block)
      s = '<a'
      s << ' href="' << ERB::Util.html_escape("#{@r.equest.path}?#{@prefix}#{name}") << '"'
      s << mkattrs(c, options)
      s << '>'
      s << anchor_content(options, c, &block)
      s << '</a>'
    end
    private :action

    def frame(c, name, options)
      s = '<frame'
      s << ' src="' << mkpath(c, name) << '"'
      s << mkattrs(c, options)
      s << ' />'
    end
    private :frame

    def import(c, name, options, &block)
      compo = c.__send__(name)
      po = PresentationObject.new(compo, @r, @template_engine, "#{@prefix}#{name}.", &block)
      compo.class.process_view(po)
    end
    private :import

    def mkinput(c, type, name, value, checked, options)
      s = '<input'
      s << ' type="' << ERB::Util.html_escape(type) << '"'
      s << ' name="' << ERB::Util.html_escape("#{@prefix}#{name}") << '"'
      s << ' value="' << ERB::Util.html_escape(value) << '"' if value
      s << ' checked="checked"' if checked
      s << mkattrs(c, options)
      s << ' />'
    end
    private :mkinput

    def submit(c, name, options)
      value = getopt(:value, options, c)
      mkinput(c, 'submit', name, value, false, options)
    end
    private :submit

    def text(c, name, options)
      mkinput(c, 'text', name, c.__send__(name), false, options)
    end
    private :text

    def passwd(c, name, options)
      mkinput(c, 'password', name, c.__send__(name), false, options)
    end
    private :passwd

    def hidden(c, name, options)
      mkinput(c, 'hidden', name, c.__send__(name), false, options)
    end
    private :hidden

    def checkbox(c, name, options)
      s = '<input type="hidden"'
      s << ' name="' << ERB::Util.html_escape("#{@prefix}#{name}:checkbox") << '"'
      s << ' value="submit"'
      s << ' style="display: none"'
      s << ' />'
      value = getopt(:value, options, c) || ''
      s << mkinput(c, 'checkbox', name, value, c.__send__(name), options)
    end
    private :checkbox

    def radio_group(c, name, options)
      list = getopt(:list, options, c) or
        raise "need for `list' option at `#{c.class}\##{name}'"

      entry = {
        :group => name,
        :name => "#{@prefix}#{name}",
        :value => c.__send__(name),
        :list => list
      }

      @radio_stack.push(entry)
      begin
        s = yield
      ensure
        @radio_stack.pop
      end

      s
    end
    private :radio_group

    def radio_button(c, name, options)
      group = options[:group] or
        raise "need for `group' option at `#{c.class}\##{name}'"
      entry = @radio_stack.reverse.find{|entry| entry[:group] == group } or
        raise "not found a radio group of `#{group}' for radio button of `#{c.class}\##{name}'"

      value = c.__send__(name)
      unless (entry[:list].include? value) then
        raise "unexpected radio button value of `#{value}' at `#{c.class}\##{name}' for radio group of `#{entry[:group]}'"
      end

      s = '<input'
      s << ' type="radio"'
      s << ' name="' << ERB::Util.html_escape(entry[:name]) << '"'
      s << ' value="' << ERB::Util.html_escape(value) << '"' if value
      s << ' checked="checked"' if (value == entry[:value])
      s << mkattrs(c, options)
      s << ' />'
    end
    private :radio_button

    def select(c, name, options)
      list = getopt(:list, options, c) or
        raise "need for `list' option at `#{c.class}\##{name}'"
      multiple = getopt(:multiple, options, c)

      s = '<select'
      if (multiple) then
        s << ' name="' << ERB::Util.html_escape("#{@prefix}#{name}[]") << '"'
        s << ' multiple="multiple"'
      else
        s << ' name="' << ERB::Util.html_escape("#{@prefix}#{name}") << '"'
      end
      s << mkattrs(c, options)
      s << '>'

      selected = {}
      item = c.__send__(name)
      if (item.is_a? Array) then
        for i in item
          selected[i] = true
        end
      else
        selected[item] = true
      end

      for value, text in list
        text = value unless text
        s << '<option'
        s << ' value="' << ERB::Util.html_escape(value) << '"'
        s << ' selected="selected"' if selected[value]
        s << '>'
        s << ERB::Util.html_escape(text)
        s << '</option>'
      end

      s << '</select>'
    end
    private :select

    def textarea(c, name, options)
      s = '<textarea'
      s << ' name="' << ERB::Util.html_escape("#{@prefix}#{name}") << '"'
      s << mkattrs(c, options)
      s << '>'
      s << ERB::Util.html_escape(c.__send__(name))
      s << '</textarea>'
    end
    private :textarea
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

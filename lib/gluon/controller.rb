# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

module Gluon
  # = controller and meta-data
  # these methods may be explicitly defined at included class.
  #
  module Controller
    # for ident(1)
    CVS_ID = '$Id$'

    # :stopdoc:
    PATH_FILTER = {}
    VIEW_EXPORT = {}
    FORM_EXPORT = {}
    # :startdoc:

    # = controller syntax
    module Syntax
      private

      def gluon_path_filter(path_filter, &block)
        PATH_FILTER[self] = {
          :filter => path_filter,
          :block => block
        }
        nil
      end

      def __gluon_export__(table, name, type, options)
        name = name.to_sym
        unless (public_method_defined? name) then
          raise NoMethodError, "not defineid method `#{name}' of `#{self}'"
        end
        table[self] = {} unless (table.key? name)
        table[self][name] = { :type => type, :options => options }
        nil
      end

      def __gluon_export_params__(table, name, params={})
        name = name.to_sym
        table[self][name].update(params)
        nil
      end

      def __gluon_view_export__(name, type, options)
        __gluon_export__(VIEW_EXPORT, name, type, options)
      end

      def __gluon_form_export__(name, type, options)
        __gluon_export__(VIEW_EXPORT, name, type, options)
        __gluon_export__(FORM_EXPORT, name, type, options)
      end

      def __gluon_form_params__(name, params={})
        __gluon_export_params__(VIEW_EXPORT, name, params)
        __gluon_export_params__(FORM_EXPORT, name, params)
      end

      def gluon_value(name, options={})
        __gluon_view_export__(name, :value, options)
      end

      def gluon_value_reader(name, options={})
        class_eval{ attr_reader(name) } # why is class_eval necessary?
        gluon_value(name, options)
      end

      def gluon_cond(name, options={})
        __gluon_view_export__(name, :cond, options)
      end

      def gluon_cond_reader(name, options={})
        class_eval{ attr_reader(name) } # why is class_eval necessary?
        gluon_cond(name, options)
      end

      def gluon_foreach(name, options={})
        __gluon_form_export__(name, :foreach, options)
      end

      def gluon_foreach_reader(name, options={})
        class_eval{ attr_reader(name) } # why is class_eval necessary?
        gluon_foreach(name, options)
      end

      def gluon_link(name, options={})
        __gluon_view_export__(name, :link, options)
      end

      def gluon_link_reader(name, options={})
        class_eval{ attr_reader(name) } # why is class_eval necessary?
        gluon_link(name, options)
      end

      def gluon_action(name, options={})
        __gluon_form_export__(name, :action, options)
      end

      def gluon_frame(name, options={})
        __gluon_view_export__(name, :frame, options)
      end

      def gluon_frame_reader(name, options={})
        class_eval{ attr_reader(name) } # why is class_eval necessary?
        gluon_frame(name, options)
      end

      def gluon_import(name, options={}, &block)
        options = { :block => block }.merge(options)
        __gluon_form_export__(name, :import, options)
      end

      def gluon_import_reader(name, options={}, &block)
        class_eval{ attr_reader(name) } # why is class_eval necessary?
        gluon_import(name, options, &block)
      end

      def gluon_submit(name, options={})
        __gluon_form_export__(name, :submit, options)
      end

      def gluon_text(name, options={})
        __gluon_form_export__(name, :text, options)
        __gluon_form_params__(name, :writer => "#{name}=".to_sym)
      end

      def gluon_text_accessor(name, options={})
        class_eval{ attr_accessor(name) } # why is class_eval necessary?
        gluon_text(name, options)
      end

      def gluon_passwd(name, options={})
        __gluon_form_export__(name, :passwd, options)
        __gluon_form_params__(name, :writer => "#{name}=".to_sym)
      end

      def gluon_passwd_accessor(name, options={})
        class_eval{ attr_accessor(name) } # why is class_eval necessary?
        gluon_passwd(name, options)
      end

      def gluon_hidden(name, options={})
        __gluon_form_export__(name, :hidden, options)
        __gluon_form_params__(name, :writer => "#{name}=".to_sym)
      end

      def gluon_hidden_accessor(name, options={})
        class_eval{ attr_accessor(name) } # why is class_eval necessary?
        gluon_hidden(name, options)
      end

      def gluon_checkbox(name, options={})
        __gluon_form_export__(name, :checkbox, options)
        __gluon_form_params__(name, :writer => "#{name}=".to_sym)
      end

      def gluon_checkbox_accessor(name, options={})
        class_eval{ attr_accessor(name) } # why is class_eval necessary?
        gluon_checkbox(name, options)
      end

      def gluon_radio(name, list, options={})
        options = { :list => list }.merge(options)
        __gluon_form_export__(name, :radio, options)
        __gluon_form_params__(name, :writer => "#{name}=".to_sym)
      end

      def gluon_radio_accessor(name, list, options={})
        class_eval{ attr_accessor(name) } # why is class_eval necessary?
        gluon_radio(name, list, options)
      end

      def gluon_select(name, list, options={})
        options = { :list => list }.merge(options)
        __gluon_form_export__(name, :select, options)
        __gluon_form_params__(name, :writer => "#{name}=".to_sym)
      end

      def gluon_select_accessor(name, list, options={})
        class_eval{ attr_accessor(name) } # why is class_eval necessary?
        gluon_select(name, list, options)
      end

      def gluon_textarea(name, options={})
        __gluon_form_export__(name, :textarea, options)
        __gluon_form_params__(name, :writer => "#{name}=".to_sym)
      end

      def gluon_textarea_accessor(name, options={})
        class_eval{ attr_accessor(name) } # why is class_eval necessary?
        gluon_textarea(name, options)
      end
    end

    class << self
      def included(module_or_class)
        module_or_class.extend(Syntax)
        super
      end

      def find_path_filter(page_type)
        entry = PATH_FILTER[page_type] and return entry[:filter]
      end

      def find_path_block(page_type)
        entry = PATH_FILTER[page_type] and return entry[:block]
      end

      def find_export(table, page_type)
        export = {}
        for module_or_class in page_type.ancestors
          if (table.key? module_or_class) then
            export.update(table[module_or_class])
          end
        end

        export
      end
      private :find_export

      def find_view_export(page_type)
        find_export(VIEW_EXPORT, page_type)
      end

      def find_form_export(page_type)
        find_export(FORM_EXPORT, page_type)
      end

      def set_form_params(controller, req, prefix='')
        form_export = find_form_export(controller.class)
        for name, form_entry in form_export
          case (form_entry[:type])
          when :foreach
            controller.__send__(name).each_with_index do |c, i|
              set_form_params(c, req, "#{prefix}#{name}[#{i}].")
            end
          when :import
            set_form_params(controller.__send__(name), req, "#{prefix}#{name}.")
          when :text, :passwd, :hidden, :textarea
            if (value = req["#{prefix}#{name}"]) then
              controller.__send__(form_entry[:writer], value)
            end
          when :checkbox
            if (req["#{prefix}#{name}:checkbox"] == 'submit') then
              if (req["#{prefix}#{name}"]) then
                controller.__send__(form_entry[:writer], true)
              else
                controller.__send__(form_entry[:writer], false)
              end
            end
          when :radio, :select
            if (value = req["#{prefix}#{name}"]) then
              case (value)
              when Array
                values = value
              else
                values = [ value ]
              end

              case (form_entry[:options][:list])
              when Array
                list = form_entry[:options][:list]
              when Symbol
                list = controller.__send__(form_entry[:options][:list])
              else
                raise "invalid list value: #{form_entry[:options][:list]}"
              end

              values.each do |i|
                unless (list.include? i) then
                  raise "unexpected value for #{prefix}#{name}: #{i}"
                end
              end

              if (form_entry[:options][:multiple]) then
                controller.__send__(form_entry[:writer], values)
              else
                controller.__send__(form_entry[:writer], value)
              end
            end
          end
        end
      end
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

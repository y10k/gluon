# -*- coding: utf-8 -*-
# = gluon - simple web application framework
# == license
#   :include:../LICENSE
#

require 'gluon/controller'

module Gluon
  class Validator
    # for ident(1)
    CVS_ID = '$Id$'

    def initialize(controller, errors, prefix='')
      @c = controller
      @errors = errors
      @prefix = prefix
      @fail_count = 0
      @form_export = Controller.find_form_export(@c.class)
    end

    def controller
      @c
    end

    def validate(error_message)
      unless (yield) then
        @fail_count += 1
        @errors << error_message
      end

      self
    end

    def validated?
      @fail_count == 0
    end

    def prefix(name)
      "#{@prefix}#{name}"
    end
    private :prefix

    def foreach(name)
      if (form_entry = @form_export[name]) then
        if (:foreach == form_entry[:type]) then
          if (list = @c.__send__(name)) then
            list.each_with_index do |c, i|
              v = Validator.new(c, @errors, "#{prefix(name)}(#{i}).")
              yield(v)
              unless (v.validated?) then
                @fail_count += 1
              end
            end
          end
        else
          raise "expected foreach, but was #{form_entry[:type]} of `#{name}' for `#{@c}'"
        end
      else
        raise "not found a form export of `#{name}' for `#{@c}'"
      end

      self
    end

    def import(name)
      if (form_entry = @form_export[name]) then
        if (:import == form_entry[:type]) then
          if (c = @c.__send__(name)) then
            v = Validator.new(c, @errors, "#{prefix(name)}.")
            yield(v)
            unless (v.validated?) then
              @fail_count += 1
            end
          end
        else
          raise "expected import, but was #{form_entry[:type]} of `#{name}' for `#{@c}'"
        end
      else
        raise "not found a form export of `#{name}' for `#{@c}'"
      end

      self
    end

    def nonnil(name, options={})
      error_message = options[:error] || "`#{prefix(name)}' should not be nil."
      value = @c.__send__(name)
      validate error_message do
        ! value.nil?
      end

      self
    end

    def not_empty(name, options={})
      error_message = options[:error] || "`#{prefix(name)}' should not be empty."
      value = @c.__send__(name)
      validate error_message do
        (! value.nil?) && (! value.empty?)
      end

      self
    end

    def not_blank(name, options={})
      error_message = options[:error] || "`#{prefix(name)}' should not be blank."
      value = @c.__send__(name)
      validate error_message do
        (! value.nil?) && (! value.strip.empty?)
      end

      self
    end

    def encoding(name, options={})
      expected_encoding = options[:expected_encoding] || @c.class.page_encoding
      error_message = options[:error] || "encoding of `#{prefix(name)}' is not #{expected_encoding}."
      value = @c.__send__(name)
      validate error_message do
        if (value) then
          if (value.is_a? Array) then
            fail_count = 0
            for v in value
              v.force_encoding(expected_encoding)
              v.valid_encoding? or fail_count += 1
            end
            fail_count == 0
          else
            value.force_encoding(expected_encoding)
            value.valid_encoding?
          end
        else
          true                  # ignored nil.
        end
      end

      self
    end

    def encoding_everything(options={})
      for name, form_entry in @form_export
        case (form_entry[:type])
        when :foreach
          if (options.key? :expected_encoding) then
            opts = options
          else
            opts = options.merge(:expected_encoding => @c.class.page_encoding)
          end
          foreach name do |v|
            v.encoding_everything(opts)
          end
        when :import
          import name do |v|
            v.encoding_everything(options)
          end
        when :text, :passwd, :hidden, :textarea, :radio_group, :select
          encoding(name, options)
        when :checkbox
          # ignored not-string values.
        else
          raise "unknown form export type at `#{name}': #{form_entry[:type]}"
        end
      end

      self
    end

    def match(name, regexp, options={})
      error_message = options[:error] || "`#{prefix(name)}' should do match to #{regexp}."
      value = @c.__send__(name)
      validate error_message do
        (! value.nil?) && (value.is_a? String) && (value =~ regexp)
      end

      self
    end

    def not_match(name, regexp, options={})
      error_message = options[:error] || "`#{prefix(name)}' should not do match to #{regexp}."
      value = @c.__send__(name)
      validate error_message do
        (! value.nil?) && (value.is_a? String) && (value !~ regexp)
      end

      self
    end
  end

  module Validation
    # for ident(1)
    CVS_ID = '$Id$'

    def self.included(controller_class)
      if (! (controller_class.is_a? Class) || ! (controller_class.include? Controller)) then
        raise "not a controller class of `#{controller_class}'"
      end
    end

    def page_validation_preprocess
      @r.validation = nil
    end

    def validation(errors)
      v = Validator.new(self, errors, '')
      yield(v)

      if (@r.validation.nil?) then
        @r.validation = v.validated?
      else
        if (@r.validation) then
          @r.validation = v.validated?
        end
      end

      self
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

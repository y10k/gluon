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

    def foreach(name)
      if (form_entry = @form_export[name]) then
        if (:foreach == form_entry[:type]) then
          if (list = @c.__send__(name)) then
            list.each_with_index do |c, i|
              v = Validator.new(c, @errors, "#{@prefix}#{name}(#{i}).")
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
            v = Validator.new(c, @errors, "#{@prefix}#{name}.")
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
      @r.validation = v.validated?
      self
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

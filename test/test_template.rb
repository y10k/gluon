#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'gluon'
require 'test/unit'

module Gluon::Test
  class TemplateEngineTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @template_dir = 'test_template.template_dir'
      @template_engine = Gluon::TemplateEngine.new(@template_dir)
    end

    class Component
      extend Gluon::Component
    end

    def test_default_template
      assert_equal("#{@template_dir}/Gluon/Test/TemplateEngineTest/Component.erb",
                   @template_engine.default_template(Component))
    end

    def test_default_template_anon_class
      ex = assert_raise(ArgumentError) { @template_engine.default_template(Class.new) }
      assert_match(/anonymous class has no classpath/, ex.message)
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

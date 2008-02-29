#!/usr/local/bin/ruby

require 'gluon'
require 'test/unit'

module Gluon::Test
  class PluginMakerTest < Test::Unit::TestCase
    # for ident(1)
    CVS_ID = '$Id$'

    def setup
      @plugin_maker = Gluon::PluginMaker.new
    end

    def test_new_plugin
      @plugin_maker.add(:foo, 'apple')
      @plugin_maker.add(:bar, 'banana')
      @plugin_maker.setup
      plugin = @plugin_maker.new_plugin
      assert_equal('apple', plugin.foo)
      assert_equal('apple', plugin[:foo])
      assert_equal('banana', plugin.bar)
      assert_equal('banana', plugin[:bar])
    end

    def test_new_plugin_empty
      @plugin_maker.setup
      plugin = @plugin_maker.new_plugin
      assert_raise(NoMethodError) {
        plugin.foo
      }
      assert_raise(NameError) {
        plugin[:foo]
      }
    end

    def test_freeze
      @plugin_maker.setup
      assert_raise(TypeError) {
        @plugin_maker.add(:foo, 'apple')
      }
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

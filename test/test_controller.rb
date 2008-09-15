#!/usr/local/bin/ruby

require 'gluon'
require 'test/unit'

module Gluon::Test
  class ControllerTest < Test::Unit::TestCase
    class Plain
    end

    class PathFilter
      gluon_path_filter %r"^/foo/([^/]+)$"
    end

    class PathFilterSubclass < PathFilter
    end

    def test_gluon_path_filter
      assert_equal(%r"^/foo/([^/]+)$",
                   Gluon::Controller.find_path_filter(PathFilter))
    end

    def test_gluon_path_filter_subclass
      assert_equal(%r"^/foo/([^/]+)$",
                   Gluon::Controller.find_path_filter(PathFilterSubclass))
    end

    def test_gluon_path_filter_not_defined
      assert_nil(Gluon::Controller.find_path_filter(Plain))
    end

    class Advice
      def adviced
      end
      gluon_advice :adviced, :foo => 123

      def not_adviced
      end

      def adviced_many
      end
      gluon_advice :adviced_many, :foo => 123, :bar => 'Hello world.'
      gluon_advice :adviced_many, :baz => :HALO

      def advice_defined_at_subclass
      end

      def advice_changed_at_subclass
      end
      gluon_advice :advice_changed_at_subclass, :foo => false

      def advice_added_at_subclass
      end
      gluon_advice :advice_added_at_subclass, :foo => 123
    end

    class AdviceSubclass < Advice
      gluon_advice :advice_defined_at_subclass, :foo => 123
      gluon_advice :advice_changed_at_subclass, :foo => true
      gluon_advice :advice_added_at_subclass, :bar => 'Hello world.'
    end

    def test_gluon_method_advices
      assert_equal({ :foo => 123 },
                   Gluon::Controller.find_method_advices(Advice, :adviced))
    end

    def test_gluon_method_advices_subclass
      assert_equal({ :foo => 123 },
                   Gluon::Controller.find_method_advices(AdviceSubclass, :adviced))
    end

    def test_gluon_method_advices_not_adviced
      assert_equal({},
                   Gluon::Controller.find_method_advices(Advice, :not_adviced))
    end

    def test_gluon_method_advices_not_adviced_subclass
      assert_equal({},
                   Gluon::Controller.find_method_advices(AdviceSubclass, :not_adviced))
    end

    def test_gluon_method_advices_many
      assert_equal({ :foo => 123, :bar => 'Hello world.', :baz => :HALO },
                   Gluon::Controller.find_method_advices(Advice, :adviced_many))
    end

    def test_gluon_method_advices_many_subclass
      assert_equal({ :foo => 123, :bar => 'Hello world.', :baz => :HALO },
                   Gluon::Controller.find_method_advices(AdviceSubclass, :adviced_many))
    end

    def test_gluon_method_advices_defined_subclass
      assert_equal({},
                   Gluon::Controller.find_method_advices(Advice, :advice_defined_at_subclass))
      assert_equal({ :foo => 123 },
                   Gluon::Controller.find_method_advices(AdviceSubclass, :advice_defined_at_subclass))
    end

    def test_gluon_method_advices_changed_at_subclass
      assert_equal({ :foo => false },
                   Gluon::Controller.find_method_advices(Advice, :advice_changed_at_subclass))
      assert_equal({ :foo => true },
                   Gluon::Controller.find_method_advices(AdviceSubclass, :advice_changed_at_subclass))
    end

    def test_gluon_method_advices_added_at_subclass
      assert_equal({ :foo => 123 },
                   Gluon::Controller.find_method_advices(Advice, :advice_added_at_subclass))
      assert_equal({ :foo => 123, :bar => 'Hello world.' },
                   Gluon::Controller.find_method_advices(AdviceSubclass, :advice_added_at_subclass))
    end

    class Export
      def exported
      end
      gluon_export :exported

      def exported_with_advice
      end
      gluon_export :exported_with_advice, :foo => 123

      def not_exported
      end

      gluon_accessor :exported_reader_writer
      gluon_reader :exported_reader
      gluon_writer :exported_writer

      attr_accessor :not_exported_reader_writer
      attr_reader :not_exported_reader
      attr_writer :not_exported_writer

      def changed_at_subclass
      end

      def advice_changed_at_subclass
      end
      gluon_export :advice_changed_at_subclass, :foo => false

      def private_method
      end
      private :private_method

      def protected_method
      end
      protected :protected_method
    end

    class ExportSubclass < Export
      gluon_export :changed_at_subclass
      gluon_export :advice_changed_at_subclass, :foo => true, :bar => 123
    end

    def test_gluon_export
      assert(Gluon::Controller.find_exported_method(Export, :exported))
    end

    def test_gluon_export_subclass
      assert(Gluon::Controller.find_exported_method(ExportSubclass, :exported))
    end

    def test_gluon_export_with_advice
      assert(advices = Gluon::Controller.find_exported_method(Export, :exported_with_advice))
      assert_equal(123, advices[:foo])
    end

    def test_gluon_export_with_advice_subclass
      assert(advices = Gluon::Controller.find_exported_method(ExportSubclass, :exported_with_advice))
      assert_equal(123, advices[:foo])
    end

    def test_gluon_export_not_exported
      assert(! Gluon::Controller.find_exported_method(Export, :not_exported))
    end

    def test_gluon_export_not_exported_subclass
      assert(! Gluon::Controller.find_exported_method(ExportSubclass, :not_exported))
    end

    def test_gluon_export_not_defined_method
      assert(! Gluon::Controller.find_exported_method(Export, :not_defined_method))
    end

    def test_gluon_export_not_defined_method_subclass
      assert(! Gluon::Controller.find_exported_method(ExportSubclass, :not_defined_method))
    end

    def test_gluon_export_changed_at_subclass
      assert(! Gluon::Controller.find_exported_method(Export, :changed_at_subclass))
      assert(Gluon::Controller.find_exported_method(ExportSubclass, :changed_at_subclass))
    end

    def test_gluon_export_advice_changed_at_subclass
      assert(advices = Gluon::Controller.find_exported_method(Export, :advice_changed_at_subclass))
      assert_equal(false, advices[:foo])
      assert((! advices.has_key? :bar))

      assert(advices = Gluon::Controller.find_exported_method(ExportSubclass, :advice_changed_at_subclass))
      assert_equal(true, advices[:foo])
      assert_equal(123, advices[:bar])
    end

    def test_gluon_accessor
      assert(advices = Gluon::Controller.find_exported_method(Export, :exported_reader_writer))
      assert_equal(true, advices[:accessor])

      assert(advices = Gluon::Controller.find_exported_method(Export, :exported_reader_writer=))
      assert_equal(true, advices[:accessor])

      assert(advices = Gluon::Controller.find_exported_method(Export, :exported_reader))
      assert_equal(true, advices[:accessor])

      assert(advices = Gluon::Controller.find_exported_method(Export, :exported_writer=))
      assert_equal(true, advices[:accessor])
    end

    def test_gluon_accessor_subclass
      assert(advices = Gluon::Controller.find_exported_method(ExportSubclass, :exported_reader_writer))
      assert_equal(true, advices[:accessor])

      assert(advices = Gluon::Controller.find_exported_method(ExportSubclass, :exported_reader_writer=))
      assert_equal(true, advices[:accessor])

      assert(advices = Gluon::Controller.find_exported_method(ExportSubclass, :exported_reader))
      assert_equal(true, advices[:accessor])

      assert(advices = Gluon::Controller.find_exported_method(ExportSubclass, :exported_writer=))
      assert_equal(true, advices[:accessor])
    end

    def test_gluon_accessor_not_exported
      assert(! Gluon::Controller.find_exported_method(Export, :not_exported_reader_writer))
      assert(! Gluon::Controller.find_exported_method(Export, :not_exported_reader_writer=))
      assert(! Gluon::Controller.find_exported_method(Export, :not_exported_reader))
      assert(! Gluon::Controller.find_exported_method(Export, :not_exported_writer=))
    end

    def test_gluon_accessor_not_exported_subclass
      assert(! Gluon::Controller.find_exported_method(ExportSubclass, :not_exported_reader_writer))
      assert(! Gluon::Controller.find_exported_method(ExportSubclass, :not_exported_reader_writer=))
      assert(! Gluon::Controller.find_exported_method(ExportSubclass, :not_exported_reader))
      assert(! Gluon::Controller.find_exported_method(ExportSubclass, :not_exported_writer=))
    end

    def test_gluon_export_syntax_error_not_defined
      assert_raise(NameError) {
        Export.class_eval{
          gluon_export :not_defined_method
        }
      }
    end

    def test_gluon_export_syntax_error_private_method
      assert_raise(NameError) {
        Export.class_eval{
          gluon_export :private_method
        }
      }
    end

    def test_gluon_export_syntax_error_protected_method
      assert_raise(NameError) {
        Export.class_eval{
          gluon_export :protected_method
        }
      }
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

class Example
  class Import
    def subpage_by_class
      Subpage
    end

    def subpage_by_object
      Subpage.new
    end

    def subpage_with_params
      Subpage.new('foo')
    end
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

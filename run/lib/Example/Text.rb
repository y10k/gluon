class Example
  class Text
    attr_writer :c

    gluon_accessor :foo

    def ok
      # nothing to do.
    end
    gluon_export :ok
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

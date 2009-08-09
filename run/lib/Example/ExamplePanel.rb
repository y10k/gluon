# -*- coding: utf-8 -*-

class Example
  class ExamplePanel
    include Gluon::Controller

    def self.page_encoding
      __ENCODING__
    end

    gluon_path_filter %r"^/([A-Za-z]+)$" do |example|
      '/' + Menu::Item.key(example)
    end

    def request_GET(key)
      @example_type = Menu::Items[key].example_type or raise "not found an example: #{key}"
      @example = @example_type.new
    end

    gluon_import_reader :example

    def title
      @example_type.description
    end
    gluon_value :title
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

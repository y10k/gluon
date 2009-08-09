# -*- coding: utf-8 -*-

class Example
  class Panel
    include Gluon::Controller

    gluon_path_filter %r"^/([A-Za-z]+)$" do |example_type|
      '/' + Menu::Item.key(example_type)
    end

    def request_GET(key)
      @example_type = Menu::Items[key].example_type
      @header = Header.new(@r, @example_type)
    end

    gluon_import_reader :header

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

# -*- coding: utf-8 -*-

class Example
  class Panel < Gluon::Controller
    gluon_path_match '/([A-Za-z]+)' do |example_type|
      '/' + Menu::Item.key(example_type)
    end

    def page_start(key)
      @example_type = Menu::Items[key].example_type
      @header_footer = HeaderFooter.new(@r, @example_type)
    end

    gluon_import_reader :header_footer

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

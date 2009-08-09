# -*- coding: utf-8 -*-

class Example
  class ViewPanel
    include Gluon::Controller

    def self.page_encoding
      __ENCODING__
    end

    gluon_path_filter %r"^/([A-Za-z]+)$" do |example|
      '/' + Menu::Item.key(example)
    end

    VIEW_DIR = File.join(File.dirname(__FILE__), '..', '..', 'view')

    def request_GET(key)
      @example_type = Menu::Items[key].example_type
      @view_path = File.join(VIEW_DIR,
                             @example_type.name.gsub(/::/, '/') +
                             Gluon::ERBView.suffix)
    end

    def title
      @example_type.description
    end
    gluon_value :title

    def filename
      File.basename(@view_path)
    end
    gluon_value :filename

    def view_code
      File.open(@view_path, "r:#{__ENCODING__}") {|f| f.read }
    end
    gluon_value :view_code
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

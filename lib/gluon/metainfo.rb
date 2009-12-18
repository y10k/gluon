# -*- coding: utf-8 -*-

class Module
  # = meta information for gluon framework
  def gluon_metainfo
    @gluon_metainfo ||= {
      :path_match => nil,
      :view_export => {},
      :form_export => {},
      :action_export => {},
      :memoize_cache => {}
    }
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

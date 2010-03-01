# -*- coding: utf-8 -*-
# Welcom application

class Welcom < Gluon::Controller
  def_page_encoding __ENCODING__

  def title
    'Welcom to Gluon'
  end
  gluon_value :title

  def example
    Example
  end
  gluon_link :example
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

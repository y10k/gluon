# Welcom application

class Welcom
  include Gluon::Controller
  include Gluon::ERBView

  def page_get
  end

  def title
    'Welcom to Gluon'
  end
end

# Local Variables:
# mode: Ruby
# indent-tabs-mode: nil
# End:

class URI
  def http?
    @scheme.in? "http", "https"
  end
end

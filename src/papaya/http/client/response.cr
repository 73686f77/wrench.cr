class HTTP::Client::Response
  def keep_alive=(value : Bool)
    return unless value

    @headers["Connection"] = "keep-alive"
  end

  def content_length
    @headers["Content-Length"].to_i64? || 0_i64
  end
end

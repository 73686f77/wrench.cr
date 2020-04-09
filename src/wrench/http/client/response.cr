class HTTP::Client::Response
  def header_keep_alive=(value : Bool)
    return unless value

    @headers["Connection"] = "keep-alive"
  end

  def content_length
    @headers["Content-Length"].to_i64? || 0_i64
  end

  def encoding? : Bool
    return false unless _compress_type = compress_type
    return false if _compress_type.identity?

    true
  end

  def set_compress_type(value : HTTP::CompressType?)
    return unless value

    @headers["Content-Encoding"] = value.to_s.downcase
  end

  def compress_type : HTTP::CompressType?
    return unless encoding = @headers["Content-Encoding"]?

    HTTP::CompressType.parse? encoding
  end
end

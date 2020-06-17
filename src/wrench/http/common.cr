module HTTP
  enum CompressType : UInt8
    Gzip     = 0_u8
    Deflate  = 1_u8
    Br       = 2_u8
    Identity = 3_u8
  end
end

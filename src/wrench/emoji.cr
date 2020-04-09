module Emoji
  # References:
  # ISO Country Code to Unicode Flag in C# | https://alanedwardes.com/blog/posts/country-code-to-flag-emoji-csharp/
  def self.country_from_iso_code(iso_code : String)
    list = iso_code.upcase.chars rescue nil
    return unless list
    return if 2_i32 != list.size

    list.map { |char| (char.ord + 0x1F1A5_i32).chr }.join
  end
end

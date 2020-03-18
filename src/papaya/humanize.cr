struct Number
  SIZE_PREFIXES = {
    {" Bytes", " KiloBytes", " MegaBytes", " GigaBytes", " TeraBytes", " PetaBytes", " ExaBytes", " ZettaBytes", " YottaBytes"},
    {" Bytes", " KiloBytes", " MegaBytes", " GigaBytes", " TeraBytes", " PetaBytes", " ExaBytes", " ZettaBytes", " YottaBytes"},
  }

  TIME_PREFIXES = { {"ns", "µs", "ms", "s", "s", "s", "s"}, {"ns", "µs", "ms", "s", "s", "s", "s"} }

  def self.si_prefix(magnitude : Int, prefixes = SI_PREFIXES) : Char | String?
    index = magnitude // 3_i32
    prefixes = prefixes[magnitude < 0_i32 ? 0_i32 : 1_i32]
    prefixes[index.clamp (-prefixes.size + 1_i32)..(prefixes.size - 1_i32)]
  end
end

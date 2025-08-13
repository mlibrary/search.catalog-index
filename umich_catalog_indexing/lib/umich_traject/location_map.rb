require "match_map"
module Traject
  module UMich
    def self.location_map
      m = MatchMap.new
      m.echo = :onmiss

      m[/^AAEL ST[NOF]{1,2}/] = "AAEL CLOSD"
      m[/^AAEL RES[CIP].*/] = "AAEL RESRV"

      m[/^SPEC SC[HB]-RARE.*/] = "SPEC RARE"
      m[/^SPEC SCB-SCI/] = "SPEC RARE"
      m[/^SPEC SCH-BUHR/] = "SPEC RARE"
      m[/^SPEC SCH-HAFTER/] = "SPEC RARE"
      m[/^SPEC SCB-BIND/] = "SPEC BIND"
      m[/^SPEC SC[HB]-REF/] = "SPEC REF"
      m[/^SPEC SCB-CHIL.*/] = "SPEC CHIL"
      m[/^SPEC SCH-FAUL.*/] = "SPEC FAUL"
      m[/^SPEC SC[HB]-TAUB.*/] = "SPEC TAUB"
      m[/^SPEC SC[HB]-CUL/] = "SPEC CUL"
      m[/^SPEC SC[HB]-JHC.*/] = "SPEC JHC"
      m[/^SPEC SC[HB]-LA.*/] = "SPEC LABD" # need to fix this later
      m[/^SPEC SC[HB]-WOR/] = "SPEC WOR" # need to fix this later
      m[/^SPEC SCB-THC.*/] = "SPEC THC" # need to fix this later

      m[/^HATCH AMIC/] = "HATCH ASIA"
      m[/^HATCH AOFF/] = "HATCH ASIA"
      m[/^HATCH AOFFNC/] = "HATCH ASIA"
      m[/^HATCH AOKA/] = "HATCH ASIA"
      m[/^HATCH AOVR/] = "HATCH ASIA"
      m[/^HATCH AREF/] = "HATCH ASIA"
      m[/^HATCH ASPEC/] = "HATCH ASIA"

      m[/^HATCH CLBKS/] = "HATCH CLARKBKS"
      m[/^HATCH CLBKS-CIRC/] = "HATCH CLARKBKS"
      m[/^HATCH CLARK/] = "HATCH CLARKBKS"

      m[/^HATCH GDESK/] = "HATCH REF"
      m[/^HATCH GLRF/] = "HATCH REF"
      m[/^HATCH GRNT/] = "HATCH REF"

      m[/^MiU-H/] = "BENT"
      m[/^MiU-C/] = "CLEM"
      m[/^MiFliC/] = "FLINT"
      m[/^MiAaUTR/] = "UMTRI"

      m[/^BUHR.*/] = "BUHR"

      # Archives - Special Collections
      m[/^FLINT SPEC/] = "FLINT ARCH"

      # Reference Collection
      m[/^FLINT ABST/] = "FLINT REF"
      m[/^FLINT REFD/] = "FLINT REF"
      m[/^FLINT TECH/] = "FLINT REF"

      # Microforms
      m[/^FLINT MCARD/] = "FLINT MICRO"
      m[/^FLINT MFICH/] = "FLINT MICRO"
      m[/^FLINT MFILM/] = "FLINT MICRO"

      # English language program
      m[/^FLINT ELP.*/] = "FLINT ELP"

      m
    end
  end
end

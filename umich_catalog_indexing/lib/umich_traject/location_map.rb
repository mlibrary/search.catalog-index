require "match_map"
module Traject
  module UMich
    def self.location_map
      m = MatchMap.new
      m.echo = :onmiss

      #====added 03-2023 for SCRC
      m[/^SPEC SC[HB]-RARE.*/] = "SPEC RARE"
      m[/^SPEC SCB-SCI/] = "SPEC RARE"
      m[/^SPEC SCH-BUHR/] = "SPEC RARE"
      m[/^SPEC SCH-HAFTER/] = "SPEC RARE"
      m[/^SPEC SCB-BIND/] = "SPEC BIND"
      m[/^SPEC SC[HB]-REF/] = "SPEC REF"
      #====end of 03-2023 SCRC additions
      #====added 09-2022 for SCRC location addtions
      m[/^SPEC SCB-CHIL.*/] = "SPEC CHIL"
      m[/^SPEC SCH-FAUL.*/] = "SPEC FAUL"
      m[/^SPEC SC[HB]-TAUB.*/] = "SPEC TAUB"
      m[/^SPEC SC[HB]-CUL/] = "SPEC CUL"
      m[/^SPEC SC[HB]-JHC.*/] = "SPEC JHC"
      m[/^SPEC SC[HB]-LA.*/] = "SPEC LABD" # need to fix this later
      m[/^SPEC SC[HB]-WOR/] = "SPEC WOR" # need to fix this later
      m[/^SPEC SCB-THC.*/] = "SPEC THC" # need to fix this later
      #==== end of 09-2022 SCRC additions

      m[/^SPEC RCLC/] = "SPEC CHIL"
      m[/^SPEC GOSL/] = ["SPEC CHIL", "SPEC GOSL"]
      m[/^SPEC CHIL.*/] = "SPEC CHIL"
      m[/^SPEC CUL.*/] = "SPEC CUL"
      m[/^SPEC WALP.*/] = "SPEC CHIL"
      m[/^SPEC FAUL.*/] = "SPEC FAUL"
      m[/^SPEC$/] = "SPEC"
      m[/^SPEC TAUB.*/] = "SPEC TAUB"
      m[/^SPEC LA.*/] = "SPEC LABD"
      #=== between 09-2022 changes and here should be removed
      #=== when confirmed that everything in SPEC is cleaned up

      m[/^HATCH AOFFNC/] = "HATCH ASIA"
      m[/^HATCH AOKA/] = "HATCH ASIA"
      m[/^HATCH AREF/] = "HATCH ASIA"
      m[/^HATCH AOVR/] = "HATCH ASIA"
      m[/^HATCH AOFF/] = "HATCH ASIA"
      m[/^HATCH AMIC/] = "HATCH ASIA"
      m[/^HATCH ASPEC/] = "HATCH ASIA"

      m[/^HATCH GRNT/] = "HATCH REF"
      m[/^HATCH GLRF/] = "HATCH REF"
      m[/^HATCH GDESK/] = "HATCH REF"

      m[/^MiU-H/] = "BENT"
      m[/^MiU-C/] = "CLEM"
      m[/^MiFliC/] = "FLINT"
      m[/^MiAaUTR/] = "UMTRI"

      m[/^BUHR.*/] = "BUHR"

      # Archives - Special Collections
      m[/^FLINT SPEC/] = "FLINT ARCH"

      # Reference Collection
      m[/^FLINT REFD/] = "FLINT REF"
      m[/^FLINT TECH/] = "FLINT REF"
      m[/^FLINT ABST/] = "FLINT REF"

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

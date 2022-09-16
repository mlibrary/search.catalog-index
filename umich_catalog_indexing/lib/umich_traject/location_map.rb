require 'match_map'
module Traject
  module UMich
    def self.location_map
      m = MatchMap.new
      m.echo = :onmiss
      #====added 09-2022 for SCRC location addtions
      m[/^SPEC SCB-CHIL.*/] = "SPEC CHIL"
      m[/^SPEC SCH-FAUL.*/] = "SPEC FAUL"
      m[/^SPEC SC[HB]-TAUB.*/] = "SPEC TAUB"
      m[/^SPEC SC[HB]-CUL/] = "SPEC CUL"
      m[/^SPEC SC[HB]-JHC.*/] = "SPEC JHC"
      m[/^SPEC SC[HB]-LA.*/] = "SPEC LABD" #need to fix this later
      m[/^SPEC SC[HB]-WOR/] = "SPEC WOR" #need to fix this later
      m[/^SPEC SCB-THC.*/] = "SPEC THC" #need to fix this later
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
      m[/^HATCH MSHLV/] = "HATCH BKS"
      m[/^HATCH MREF/] = "HATCH BKS"
      m[/^HATCH MOVRD/] = "HATCH MAP"
      m[/^HATCH MOVR/] = "HATCH BKS"
      m[/^HATCH MMIC/] = "HATCH MAP"
      m[/^HATCH DFILE/] = "HATCH DOCS"
      m[/^HATCH AREF/] = "HATCH ASIA"
      m[/^HATCH AOVR/] = "HATCH ASIA"
      m[/^HATCH AOFF/] = "HATCH ASIA"
      m[/^HATCH AMIC/] = "HATCH ASIA"
      m[/^HATCH ASPEC/] = 'HATCH ASIA'
      m[/^MiU-H/] = "BENT"
      m[/^MiU-C/] = "CLEM"
      m[/^MiFliC/] = "FLINT"
      m[/^MiAaUTR/] = "UMTRI"
      m[/^BUHR.*/] = "BUHR"
      m[/^HATCH MFOL/] = "HATCH MRAR"
      m[/^HATCH MFILR/] = "HATCH MRAR"
      m[/^HATCH MFILE/] = "HATCH MAP"
      m[/^HATCH MATL/] = "HATCH BKS"
      m[/^HATCH GRNT/] = "HATCH REF"
      m[/^HATCH GLRF/] = "HATCH REF"
      m[/^HATCH GDESK/] = "HATCH REF"
      m[/^FLINT TECH/] = "FLINT REF"
      m[/^HATCH DSOFT/] = "HATCH DOCS"
      m[/^FLINT SPEC/] = "FLINT ARCH"
      m[/^HATCH DREF/] = "HATCH DOCS"
      m[/^FLINT REFD/] = "FLINT REF"
      m[/^HATCH DMIC/] = "HATCH DOCS"
      m[/^FLINT OVERZ/] = "FLINT MAIN"
      m[/^FLINT MSTR/] = "FLINT MAIN"
      m[/^FLINT MOVRZ/] = "FLINT MEDIA"
      m[/^FLINT MFILM/] = "FLINT MICRO"
      m[/^FLINT MFICH/] = "FLINT MICRO"
      m[/^FLINT MCARD/] = "FLINT MICRO"
      m[/^FLINT FSPAM/] = "FLINT MAIN"
      m[/^FLINT BUSP/] = "FLINT PERI"
      m[/^FLINT BUSB/] = "FLINT MAIN"
      m[/^FLINT ATLAS/] = "FLINT REF"
      return m
    end
  end
end


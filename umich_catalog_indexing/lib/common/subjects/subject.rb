module Common
  class Subjects
    class Subject
      class << self
        def subject_field?(field)
          SUBJECT_FIELDS.include?(field.tag)
        end

        # Delegate LC determination to the class itself.
        def lc_subject_field?(field)
          LCSubject.lc_subject_field?(field)
        end

        # Pass off a new subject to the appropriate class
        def new(field)
          if lc_subject_field?(field)
            LCSubject.from_field(field)
          else
            NonLCSubject.from_field(field)
          end
        end
      end
    end
  end
end

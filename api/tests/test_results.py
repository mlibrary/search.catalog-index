from catalog_api.results import Filter, FilterQuery


class TestFilter:
    def test_filter_has_values(self):
        subject = Filter(field="format", values=["Value1", 1, "Value2", 25]).values

        assert subject[0].text == "Value1"
        assert subject[0].count == 1
        assert subject[1].text == "Value2"
        assert subject[1].count == 25


class TestFilterQuery:
    def test_query_does_not_include_availability(self):
        subject = FilterQuery({"filters": ["availability:Availabilable Online"]})
        assert len(subject.query()) == 0

    def test_query_handles_format_facet(self):
        expected = "format:(Book)"
        subject = FilterQuery({"filters": ["format:Book"]})
        assert expected in subject.query()

    def test_query_escape_the_value_and_use_solr_name(self):
        expected = "topicStr:(Engineering\\ \\&\\ Applied\\ Sciences)"
        subject = FilterQuery({"filters": ["subject:Engineering & Applied Sciences"]})
        assert expected in subject.query()

    def test_query_ands_together_facets_with_same_facet_field(self):
        expected = "topicStr:(Technology\\ \\-\\ General AND Engineering\\ \\&\\ Applied\\ Sciences)"

        subject = FilterQuery(
            {
                "filters": [
                    "subject:Technology - General",
                    "subject:Engineering & Applied Sciences",
                ]
            }
        )
        assert expected in subject.query()

    def test_query_excludes_unknown_facet(self):
        subject = FilterQuery({"filters": ["facet_field_does_not_exist:some_value"]})
        assert len(subject.query()) == 0

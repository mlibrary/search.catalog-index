# MARC::FastXMLWriter

## 1.1.0 Fix namespace code

The The supposed `include_namespace` code wasn't actually using
the namespace (`xmlns="http://www.loc.gov/..."`), only 
defining it (`xmlns:marc="http://www.loc.gov/...`), thus producing
files were not, in fact, namespaced.

Also adds tests against nokogiri as well as rexml

### 1.0.0 First release


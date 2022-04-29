class RequestFilter {
  String fieldType;
  String fieldName;
  dynamic fieldValue;
  String rule;

  RequestFilter(this.fieldType, this.fieldName, this.rule, this.fieldValue);
}

class RequestSorter {
  String fieldType;
  String fieldName;
  String sortType;

  RequestSorter(this.sortType, this.fieldType, this.fieldName);
}

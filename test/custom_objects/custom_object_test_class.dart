import 'dart:io';

String testClassName = "TestClass";

class TestClass {
  int integerField;
  double floatField;
  bool booleanField;
  String stringField;
  DateTime dateField;
  File fileField;

  List<double> locationField;
  List<int> arrayIntegers;
  List<double> arrayFloats;
  List<bool> arrayBooleans;
  List<String> arrayStrings;

  TestClass({
    this.integerField,
    this.floatField,
    this.booleanField,
    this.stringField,
    this.locationField,
    this.dateField,
    this.fileField,
    this.arrayIntegers,
    this.arrayFloats,
    this.arrayBooleans,
    this.arrayStrings,
  });

  TestClass.fromJson(Map<String, dynamic> json) {
    this.integerField = json['integerField'];
    this.floatField = json['floatField'];
    this.booleanField = json['booleanField'];
    this.stringField = json['stringField'];
    this.dateField = json['dateField'];
    this.fileField = json['fileField'];

    var locationFieldRaw = json['locationField'];
    if (locationFieldRaw != null) {
      this.locationField =
          List.of(locationFieldRaw).map((e) => e as double).toList();
    }
    var arrayIntegersRaw = json['arrayIntegers'];
    if (arrayIntegersRaw != null) {
      this.arrayIntegers =
          List.of(arrayIntegersRaw).map((e) => e as int).toList();
    }

    var arrayFloatsRaw = json['arrayFloats'];
    if (arrayFloatsRaw != null) {
      this.arrayFloats =
          List.of(arrayFloatsRaw).map((e) => e as double).toList();
    }
    var arrayBooleansRaw = json['arrayBooleans'];
    if (arrayBooleansRaw != null) {
      this.arrayBooleans =
          List.of(arrayBooleansRaw).map((e) => e as bool).toList();
    }
    var arrayStringsRaw = json['arrayStrings'];
    if (arrayStringsRaw != null) {
      this.arrayStrings =
          List.of(arrayStringsRaw).map((e) => e as String).toList();
    }
  }

  Map<String, dynamic> toJson() => {
        'integerField': integerField,
        'floatField': floatField,
        'booleanField': booleanField,
        'stringField': stringField,
        'locationField': locationField,
        'dateField': dateField,
        'fileField': fileField,
        'arrayIntegers': arrayIntegers,
        'arrayFloats': arrayFloats,
        'arrayBooleans': arrayBooleans,
        'arrayStrings': arrayStrings
      };

  @override
  toString() => toJson().toString();
}

// TODO: should be generated by builder
part of 'person.dart';

Person decodePerson(EJsonValue ejson) {
  return switch (ejson) {
    {
      'name': EJsonValue name,
      'birthDate': EJsonValue birthDate,
      'income': EJsonValue income,
      'spouse': EJsonValue spouse,
    } =>
      Person(
        name.to<String>(),
        birthDate.to<DateTime>(),
        income.to<double>(),
        spouse: spouse.to<Person?>(),
      ),
    _ => raiseInvalidEJson(ejson),
  };
}

EJsonValue encodePerson(Person person) {
  return {
    'name': person.name.toEJson(),
    'birthDate': person.birthDate.toEJson(),
    'income': person.income.toEJson(),
    'spouse': person.spouse.toEJson(),
  };
}

extension PersonEJsonEncoderExtension on Person {
  @pragma('vm:prefer-inline')
  EJsonValue toEJson() => encodePerson(this);
}

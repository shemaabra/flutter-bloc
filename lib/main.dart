import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => PersonBloc(),
        child: const HomePage(),
      ),
    );
  }
}

@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadPersonAction implements LoadAction {
  final PersonUrl url;
  const LoadPersonAction({required this.url}) : super();
}

enum PersonUrl {
  person1,
  person2,
}

extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.person1:
        return 'http://127.0.0.1:5500/api/person1.json';
      case PersonUrl.person2:
        return 'http://127.0.0.1:5500/api/person1.json';
    }
  }
}

@immutable
class Person {
  final String name;
  final int age;

  const Person({
    required this.name,
    required this.age,
  });

  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;
}

Future<Iterable<Person>> getPersons(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

@immutable
class FetchResult {
  final Iterable<Person> person;
  final bool isRetrivedFromCache;

  const FetchResult({
    required this.person,
    required this.isRetrivedFromCache,
  });

  @override
  String toString() =>
      'FetchResult(isRetrivedFromCache = $isRetrivedFromCache, person=$person';
}

class PersonBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<PersonUrl, Iterable<Person>> _cache = {};
  PersonBloc() : super(null) {
    on<LoadPersonAction>(
      (event, emit) async {
        final url = event.url;
        if (_cache.containsKey(url)) {
          final cachedPerson = _cache[url]!;
          final result = FetchResult(
            person: cachedPerson,
            isRetrivedFromCache: true,
          );
          emit(result);
        } else {
          final persons = await getPersons(url.urlString);
          _cache[url] = persons;
          final result = FetchResult(
            person: persons,
            isRetrivedFromCache: false,
          );
          emit(result);
        }
      },
    );
  }
}

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          "Home page",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  context.read<PersonBloc>().add(
                        const LoadPersonAction(url: PersonUrl.person1),
                      );
                },
                child: const Text(
                  "Load json #1",
                  style: TextStyle(color: Colors.teal),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<PersonBloc>().add(
                        const LoadPersonAction(url: PersonUrl.person2),
                      );
                },
                child: const Text(
                  "Load json #2",
                  style: TextStyle(color: Colors.teal),
                ),
              ),
            ],
          ),
          BlocBuilder<PersonBloc, FetchResult?>(
              buildWhen: (previousResult, currentResult) {
            return previousResult?.person != currentResult?.person;
          }, builder: (context, fetchResult) {
            final person = fetchResult?.person;
            if (person == null) {
              return SizedBox();
            } else {
              return Expanded(
              child: ListView.builder(
                itemCount: person.length,
                itemBuilder: (context, index) {
                  final persons = person[index]!;
                  return ListTile(
                    title: Text(persons.name),
                  );
                },
              ),
            );
            }
            
            return Container();
          }),
        ],
      ),
    );
  }
}

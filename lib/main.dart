import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: const Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  /* Declarando um controller para o TextFIeld */
  final _toDoController = TextEditingController();

  /* Lista para receber e guardar os dados digitados */
  List _toDoList = [];

  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();
    _readData().then(
      (data) => setState(
        () {
          _toDoList = json.decode(data) as List<dynamic>;
        },
      ),
    );
  }

  /* Adiciona tarefa */
  void _addToDo() {
    setState(() {
      final newToDo = <String, dynamic>{};

      newToDo['title'] = _toDoController.text;
      _toDoController.text = '';
      newToDo['ok'] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  /* Funcao para fazer refresh */
  Future<void> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      /* condicoes de Ordenacao  */
      _toDoList.sort((a, b) {
        if (a['ok'] as bool && !(b['ok'] == a['ok'])) {
          return 1;
        } else if (!(a['ok'] == b['ok']) && b['ok'] as bool) {
          return -1;
        } else {
          return 0;
        }
      });

      _saveData();
    });

    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista de Tarefas',
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: [
                /* Para expandir o maximo que poder juntamente com outro(s) widget(s) */
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                      labelText: 'Nova Tarefa',
                      labelStyle: TextStyle(
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
                /* Botao de adicionar */
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      Colors.blueAccent,
                    ),
                    foregroundColor: MaterialStateProperty.all(
                      Colors.white,
                    ),
                  ),
                  onPressed: _addToDo,
                  child: Text(
                    'ADD',
                  ),
                ),
              ],
            ),
          ),
          /* Para expandir o maximo que poder juntamente com outro(s) widget(s) */
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    /* WIdget que permite a movimentacao e direcao desejada */
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        onChanged: (check) {
          setState(() {
            _toDoList[index]['ok'] = check;
            _saveData();
          });
        },
        title: Text(_toDoList[index]['title'].toString()),
        value: _toDoList[index]['ok'] as bool,
        secondary: CircleAvatar(
          child:
              Icon(_toDoList[index]['ok'] as bool ? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index] as Map<dynamic, dynamic>);
          _lastRemovedPosition = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text('Tarefa "${_lastRemoved["title"]}" removida!'),
            action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );

          /*Notificacao e aparicao na tela */
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

/* Funcao para levar e retornar os dados em JSON */
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  /* FUncao para salvar os dados no celular */
  Future<File> _saveData() async {
    /* Converter a lista em arquivo JSON and store in Data variable String */
    final data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  /* Funcao para ler dados gravados */
  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return 'Ocorreu um erro!';
    }
  }
}

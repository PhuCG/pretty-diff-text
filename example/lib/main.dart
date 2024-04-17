import 'package:flutter/material.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo of PrettyDiffText',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Demo of PrettyDiffText'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final TextEditingController _oldTextEditingController;
  late final TextEditingController _newTextEditingController;
  late final TextEditingController _diffTimeoutEditingController;
  DiffType _diffType = DiffType.WORD;

  @override
  void initState() {
    _oldTextEditingController = TextEditingController();
    _newTextEditingController = TextEditingController();
    _diffTimeoutEditingController = TextEditingController();
    _oldTextEditingController.text =
        "She not only is responsible to managing the team, but also she take care of client interactions.";
    _newTextEditingController.text =
        "She is not only responsible for managing the team, but she also takes care of client interactions.";

    _diffTimeoutEditingController.text = "1.0";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _oldTextEditingController,
                      maxLines: 5,
                      onChanged: (string) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: "Old Text",
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 5,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _newTextEditingController,
                      maxLines: 5,
                      onChanged: (string) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: "New Text",
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                ),
                margin: EdgeInsets.only(top: 8),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: PrettyDiffText(
                    displayType: DisplayType.COMPARE,
                    textAlign: TextAlign.left,
                    oldText: _oldTextEditingController.text,
                    newText: _newTextEditingController.text,
                    diffCleanupType: DiffCleanupType.SEMANTIC,
                    diffType: _diffType,
                    diffTimeout: diffTimeoutToDouble(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_diffType == DiffType.WORD) {
                    _diffType = DiffType.CHARACTER;
                  } else {
                    _diffType = DiffType.WORD;
                  }
                });
              },
              child: Text(
                _diffType == DiffType.WORD
                    ? 'Diff by character'.toUpperCase()
                    : 'Diff by word'.toUpperCase(),
              ),
            )
          ],
        ),
      ),
    );
  }

  double diffTimeoutToDouble() {
    try {
      final response = double.parse(_diffTimeoutEditingController.text);
      ScaffoldMessenger.of(context).clearSnackBars();
      return response;
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Enter a valid double value for edit cost")));
      });
      return 1.0; // default value for timeout
    }
  }
}

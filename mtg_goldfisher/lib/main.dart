import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keymap/keymap.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:scryfall_api/scryfall_api.dart' as scry;

void main() => runApp(const MtgGoldfisher());
int deckPtr = 0;
final apiClient = scry.ScryfallApiClient();
List<String> deck = ["Hello"];

/// A class for consolidating the definition of menu entries.
///
/// This sort of class is not required, but illustrates one way that defining
/// menus could be done.
class MenuEntry {
  const MenuEntry(
      {required this.label, this.shortcut, this.onPressed, this.menuChildren})
      : assert(menuChildren == null || onPressed == null,
            'onPressed is ignored if menuChildren are provided');
  final String label;

  final MenuSerializableShortcut? shortcut;
  final VoidCallback? onPressed;
  final List<MenuEntry>? menuChildren;

  static List<Widget> build(List<MenuEntry> selections) {
    Widget buildSelection(MenuEntry selection) {
      if (selection.menuChildren != null) {
        return SubmenuButton(
          menuChildren: MenuEntry.build(selection.menuChildren!),
          child: Text(selection.label),
        );
      }
      return MenuItemButton(
        shortcut: selection.shortcut,
        onPressed: selection.onPressed,
        child: Text(selection.label),
      );
    }

    return selections.map<Widget>(buildSelection).toList();
  }
}

class DynamicWidget extends StatefulWidget {
  @override
  State<DynamicWidget> createState() => _DynamicWidgetState();
}

class _DynamicWidgetState extends State<DynamicWidget> {

 void addCard(String card){
    deck.add(card);
 }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(5.0),
      /*  child:ListBody(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
                  child: TextFormField(
                  controller: Name,
                    decoration: const InputDecoration(
                        labelText: 'Card Name',
                        border: OutlineInputBorder()
                  ),
                ),
              ),
            ],
          )
        ],
      ),*/
      child: Container(
        width: 150,
        color: Colors.red,
        child: Column(
          children: [
            Text(deck[deckPtr]),
          ],
        )
      ),
    );
    
  }
}

class MtgGoldfisher extends StatelessWidget {
  const MtgGoldfisher({super.key});

  static const String kMessage = '"Talk less. Smile more." - A. Burr';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: MtgApp(message: kMessage)),
    );
  }
}

// ignore: must_be_immutable
class MtgApp extends StatefulWidget {
  MtgApp({
    super.key,
    required this.message,
  });

  String message = "";

  @override
  State<MtgApp> createState() => _MtgAppState();
}

class _MtgAppState extends State<MtgApp> {
  ShortcutRegistryEntry? _shortcutsEntry;
  String? _lastSelection;

  //used for card drawing
  List<DynamicWidget> dynamicList = [];
  List<String> cardName = [];

  Color backgroundColor = Color.fromARGB(255, 255, 255, 255);

  bool get showingMessage => _showMessage;
  bool _showMessage = false;
  set showingMessage(bool value) {
    if (_showMessage != value) {
      setState(() {
        _showMessage = value;
      });
    }
  }

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: MenuBar(
                  children: MenuEntry.build(_getMenus()),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          showingMessage ? widget.message : '',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Text(_lastSelection != null
                          ? 'Last Selected: $_lastSelection'
                          : ''),
                    ],
                  ),
            ),
                  Container(
                    margin: const EdgeInsets.all(15.0),
                    height: 250,
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color.fromARGB(255, 0, 0, 0))
                    ),
                    child: KeyboardWidget(
                          bindings: [
                            KeyAction(LogicalKeyboardKey.keyD, 'Draw a card', () {
//                    debugPrint('test');
                              setState(() {
                                dynamicList.add(DynamicWidget());
                                deckPtr++;
                              });
//                    debugPrint("Length:" + dynamicList.length.toString());
                            })
                          ],
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: dynamicList,
                            )
                          )
                      ),
                  ),
          ],
        ),
      );
  }

  List<MenuEntry> _getMenus() {
    final List<MenuEntry> result = <MenuEntry>[
      MenuEntry(
        label: 'Menu Demo',
        menuChildren: <MenuEntry>[
          MenuEntry(
            label: 'Shortcuts',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'MenuBar Sample',
                applicationVersion: '1.0.0',
              );
              setState(() {
                _lastSelection = 'About';
              });
            },
          ),
          MenuEntry(
              label: 'Import Background Image',
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'MenuBar Sample',
                  applicationVersion: '1.0.0',
                );
              }
          ),
          MenuEntry(label: 'Import Decklist',
          onPressed: () async {
              //await chooseFile();
              await createDeckList();
          })
        ],
      ),
    ];

    return result;
  }

  Future<String> get chooseFile async {
    FilePickerResult? fileResult = await FilePicker.platform.pickFiles();
    
    if( fileResult == null) return "";
    
    PlatformFile file = fileResult.files.single;
    
    print(file.path);
    
    return file.path.toString();
  }

  Future<File> get localFile async {
    final path = await chooseFile;
    return File(path);
  }

  Future<String> readFile() async {
    try {
      final file = await localFile;

      final contents = await file.readAsString();

      return contents;
    } catch (e) {
      return "";
    }
  }

  Future<void> createDeckList() async {
    final deckList = await readFile();
    List<String> cardList = [];
    List<String> cardParameters = [];
    String cardName = "";


      _DynamicWidgetState deckBox = _DynamicWidgetState();
    LineSplitter.split(deckList).forEach((line) => 
    cardList.add(line));

    deck = [];
    

    for(var card in cardList){
      cardParameters = card.split(' ');
      //exclude creating an object for categories
      if(int.tryParse(cardParameters[0]) != null){
        for(var count = 0; count < int.parse(cardParameters[0]); count++){
          for(var count2 = 1; count2 < cardParameters.length; count2++){
            cardName = cardName + cardParameters[count2] + " ";
          }
          
          if(cardName != ""){
            print(cardName);
            //print(cardName.length);
            final mtgCard = await apiClient.getCardByName(cardName);
            print("Mana Cost of card: ${mtgCard.manaCost}");
            print("Image?: ${mtgCard.imageUris}");

            setState(() {
              deckBox.addCard(cardName);
            //  deckBox.addCard(mtgCard.imageUris as String);
            });
            cardName = "";
          }
        }
      }
  }

  }
}

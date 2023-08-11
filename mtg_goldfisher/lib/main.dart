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
List<scry.MtgCard> deck = [];
Key initialKey = GlobalKey();
Map keyImage = {initialKey:"index 0"};


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

//Be able to somehow track each widget and be able to grab the image associated with each
//We need to be able to save the image associated with each card
//We need to be able to save a map of each card's key and the image associated with it
class MtgCard extends StatefulWidget {
  @override
  State<MtgCard> createState() => _MtgCardState();
}

class _MtgCardState extends State<MtgCard> {
  Key objKey = keyImage.keys.toList()[deckPtr];

  void addCard(scry.MtgCard card, int ptr){
    //add card to deck
    deck.add(card);

    //add to map
    final key = GlobalKey();
    keyImage[key] = "http://cards.scryfall.io${card.imageUris!.large.path}";
    //print(card.name);
    print(key);
  }

  //final uri = "http://cards.scryfall.io${deck[deckPtr].imageUris!.large.path}";
  //final uri = "https://cards.scryfall.io/large/front/f/1/f1d9cfce-1507-4cdf-9d58-6ebaf44e72e3.jpg?1562557622";

  

  double elevation = 4.0; 
  double scale = 1.0;
  Offset translate = Offset(0,0);

 


  @override
  Widget build(BuildContext context) {
      return Container(
        margin: EdgeInsets.all(25.0),
  //      key: ValueKey<String>(deck[deckPtr].name),
        //What you drag
        child: Draggable(
          feedback: Container(
            height: 300,
            width: 215,
            decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                  keyImage[objKey]
                  ),
              fit: BoxFit.cover,
              ),
            ),
          ),
          //What you see when you're dragging
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: Container(
              width: 200,
              height: 275,
              decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    keyImage[objKey]
                    ),
                fit: BoxFit.cover,
                ),
              ),
            ),
          ),
         /* child: Container(
              width: 200,
              height: 275,
              decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    "http://cards.scryfall.io${deck[deckPtr].imageUris!.large.path}"
                    ),
                fit: BoxFit.cover,
                ),
              ),
            ),*/
            child: InkWell(
              onTap: (){},
              onHover: (value){
                if(value){
                  print(objKey);
                  print(keyImage[objKey]);
                  print(keyImage.keys.toList()[0]);
               //   print(translate);
                  setState((){
                    elevation = 4.0; 
                    scale = 1.5;
                    translate = Offset(0,-100);
                  });
                }else{
                //  print("Not hovering :(");
               //   print(translate);
                  setState((){
                    elevation = 4.0; 
                    scale = 1.0;
                    translate = Offset(0,0);
                  });
                }
             },
             child: SizedBox(
                width: 200,
                height: 275,
               /* decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                        "http://cards.scryfall.io${deck[deckPtr].imageUris!.large.path}"
                        ),
                    fit: BoxFit.cover,
                    ),
                ),
                child: [
                  
                ]*/
                child: Transform.translate(
                offset: translate,        
                child: Transform.scale(
                  scale: scale,
                  child: Material(        
                    elevation: elevation,        
                    child: Image.network(           
                        keyImage[objKey]
                    ),
                  ),
                ),
              ),
             ),
           ),
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
  List<MtgCard> dynamicList = [];
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
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    height: 350,
                    padding: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color.fromARGB(255, 0, 0, 0))
                    ),
                    child: KeyboardWidget(
                          bindings: [
                            KeyAction(LogicalKeyboardKey.keyD, 'Draw a card', () {
                              if(deck.isNotEmpty){
                                setState(() {
                                dynamicList.add(MtgCard());
                              //  dynamicList.add(DynamicWidget(key: UniqueKey(), ptr: deckPtr));
                                deckPtr++;
                              });
                              } else {
                                print("Please enter decklist");
                              }
                            })
                          ],
                     //     child: Scrollbar(
                      //      thickness: 10, //width of scrollbar
                      //      radius: Radius.circular(20), //corner radius of scrollbar
                         //   scrollbarOrientation: ScrollbarOrientation.left, 
                            child: SingleChildScrollView(
                          //    scrollDirection: Axis.horizontal,
                             // padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                              child: Row(
                               // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: dynamicList,
                              )
                            ),
                        //  )
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


      _MtgCardState deckBox = _MtgCardState();
    LineSplitter.split(deckList).forEach((line) => 
    cardList.add(line));

    deck = [];
    

    for(var card in cardList){
      cardParameters = card.split(' ');
      //exclude creating an object for categories
      if(int.tryParse(cardParameters[0]) != null){
        for(var count = 0; count < int.parse(cardParameters[0]); count++){
          for(var count2 = 1; count2 < cardParameters.length; count2++){
            cardName = "$cardName${cardParameters[count2]} ";
          }
          
          if(cardName != ""){
            final mtgCard = await apiClient.getCardByName(cardName);

            setState(() {
            //  deckBox.addCard(cardName);
              deckBox.addCard(mtgCard, deckPtr);
            });
            cardName = "";
          }
        }
      }
  }

  }
}

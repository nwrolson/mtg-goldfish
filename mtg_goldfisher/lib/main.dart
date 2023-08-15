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

  //Add Card to deck after importing decklist
  void addCard(scry.MtgCard card, int ptr){
    //add card to deck
    deck.add(card);

    //add to map
    final key = GlobalKey();
    keyImage[key] = "http://cards.scryfall.io${card.imageUris!.large.path}";
  }

  double elevation = 4.0; 
  double scale = 1.0;
  Offset translate = Offset(0,0);

  //Dragging
  Offset position = Offset(100,100);
  double _x = 0.0;
  double _y = 0.0;



 


  @override
  Widget build(BuildContext context) {
      return 
         Draggable(
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
            //What you see in original position when you're dragging
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
            //  child: keyImage[objKey],
            //Moveable
            onDragEnd: (dragDetails) {
                setState(() {
                  _x = dragDetails.offset.dx;
                  // if applicable, don't forget offsets like app/status bar
                  _y = dragDetails.offset.dy;
                });
              },
            //What you have in hand - Zoom in
            child: InkWell(
              onTap: (){},
              onHover: (value){
                if(value){
                  setState((){
                    elevation = 4.0; 
                    scale = 1.25;
                    translate = Offset(0,-75);
                  });
                }else{
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
                child: Transform.translate(
                  offset: translate,        
                  child: Transform.scale(
                    scale: scale,
                    child: Material(        
                      elevation: elevation,        
                      child: Image.network(           
                          keyImage[objKey],
                          fit: BoxFit.cover,
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

  //used for scrolling
  final ScrollController _scrollController = ScrollController();

  //used for card drawing
  List<MtgCard> dynamicList = [];
  List<String> cardName = [];

  //for moving card
  Offset _position = Offset(0, 0);
  bool _started = false;

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
        //Menu
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
              //Battlefield
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
              //Hand
              Column(
                children: [
                  Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  height: 400,
                  padding: const EdgeInsets.all(0.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color.fromARGB(255, 0, 0, 0))
                  ),
                  child: KeyboardWidget(
                        bindings: [
                          KeyAction(LogicalKeyboardKey.keyD, 'Draw a card', () {
                            if(deck.isNotEmpty){
                              setState(() {
                              dynamicList.add(MtgCard());
                              deckPtr++;
                            });
                            } else {
                              print("Please enter decklist");
                            }
                          })
                        ],
                        child: Scrollbar(
                          controller:_scrollController,
                          child: ListView.builder(
                            shrinkWrap: false,
                            scrollDirection: Axis.horizontal,
                            controller: _scrollController,
                            itemCount: 1,
                            padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                            itemBuilder: (context, index){
                              return Card(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: dynamicList,       
                                )
                              );
                            }
                          )
                        )
                    ),
                ),
                
              //    )
                ],
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

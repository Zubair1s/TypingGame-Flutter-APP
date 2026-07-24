import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

// ── ENTRY POINT ────────────────────────────────────────────
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    )
  );
}

// ── WORD STATUS (like enum in C++) ─────────────────────────
enum Status { pending, correct, wrong }

// ── WORD CLASS (like struct in C++) ───────────────────────
class Word {
  late String text;
  late Status status;

  Word(String t) {
    text   = t;
    status = Status.pending;
  }
}

// ── THEME CLASS — holds colors for one theme ───────────────
class AppTheme {
  String name;
  Color  background;
  Color  textColor;
  Color  highlight;

AppTheme(String n, Color bg, Color txt, Color hi)
    : name       = n,
      background = bg,
      textColor  = txt,
      highlight  = hi;
}

// ── GAME SCREEN ────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() {
    return _GameState();
  }
}

class _GameState extends State<GameScreen> {

  // ── VARIABLES ───────────────────────────────────────────
  List<String> wordBank = [
    'game', 'would', 'code', 'apple', 'fast', 'clean',
    'change', 'space', 'focus', 'build', 'what', 'play',
    'light', 'speed', 'moon', 'star', 'rain', 'sun',
    'fish', 'jump', 'mouse', 'dark', 'world',
  ];

  

  List<Word> words   = [];
  int  index         = 0;
  
  int  totalTime     = 30;
  int  timeLeft      = 30;
  bool done          = false;
  Timer? timer; //to make the timer value null without it it cant be set null otherwise it needs a value 

  TextEditingController input  = TextEditingController();
  FocusNode             focus  = FocusNode();
  ScrollController      scroll = ScrollController();

  // ── THEME VARIABLES ─────────────────────────────────────
  List<AppTheme> themes = [
    //        name       background          text           highlight
    AppTheme('Dark',   Color(0xFF1A1A2E), Colors.white,   Colors.amber),
    AppTheme('Pink',   Color(0xFFFFB6C1), Colors.black,   Color(0xFF880E4F)),
    AppTheme('Sky',    Color(0xFF87CEEB), Colors.black,   Color(0xFF01579B)),
    AppTheme('Forest', Color(0xFF1B4332), Colors.white,   Color(0xFF95D5B2)),
    AppTheme('Paper',  Color(0xFFF5F0E8), Colors.black,   Color(0xFF6D4C41)),
  ];

  int themeIndex = 0; // which theme is active right now

  // runs once when screen opens (like constructor in C++)
  @override
  void initState() {
    super.initState();
    newGame();
  }

  // ── 1. newGame() — reset everything ───────────────────
  void newGame() {
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }

    input.clear();

    if (scroll.hasClients) { //scroll view exists?
      scroll.jumpTo(0);
    }

    List<Word> freshWords = [];
    for (int i = 0; i < 60; i++) {
      int randomIndex = Random().nextInt(wordBank.length);
      freshWords.add(Word(wordBank[randomIndex]));
    }

    setState(() {
      words    = freshWords;
      index    = 0;
      timeLeft = totalTime;
      done     = false;
    });

    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) { //widget is still active on screen or not comes with the state class
        focus.requestFocus();
      }
    });
  }

  // ── 2. startTimer() — tick every second ───────────────
  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        timeLeft = timeLeft - 1;
        if (timeLeft == 0) {
          timer!.cancel();
          done = true;
        }
      });
    });
  }

  // ── 3. onType() — runs every time user types ──────────
  void onType(String val) {
    if (done == true) {
      return;
    }

    if (timer == null) {
      startTimer();
    }

    if (val.endsWith(' ')) {
      String typed = val.trim();

      setState(() {
        if (typed == words[index].text) {
          words[index].status = Status.correct;
        } else {
          words[index].status = Status.wrong;
        }

        index = index + 1;
        input.clear();

        if (index % 6 == 0) {
          scroll.animateTo(
            scroll.offset + 50,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // ── 6. changeTheme() — go to next theme ───────────────
  void changeTheme() {
    setState(() {
      // add 1, and loop back to 0 after the last theme
      themeIndex = (themeIndex + 1) % themes.length;
    });
  }

  // ── WPM CALCULATION ────────────────────────────────────
  int getWPM() {
    int correctCount = 0;
    for (int i = 0; i < words.length; i++) {
      if (words[i].status == Status.correct) {
        correctCount = correctCount + 1;
      }
    }
    return ((correctCount / totalTime) * 60).round();
  }

  // ── BUILD — draws the whole screen ────────────────────
  @override
  Widget build(BuildContext context) {

    // get current theme colors
    AppTheme theme = themes[themeIndex];

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // TOP BAR — timer on left, buttons on right
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [// Timer display
                  Text('$timeLeft s',style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: theme.highlight,),),
                  // 15 / 30 / 60 selector + theme button
                  Row(children: buildTimeButtons(theme),),
                ],
              ),

              SizedBox(height: 24),

              // Middle: words or results
              Expanded(child: done ? results(theme) : wordArea(theme),),
              // Input box (only shown during game)
              if (done == false)
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: TextField(
                    controller:        input,
                    focusNode:         focus,
                    autofocus:         true,
                    onChanged:         onType,
                    autocorrect:       false,
                    enableSuggestions: false,
                    style: TextStyle(color: theme.textColor, fontSize: 20),
                    
                    decoration: InputDecoration(hintText:  'type here...',hintStyle: TextStyle(color: Colors.grey), filled:true,fillColor: theme.textColor.withOpacity(0.08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: BorderSide.none,),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),borderSide: BorderSide(color: theme.highlight),),),
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }

  // ── builds the 15 / 30 / 60 buttons + theme button ────
  List<Widget> buildTimeButtons(AppTheme theme) {
    List<int> times = [15, 30, 60];
    List<Widget> buttons = [];

    for (int i = 0; i < times.length; i++) {
      int t = times[i];
      bool selected = (t == totalTime);

      Widget btn = GestureDetector(
        onTap: () {
          setState(() {
            totalTime = t;
          });
          newGame();
        },
        child: Container(
              margin: EdgeInsets.only(left: 8),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? theme.highlight : Colors.grey,),
                  color: selected ? theme.highlight.withOpacity(0.15): Colors.transparent,),
                      child: Text('$t', style: TextStyle( color: selected ? theme.highlight : Colors.grey,fontWeight: selected ? FontWeight.bold : FontWeight.normal,),),),
      );
      buttons.add(btn);
    }

    // Theme button — tap to cycle through themes
    Widget themeBtn = GestureDetector(
      onTap: changeTheme,
      child: Container(
        margin: EdgeInsets.only(left: 8),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.highlight),
          color: theme.highlight.withOpacity(0.15),
        ),
        child: Text(theme.name,style: TextStyle(color: theme.highlight,fontWeight: FontWeight.bold,),), // text
      ),
    );

    buttons.add(themeBtn);

    return buttons;
  }

  // ── 4. wordArea() — paragraph of words ────────────────
  Widget wordArea(AppTheme theme) {
    List<Widget> wordWidgets = [];

    for (int i = 0; i < words.length; i++) {
      Color c;
      if (i == index) {
        c = theme.textColor;
      } else if (words[i].status == Status.correct) {
        c = Colors.green;
      } else if (words[i].status == Status.wrong) {
        c = Colors.red;
      } else {
        c = Colors.grey;
      }

      BoxDecoration? decoration;
      if (i == index) {
        decoration = BoxDecoration(border: Border(bottom: BorderSide(color: theme.highlight, width: 2),),);
      }

      Widget wordBox = Container(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: decoration,
        child: Text(
          words[i].text,
          style: TextStyle(
            fontSize: 22,
            color: c,
            fontWeight: i == index ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );

      wordWidgets.add(wordBox);
    }

    return SingleChildScrollView(
      controller: scroll,
      physics: NeverScrollableScrollPhysics(),
      child: Wrap(
        spacing: 8,
        runSpacing: 14,
        children: wordWidgets,
      ),
    );
  }

  // ── 5. results() — WPM + try again button ─────────────
  Widget results(AppTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text('FINISHED',style: TextStyle(color: Colors.grey, letterSpacing: 4),),
          SizedBox(height: 8),

          Text('${getWPM()}',
            style: TextStyle(fontSize: 90,fontWeight: FontWeight.bold,color: theme.highlight,),),
          Text('WPM',style: TextStyle(color: Colors.grey, fontSize: 20),),

          SizedBox(height: 30),

          ElevatedButton(
            onPressed: newGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.highlight,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Try Again',style: TextStyle(color: theme.background,fontSize: 16,fontWeight: FontWeight.bold,),),
          ),
        ],
      ),
    );
  }

  // runs when screen is closed — clean up (like destructor in C++)
  @override
  void dispose() {
    if (timer != null) timer!.cancel();
    input.dispose();
    focus.dispose();
    scroll.dispose();
    super.dispose();
  }
}
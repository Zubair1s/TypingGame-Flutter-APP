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
  late String text;    // 'late' tells Dart: "trust me, it will be set in constructor"
  late Status status;

  Word(String t) {
    text   = t;
    status = Status.pending;
  }
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
  int  index         = 0;   // which word user is on
  int  totalTime     = 30;  // chosen time: 15 / 30 / 60
  int  timeLeft      = 30;  // countdown
  bool done          = false;
  Timer? timer;

  TextEditingController input  = TextEditingController();
  FocusNode             focus  = FocusNode();
  ScrollController      scroll = ScrollController();

  // runs once when screen opens (like constructor in C++)
  @override
  void initState() {
    super.initState();
    newGame();
  }

  // ── 1. newGame() — reset everything ───────────────────
  void newGame() {
    // stop timer if running
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }

    input.clear();

    // reset scroll to top
    if (scroll.hasClients) {
      scroll.jumpTo(0);
    }

    // build 60 random words
    List<Word> freshWords = [];
    for (int i = 0; i < 60; i++) {
      int randomIndex = Random().nextInt(wordBank.length);
      freshWords.add(Word(wordBank[randomIndex]));
    }

    // setState tells Flutter to redraw the screen
    setState(() {
      words    = freshWords;
      index    = 0;
      timeLeft = totalTime;
      done     = false;
    });

    // focus the input field after 300ms (waits for screen to build)
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
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
          timer!.cancel();  // stop so it doesn't go negative
          done = true;
        }
      });
    });
  }

  // ── 3. onType() — runs every time user types ──────────
  void onType(String val) {
    // do nothing if game is over
    if (done == true) {
      return;
    }

    // start timer on very first keystroke
    if (timer == null) {
      startTimer();
    }

    // space pressed = submit word
    if (val.endsWith(' ')) {
      String typed = val.trim(); // remove the space

      setState(() {
        // check if typed word matches current word
        if (typed == words[index].text) {
          words[index].status = Status.correct;
        } else {
          words[index].status = Status.wrong;
        }

        index = index + 1; // move to next word
        input.clear();     // clear input box

        // scroll down every 6 words
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

  // ── WPM CALCULATION ────────────────────────────────────
  // 30s = half a minute, so correct words x2 = per minute
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
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [

              // TOP BAR — timer on left, buttons on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  // Timer display
                  Text(
                    '$timeLeft s',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 238, 232, 215),
                    ),
                  ),

                  // 15 / 30 / 60 selector
                  Row(
                    children: buildTimeButtons(),
                  ),

                ],
              ),

              SizedBox(height: 24),

              // Middle: words or results
              Expanded(
                child: done ? results() : wordArea(),
              ),

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
                    style: TextStyle(color: Colors.white, fontSize: 20),
                    decoration: InputDecoration(
                      hintText:  'type here...',
                      hintStyle: TextStyle(color: Colors.grey),
                      filled:    true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }

  // ── builds the 15 / 30 / 60 buttons ───────────────────
  List<Widget> buildTimeButtons() {
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
            border: Border.all(
              color: selected ? Colors.amber : Colors.grey,
            ),
            color: selected
                ? Colors.amber.withOpacity(0.15)
                : Colors.transparent,
          ),
          child: Text(
            '$t',
            style: TextStyle(
              color: selected ? Colors.amber : Colors.grey,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );

      buttons.add(btn);
    }

    return buttons;
  }

  // ── 4. wordArea() — paragraph of words ────────────────
  Widget wordArea() {
    List<Widget> wordWidgets = [];

    for (int i = 0; i < words.length; i++) {
      // pick color based on status
      Color c;
      if (i == index) {
        c = Colors.white;               // current word
      } else if (words[i].status == Status.correct) {
        c = Colors.greenAccent;         // correct
      } else if (words[i].status == Status.wrong) {
        c = Colors.redAccent;           // wrong
      } else {
        c = Colors.grey;                // not typed yet
      }

      // amber underline on current word
      BoxDecoration? decoration;
      if (i == index) {
        decoration = BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.amber, width: 2),
          ),
        );
      }

      Widget wordBox = Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
  Widget results() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            'FINISHED',
            style: TextStyle(color: Colors.grey, letterSpacing: 4),
          ),

          SizedBox(height: 8),

          Text(
            '${getWPM()}',
            style: TextStyle(
              fontSize: 90,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),

          Text(
            'WPM',
            style: TextStyle(color: Colors.grey, fontSize: 20),
          ),

          SizedBox(height: 30),

          ElevatedButton(
            onPressed: newGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Try Again',style: TextStyle( color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold,),
            ),
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
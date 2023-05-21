import 'dart:convert';

import 'package:hexcolor/hexcolor.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'calculator/buttons.dart';
import 'dart:async';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({Key? key}) : super(key: key);

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

var userQuestion = '';
var userAnswer = '';

void navigateToNewScreen(BuildContext context) {
  // Navigator.push(
  //   context,
  //   MaterialPageRoute(builder: (context) => ()),
  // );
}

final List<String> buttons = [
  'C',
  'DEL',
  '%',
  '/',
  '9',
  '8',
  '7',
  'x',
  '6',
  '5',
  '4',
  '-',
  '3',
  '2',
  '1',
  '+',
  '0',
  '.',
  'News',
  '=',
];

bool isOperator(String x) {
  if (x == '%' ||
      x == 'BTC' ||
      x == '-' ||
      x == '/' ||
      x == 'x' ||
      x == '+' ||
      x == '=') {
    return true;
  }
  return false;
}

bool isBtn(String x) {
  if (x == 'News') {
    return true;
  }
  return false;
}

late Timer _timer;
Map<String, dynamic> _cryptoPriceData = {};

Future<String> fetchBitcoinPrice() async {
  var response = await http.get(Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd'));
  if (response.statusCode == 200) {
    var json = jsonDecode(response.body);
    var price = json['bitcoin']['usd'].toString();
    return '\$' + price;
  } else {
    return 'Error fetching price';
  }
}

class _CalculatorPageState extends State<CalculatorPage> {
  @override
  void initState() {
    super.initState();

    // Set up a timer to refresh the crypto price data every 5 minutes
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchBitcoinPrice();
    });
  }

  @override
  void dispose() {
    super.dispose();
    // Cancel the timer when the widget is disposed to avoid memory leaks
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 8.0, right: 8, top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FutureBuilder<String>(
                              future: fetchBitcoinPrice(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<String> snapshot) {
                                if (snapshot.hasData) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Bitcoin Price: ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        snapshot.data!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  );
                                } else if (snapshot.hasError) {
                                  return const Text(
                                    'Error fetching price',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  );
                                } else {
                                  return const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      color: Colors.orange,
                                      strokeWidth: 2,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            userQuestion,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0, right: 8),
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '= $userAnswer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: GridView.builder(
                  itemCount: buttons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4),
                  itemBuilder: (BuildContext context, int index) {
                    return Buttons(
                      buttontapped: () {
                        setState(() {
                          if (buttons[index] == 'DEL') {
                            // Delete last item added
                            userQuestion = userQuestion.substring(
                                0, userQuestion.length - 1);
                          } else if (buttons[index] == 'C') {
                            // Clear everything
                            userQuestion = '';
                            userAnswer = '';
                          } else if (buttons[index] == 'News') {
                            print('news');
                            navigateToNewScreen(context);
                          } else if (buttons[index] == '=') {
                            // Evaluate userQuestion
                            equalPressed();
                            if (userQuestion.isNotEmpty) {
                              // Evaluate expression
                              // ...
                              // Set userAnswer to result of evaluation
                            } else {
                              userAnswer = 'Clear';
                            }
                          } else {
                            userQuestion += buttons[index];
                          }
                        });
                      },
                      color: isOperator(buttons[index])
                          ? Colors.deepPurpleAccent
                          : isBtn(buttons[index])
                              ? HexColor(
                                  '303136') // Set color to green if button is 'News'
                              : HexColor('303136'),
                      textColor: Colors.white,
                      buttonText: buttons[index],
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void equalPressed() {
    String finalQuestion = userQuestion;
    finalQuestion = finalQuestion.replaceAll('x', '*');
    Parser p = Parser();
    Expression exp = p.parse(finalQuestion);
    ContextModel cm = ContextModel();
    double eval = exp.evaluate(EvaluationType.REAL, cm);
    int resultAsInt = eval.toInt();
    userAnswer = resultAsInt == eval ? '$resultAsInt' : '$eval';
  }
}

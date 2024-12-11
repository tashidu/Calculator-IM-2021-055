//IM/2021/055-Tashidu Vinuka
import 'package:flutter/material.dart';
import 'package:expressions/expressions.dart';
import 'dart:math';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}
//IM/2021/055-Tashidu Vinuka
class _CalculatorScreenState extends State<CalculatorScreen> {
  List<String> _history = []; // List to store calculation history

  final ScrollController _scrollController = ScrollController(); // Controller for scrolling the output

  // Color constants for different button types and text
  static const Color numberButtonColor = Color(0xFFeff0f6);
  static const Color operatorButtonColor = Color(0xffe7f6ff);
  static const Color acButtonColor = Color(0xFFffd2e8);
  static const Color equalsButtonColor = Color.fromARGB(255, 49, 94, 114);
  static const Color textColor = Color(0xFF2b2933);
  static const Color operatorTextColor = Color(0xFF2e4f64);
  static const Color acTextColor = Color(0xFF792b53);
  static const Color backspaceTextColor = Color(0xFFf52c58);
  static const Color errorColor = Color(0xFFf52c58);
  static const Color resultColor = Color(0xFF4c98d5);

  String _output = ''; // Current display output
  String _operationSequence = ''; // Full sequence of input operations
  String _previousSequence = ''; // Previous calculation sequence
  bool _isNewNumber = true; // Flag to track if a new number input is expected
  bool _hasError = false; // Flag to indicate if an error occurred
  bool _isResultDisplayed = false; // Flag to track if result is currently displayed
  bool _canDisplayZero = false; // Track if '0' can be displayed

  void _onNumberPressed(String number) {
    setState(() {
      // Reset state if previous calculation had an error or result is displayed
      if (_hasError || _isResultDisplayed) {
        _output = '';
        _operationSequence = '';
        _isNewNumber = true;
        _hasError = false;
        _isResultDisplayed = false;
      }

      // Handle the case for leading '0' (only allow one leading '0')
      if (number == '0') {
        if (_operationSequence.isEmpty && !_canDisplayZero) {
          _canDisplayZero = true; // Allow a single leading '0'
          return; // Do not display the '0' yet
        } else if (_operationSequence.startsWith('0') && _operationSequence.length == 1) {
          // Prevent entering multiple zeros (i.e., 00, 000, etc.)
          return;
        }
      }

      // If any number from 1-9 is pressed after '0', replace the leading '0'
      if (number != '0' && _canDisplayZero) {
        _operationSequence = ''; // Clear previous '0'
        _canDisplayZero = false; // Reset flag
      }

      // Check if the number is a decimal point
      if (number == '.') {
        // Ensure that only one decimal point exists in the current number
        if (!_operationSequence.contains('.') && _operationSequence.isNotEmpty) {
          // Add decimal point if there's none already in the sequence
          _operationSequence += number;
        } else if (_operationSequence.isEmpty) {
          // If there's nothing entered yet, start with "0."
          _operationSequence = '0.';
        }
      } else {
        // Append the number to the operation sequence (handles all other digits)
        if (_isNewNumber) {
          _operationSequence += number;
          _isNewNumber = false;
        } else {
          _operationSequence += number;
        }
      }

      // Handle negative number input
      if (number == '-') {
        // Allow minus at the start of the sequence or after an operator
        if (_operationSequence.isEmpty || _operationSequence.endsWith(' ')) {
          _operationSequence += '-';
        } else {
          // If it's not at the start, treat '-' as an operator for subtraction
          _onOperationPressed('-');
          return;
        }
      }

      // Limit decimal places to 10
      if (_operationSequence.contains('.')) {
        final parts = _operationSequence.split('.');
        if (parts[1].length > 10) {
          _operationSequence = '${parts[0]}.${parts[1].substring(0, 10)}';
        }
      }

      // Update the output to reflect the current operation sequence
      _output = _operationSequence;
    });

    // Scroll the text input to the right if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  // Decimal button press handler
  void onDecimalPressed() {
    setState(() {
      // If the sequence is empty or only contains the initial zero, treat it as 0. before the decimal.
      if (_operationSequence.isEmpty || _operationSequence == '0') {
        _operationSequence = '0.'; // Automatically prepend '0.' if nothing has been entered.
      }
      // If the sequence is not empty and doesn't contain a decimal point, allow the decimal point.
      else if (!_operationSequence.contains('.')) {
        _operationSequence += '.'; // Add decimal point only if it's not already there.
      }
      if (!_operationSequence.split(' ').last.contains('.')) {
        _operationSequence += '.';
      }
    });
  }

  // Handler for operation button presses (+, -, ×, ÷)
  void _onOperationPressed(String operation) {
    setState(() {
      // Ignore if there's an existing error
      if (_hasError) {
        return;
      }
      // Reset sequence if previous result is displayed
      if (_isResultDisplayed) {
        _operationSequence = _output;
        _isResultDisplayed = false;
      }
      // Check if the last character in the sequence is an operator
      if (_operationSequence.isNotEmpty && _operationSequence.endsWith(' ')) {
        // Replace the last operator with the new one
        _operationSequence = _operationSequence.substring(0, _operationSequence.length - 3) + ' $operation ';
      } else if (_operationSequence.isNotEmpty && !_isNewNumber) {
        // Append new operator if the sequence is not empty and not a new number
        _operationSequence += ' $operation ';
        _isNewNumber = true;
      }
      _output = _operationSequence;
    });
  }

  // Handler for equals button press
  void _onEqualsPressed() {
    setState(() {
      // Ignore if there's an error or no operation sequence
      if (_hasError || _operationSequence.isEmpty) {
        return;
      }
      try {
        // Evaluate the mathematical expression
        final result = _evaluateExpression(_operationSequence);
        _previousSequence = _operationSequence;
        _output = result;
        _isResultDisplayed = true;
        // Add the calculation to history
        _history.add('$_operationSequence = $_output');
      } catch (e) {
        // Display error if calculation fails
        _output = e.toString().replaceFirst('Exception: ', ''); // Remove "Exception: " prefix
        _hasError = true;
      }
    });
  }

  // Method to safely evaluate mathematical expressions
  String _evaluateExpression(String expression) {
    try {
      // Replace calculator symbols with standard math symbols
      final exp = expression.replaceAll('×', '*').replaceAll('÷', '/');
      final parsedExpression = Expression.parse(exp);
      final evaluator = const ExpressionEvaluator();
      final result = evaluator.eval(parsedExpression, {});

      // Check for division by zero
      if (result.isNaN || result == double.infinity || result == double.negativeInfinity) {
        throw 'Can\'t divide by zero'; // Throw exact error message
      }

      // Return integer if whole number, otherwise return decimal
      return result % 1 == 0 ? result.toInt().toString() : result.toString();
    } catch (e) {
      // Catch other errors and throw a generic "Invalid calculation" message
      if (e.toString() == 'Can\'t divide by zero') {
        rethrow;
      } else {
        throw 'Invalid calculation'; // Throw exact error message
      }
    }
  }

  // Handler for clear button press
  void _onClearPressed() {
    setState(() {
      // Reset all state variables
      _output = '';
      _operationSequence = '';
      _previousSequence = '';
      _isNewNumber = true;
      _hasError = false;
      _isResultDisplayed = false;
    });
  }
//IM/2021/055-Tashidu Vinuka
  // Show history dialog
  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('History'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _history.isEmpty
                  ? [Text('No history available')]
                  : _history.map((item) => Text(item)).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Clear History'),
              onPressed: () {
                setState(() {
                  _history.clear();
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Build history button
  Widget _buildHistoryButton() {
    return IconButton(
      icon: Icon(Icons.history),
      onPressed: _showHistoryDialog,
    );
  }

  // Handler for backspace button press
  void _onBackspacePressed() {
    setState(() {
      // Handle backspace differently for result and operation sequence
      if (_isResultDisplayed) {
        if (_output.isNotEmpty) {
          _output = _output.substring(0, _output.length - 1);
        }
        if (_output.isEmpty) {
          _previousSequence = '';
          _isResultDisplayed = false;
        }
      } else if (_operationSequence.isNotEmpty) {
        _operationSequence =
            _operationSequence.substring(0, _operationSequence.length - 1);
        _output = _operationSequence;
      }
    });
  }

// Handler for square root button press
void _onSquareRootPressed() {
  setState(() {
    // Check if there is any number in the operation sequence
    if (_operationSequence.isNotEmpty) {
      // Parse the number from the operation sequence
      double number = double.tryParse(_operationSequence) ?? 0;

      // Check if the number is negative
      if (number < 0) {
        _output = 'Invalid input: Negative number'; // Show error message for negative numbers
        _hasError = true;
      } else {
        // Calculate the square root of the number and update the output
        _operationSequence = sqrt(number).toString();
        _output = _operationSequence; // Display the result
        _isResultDisplayed = true;
      }
    } else {
      // If no number is entered, show an error message
      _output = 'Invalid input: No number entered';
      _hasError = true;
    }
  });
}

  // Handler for percentage button press
  void _onPercentagePressed() {
    setState(() {
      if (_operationSequence.isNotEmpty) {
        // Ignore if last character is a space (after an operator)
        if (_operationSequence.endsWith(' ')) {
          return;
        }
        final lastNumber = _operationSequence.split(' ').last;
        // Convert last number to percentage
        final percentage = (double.parse(lastNumber) / 100).toString();
        _operationSequence = _operationSequence.substring(
            0, _operationSequence.length - lastNumber.length) +
            percentage;
        _output = _operationSequence;
      }
    });
  }

  // Custom button builder with configurable colors and behavior
  Widget _buildButton(
      String text, {
        Color backgroundColor = numberButtonColor,
        Color textColor = textColor,
      }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          // Button styling with subtle shadow
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: MaterialButton(
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            // Route button press to appropriate handler
            onPressed: () {
              if (text == 'C') {
                _onClearPressed();
              } else if (text == '⌫') {
                _onBackspacePressed();
              } else if (text == 'AC') {
                _onClearPressed();
              } else if (text == '√') {
                _onSquareRootPressed();
              } else if (text == '%') {
                _onPercentagePressed();
              } else if (text == '=') {
                _onEqualsPressed();
              } else if ('+-×÷'.contains(text)) {
                _onOperationPressed(text);
              } else {
                _onNumberPressed(text);
              }
            },
            child: Text(
              text,
              style: TextStyle(
                fontSize: 24,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        leading: _buildHistoryButton(),
      ),
      backgroundColor: const Color.fromARGB(255, 151, 147, 147),
      body: Container(
        // Soft gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F9FE), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App title
              Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.03,
                    bottom: MediaQuery.of(context).size.height * 0.01,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Previous calculation sequence
                      Text(
                        _previousSequence,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF494949),
                        ),
                        overflow: TextOverflow.ellipsis, // Handle overflow
                        maxLines: 1, // Single line display
                      ),
                      // Current output with dynamic font size and horizontal scrolling
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double fontSize = constraints.maxWidth * 0.15; // Default font size as a percentage of screen width

                          // If text is too long, reduce the font size (making it smaller three times)
                          if (_output.length > 10) {
                            fontSize = constraints.maxWidth * 0.12; // First reduction
                          }
                          if (_output.length > 20) {
                            fontSize = constraints.maxWidth * 0.10; // Second reduction
                          }
                          if (_output.length > 30) {
                            fontSize = constraints.maxWidth * 0.08; // Third reduction
                          }

                          return SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end, // Ensure the text is aligned to the right
                              children: [
                                Text(
                                  _output,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w600,
                                    color: _hasError
                                        ? errorColor
                                        : (_isResultDisplayed ? resultColor : Color(0xFF494949)),
                                  ),
                                  overflow: TextOverflow.ellipsis, // Truncate if overflow
                                  maxLines: 1, // Keep it in a single line
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Calculator buttons layout
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Button rows with various operations and numbers
                    Row(
                      children: [
                        _buildButton('√',
                            backgroundColor: operatorButtonColor,
                            textColor: operatorTextColor),
                        _buildButton('%'),
                        _buildButton('⌫',
                            backgroundColor: numberButtonColor,
                            textColor: backspaceTextColor),
                        _buildButton('÷',
                            backgroundColor: operatorButtonColor,
                            textColor: operatorTextColor),
                      ],
                    ),
                    // Numeric and operator buttons
                    Row(children: [
                      _buildButton('1'),
                      _buildButton('2'),
                      _buildButton('3'),
                      _buildButton('×',
                          backgroundColor: operatorButtonColor,
                          textColor: operatorTextColor),
                    ]),
                    Row(children: [
                      _buildButton('4'),
                      _buildButton('5'),
                      _buildButton('6'),
                      _buildButton('-',
                          backgroundColor: operatorButtonColor,
                          textColor: operatorTextColor),
                    ]),
                    Row(children: [
                      _buildButton('7'),
                      _buildButton('8'),
                      _buildButton('9'),
                      _buildButton('+',
                          backgroundColor: operatorButtonColor,
                          textColor: operatorTextColor),
                    ]),
                    Row(children: [
                      _buildButton('.'),
                      _buildButton('0'),
                      _buildButton('AC',
                          backgroundColor: const Color.fromARGB(255, 242, 206, 223),
                          textColor: const Color.fromARGB(255, 231, 80, 60)),
                      _buildButton('=',
                          backgroundColor: const Color.fromARGB(255, 16, 53, 121),
                          textColor: Colors.white),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//IM/2021/055-Tashidu Vinuka  
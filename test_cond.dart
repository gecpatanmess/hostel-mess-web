void main() {
  String existingPin = 'ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f';
  String typedPin = '12345678';
  String hashedTypedPin = 'ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f';

  if (existingPin != typedPin && existingPin != hashedTypedPin) {
    print('WRONG PASSWORD TRIGGERED');
  } else {
    print('SUCCESS');
  }
}

import 'package:flutter/material.dart';

Widget testWidget() {
  return Container(
    child: Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, idx) {
              return Container();
            }
          )
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             Column(
               children: [
                 const Text("Export Month:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                 Container()
               ]
             ),
             Column(
               children: [
                 const Text("Export Year:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                 Container()
               ]
             )
          ]
        ),
        const SizedBox(height: 10),
      ]
    )
  );
}

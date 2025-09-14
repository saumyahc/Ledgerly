import 'package:flutter/material.dart';
import '../models/bet.dart';
import 'package:google_fonts/google_fonts.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final BetChallenge challenge;
  ChallengeDetailScreen({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.title, style: GoogleFonts.poppins()),
        backgroundColor: Color(0xFF6A5AE0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(challenge.description,
                style: GoogleFonts.poppins(fontSize: 16)),
            SizedBox(height: 16),
            Text("Participants", style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 18)),
            Expanded(
              child: ListView.builder(
                itemCount: challenge.participants.length,
                itemBuilder: (context, index) {
                  final p = challenge.participants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFF6A5AE0),
                      child: Text(p.name[0], style: TextStyle(color: Colors.white)),
                    ),
                    title: Text(p.name, style: GoogleFonts.poppins()),
                    subtitle: LinearProgressIndicator(
                      value: p.progress / 20, // assume target is 20 for demo
                      backgroundColor: Colors.grey[300],
                      color: Color(0xFF6A5AE0),
                    ),
                    trailing: Text("${p.progress} km",
                        style: GoogleFonts.poppins()),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // join challenge later
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A5AE0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Join Challenge", style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}

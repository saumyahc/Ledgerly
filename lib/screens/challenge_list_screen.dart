import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/blockchain_service.dart';
import '../models/bet.dart';
import 'challenge_detail_screen.dart';
import 'create_challenge_screen.dart';

class ChallengeListScreen extends StatefulWidget {
  @override
  _ChallengeListScreenState createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen> {
  final BlockchainService _service = BlockchainService();
  late Future<List<BetChallenge>> _challenges;

  @override
  void initState() {
    super.initState();
    _challenges = _service.fetchChallenges();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFF6A5AE0),
        title: Text(
          "Fitness Bets",
          style: GoogleFonts.poppins(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<BetChallenge>>(
        future: _challenges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No challenges yet. Create one!",
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            );
          }

          final challenges = snapshot.data!;
          return ListView.builder(
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final c = challenges[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChallengeDetailScreen(challenge: c),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          c.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Stake: \$${c.stake}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "Ends: ${c.endDate.day}/${c.endDate.month}/${c.endDate.year}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF6A5AE0),
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateChallengeScreen()),
          );
          if (created == true) {
            setState(() {
              _challenges = _service.fetchChallenges(); // refresh list
            });
          }
        },
      ),
    );
  }
}

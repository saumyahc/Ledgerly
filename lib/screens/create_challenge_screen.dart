import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../models/friend.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateChallengeScreen extends StatefulWidget {
  @override
  _CreateChallengeScreenState createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _stakeController = TextEditingController();
  DateTime? _endDate;
  List<Friend> _friends = [];

  @override
  void initState() {
    super.initState();
    FriendService().fetchFriends().then((list) {
      setState(() => _friends = list);
    });
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) setState(() => _endDate = date);
  }

  void _createChallenge() {
    // For now, just print (later send to blockchain API)
    final invited = _friends.where((f) => f.invited).map((f) => f.name).toList();
    print("New Challenge: ${_titleController.text}, invited: $invited");
    Navigator.pop(context, true); // go back after creation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Challenge", style: GoogleFonts.poppins()),
        backgroundColor: Color(0xFF6A5AE0),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: _descController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            TextField(
              controller: _stakeController,
              decoration: InputDecoration(labelText: "Stake (e.g. 50)"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickDate,
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6A5AE0)),
                  child: Text("Pick End Date"),
                ),
                SizedBox(width: 12),
                if (_endDate != null)
                  Text("${_endDate!.day}/${_endDate!.month}/${_endDate!.year}",
                      style: GoogleFonts.poppins()),
              ],
            ),
            SizedBox(height: 24),
            Text("Invite Friends", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final f = _friends[index];
                return CheckboxListTile(
                  title: Text(f.name, style: GoogleFonts.poppins()),
                  value: f.invited,
                  onChanged: (val) {
                    setState(() => f.invited = val ?? false);
                  },
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A5AE0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Create", style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}

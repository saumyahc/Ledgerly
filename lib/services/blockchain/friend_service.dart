import '../models/friend.dart';

class FriendService {
  Future<List<Friend>> fetchFriends() async {
    // Mock data for now - replace with actual API call
    return [
      Friend(id: '1', name: 'Alice Johnson'),
      Friend(id: '2', name: 'Bob Smith'),
      Friend(id: '3', name: 'Charlie Brown'),
      Friend(id: '4', name: 'Diana Prince'),
    ];
  }
}

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/ticket.dart';

/// Issue management / society services state.
class TicketProvider extends ChangeNotifier {
  final List<ServiceTicket> _tickets = MockData.demoTickets();
  final List<BroadcastNotice> _broadcasts = MockData.demoBroadcasts();

  List<ServiceTicket> get tickets => List.unmodifiable(
    _tickets..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  List<BroadcastNotice> get broadcasts => List.unmodifiable(
    _broadcasts..sort((a, b) => b.postedAt.compareTo(a.postedAt)),
  );

  void addTicket(ServiceTicket ticket) {
    _tickets.insert(0, ticket);
    notifyListeners();
  }

  void updateStatus(ServiceTicket ticket, TicketStatus status) {
    ticket.status = status;
    notifyListeners();
  }

  void addBroadcast(BroadcastNotice notice) {
    _broadcasts.insert(0, notice);
    notifyListeners();
  }
}

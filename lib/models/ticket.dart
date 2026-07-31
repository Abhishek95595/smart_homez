enum TicketStatus { open, inProgress, resolved, closed }

enum TicketCategory { electrical, plumbing, security, cleaning, device, other }

extension TicketStatusX on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }
}

extension TicketCategoryX on TicketCategory {
  String get label {
    switch (this) {
      case TicketCategory.electrical:
        return 'Electrical';
      case TicketCategory.plumbing:
        return 'Plumbing';
      case TicketCategory.security:
        return 'Security';
      case TicketCategory.cleaning:
        return 'Cleaning';
      case TicketCategory.device:
        return 'Device Issue';
      case TicketCategory.other:
        return 'Other';
    }
  }
}

class ServiceTicket {
  final String id;
  final String title;
  final String description;
  final TicketCategory category;
  TicketStatus status;
  final String raisedBy;
  final String location;
  final DateTime createdAt;
  String? assignedTo;

  ServiceTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.status = TicketStatus.open,
    required this.raisedBy,
    required this.location,
    required this.createdAt,
    this.assignedTo,
  });
}

class BroadcastNotice {
  final String id;
  final String title;
  final String message;
  final DateTime postedAt;
  final String postedBy;

  const BroadcastNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.postedAt,
    required this.postedBy,
  });
}

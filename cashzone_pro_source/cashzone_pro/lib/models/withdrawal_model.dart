// ============================================================
//  withdrawal_model.dart  –  Withdrawal request data model
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum WithdrawalStatus { pending, approved, rejected }
enum PaymentMethod { jazzcash, easypaisa, bankTransfer, upi, paytm }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.jazzcash:     return 'JazzCash';
      case PaymentMethod.easypaisa:    return 'EasyPaisa';
      case PaymentMethod.bankTransfer: return 'Bank Transfer';
      case PaymentMethod.upi:          return 'UPI';
      case PaymentMethod.paytm:        return 'Paytm';
    }
  }
  String get icon {
    switch (this) {
      case PaymentMethod.jazzcash:     return '📱';
      case PaymentMethod.easypaisa:    return '💚';
      case PaymentMethod.bankTransfer: return '🏦';
      case PaymentMethod.upi:          return '💳';
      case PaymentMethod.paytm:        return '🔵';
    }
  }
}

class WithdrawalModel {
  final String id;
  final String userId;
  final String userEmail;
  final double amountPKR;     // PKR amount requested
  final int coinsDeducted;    // coins removed from user
  final PaymentMethod method;
  final String accountNumber;
  final String accountTitle;
  final WithdrawalStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? adminNote;    // admin can add note on reject

  const WithdrawalModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.amountPKR,
    required this.coinsDeducted,
    required this.method,
    required this.accountNumber,
    required this.accountTitle,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.adminNote,
  });

  factory WithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WithdrawalModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      userEmail: d['userEmail'] ?? '',
      amountPKR: (d['amountPKR'] ?? 0).toDouble(),
      coinsDeducted: (d['coinsDeducted'] ?? 0).toInt(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == d['method'], orElse: () => PaymentMethod.jazzcash),
      accountNumber: d['accountNumber'] ?? '',
      accountTitle: d['accountTitle'] ?? '',
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == d['status'], orElse: () => WithdrawalStatus.pending),
      requestedAt: (d['requestedAt'] as Timestamp).toDate(),
      processedAt: (d['processedAt'] as Timestamp?)?.toDate(),
      adminNote: d['adminNote'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userEmail': userEmail,
    'amountPKR': amountPKR,
    'coinsDeducted': coinsDeducted,
    'method': method.name,
    'accountNumber': accountNumber,
    'accountTitle': accountTitle,
    'status': status.name,
    'requestedAt': Timestamp.fromDate(requestedAt),
    'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    'adminNote': adminNote,
  };

  String get statusEmoji {
    switch (status) {
      case WithdrawalStatus.pending:  return '⏳';
      case WithdrawalStatus.approved: return '✅';
      case WithdrawalStatus.rejected: return '❌';
    }
  }
}

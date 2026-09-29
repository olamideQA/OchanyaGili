import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ochanya_gili/features/quotations/domain/models/quote.dart';

class QuotationsRepository {
  final SupabaseClient _client;

  QuotationsRepository(this._client);

  /// Fetch all quote versions for a custom request
  Future<List<Quote>> getQuotesForRequest(String customRequestId) async {
    try {
      final res = await _client
          .from('quotes')
          .select('*, quote_items(*)')
          .eq('custom_request_id', customRequestId)
          .order('version', ascending: false);

      final list = res as List<dynamic>;
      return list.map((e) => Quote.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get the active/latest quote for a custom request
  Future<Quote?> getLatestQuote(String customRequestId) async {
    try {
      final res = await _client
          .from('quotes')
          .select('*, quote_items(*)')
          .eq('custom_request_id', customRequestId)
          .order('version', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res == null) return null;
      return Quote.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Designer builds and issues an itemized quotation
  Future<Quote> createQuote({
    required String customRequestId,
    required List<({String description, int quantity, double unitPrice})> lineItems,
    double depositPercentage = 50.0,
    DateTime? validUntil,
    String? notes,
    String? createdBy,
  }) async {
    // 1. Determine next version number
    final existing = await getQuotesForRequest(customRequestId);
    final nextVersion = existing.isEmpty ? 1 : existing.first.version + 1;

    // 2. Calculate authoritative totals
    final subtotal = lineItems.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
    final total = subtotal;
    final depositAmount = (total * (depositPercentage / 100.0));
    final balanceAmount = total - depositAmount;

    // 3. Insert quote header
    final quoteRes = await _client
        .from('quotes')
        .insert({
          'custom_request_id': customRequestId,
          'version': nextVersion,
          'subtotal': subtotal,
          'total': total,
          'deposit_percentage': depositPercentage,
          'deposit_amount': depositAmount,
          'balance_amount': balanceAmount,
          'status': 'sent',
          'valid_until': validUntil?.toIso8601String(),
          'notes': notes,
          'created_by': createdBy,
        })
        .select()
        .single();

    final quoteId = quoteRes['id'] as String;

    // 4. Insert quote items
    for (int i = 0; i < lineItems.length; i++) {
      final item = lineItems[i];
      await _client.from('quote_items').insert({
        'quote_id': quoteId,
        'description': item.description,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'total_price': item.quantity * item.unitPrice,
        'sort_order': i,
      });
    }

    // 5. Update custom request status to 'quote_sent'
    await _client.from('custom_requests').update({
      'status': 'quote_sent',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', customRequestId);

    return (await getLatestQuote(customRequestId))!;
  }

  /// Customer accepts quote -> sets custom request to 'customer_approved'
  Future<void> acceptQuote(String quoteId, String customRequestId) async {
    await _client.from('quotes').update({
      'status': 'accepted',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', quoteId);

    await _client.from('custom_requests').update({
      'status': 'customer_approved',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', customRequestId);
  }

  /// Customer requests changes -> sets custom request to 'design_discussion'
  Future<void> requestChanges(
    String quoteId,
    String customRequestId,
    String clientFeedback,
  ) async {
    await _client.from('quotes').update({
      'status': 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', quoteId);

    await _client.from('custom_requests').update({
      'status': 'design_discussion',
      'designer_notes': 'Client requested quote revisions: $clientFeedback',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', customRequestId);
  }

  /// Settle deposit payment using server-side RPC
  Future<Map<String, dynamic>> settleDepositPayment({
    required String customRequestId,
    required String quoteId,
    required String paymentReference,
    required double amountPaid,
  }) async {
    final res = await _client.rpc('settle_custom_request_deposit', params: {
      'p_custom_request_id': customRequestId,
      'p_quote_id': quoteId,
      'p_payment_reference': paymentReference,
      'p_amount_paid': amountPaid,
    });

    return Map<String, dynamic>.from(res as Map);
  }
}

final quotationsRepositoryProvider = Provider<QuotationsRepository>((ref) {
  return QuotationsRepository(Supabase.instance.client);
});

final latestQuoteProvider =
    FutureProvider.family<Quote?, String>((ref, customRequestId) {
  return ref.watch(quotationsRepositoryProvider).getLatestQuote(customRequestId);
});

import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/quotations/domain/models/quote.dart';
import 'package:ochanya_gili/features/custom_atelier/domain/models/custom_request.dart';

void main() {
  group('QuoteStatus', () {
    test('fromString maps all database values correctly', () {
      expect(QuoteStatus.fromString('draft'), QuoteStatus.draft);
      expect(QuoteStatus.fromString('sent'), QuoteStatus.sent);
      expect(QuoteStatus.fromString('accepted'), QuoteStatus.accepted);
      expect(QuoteStatus.fromString('rejected'), QuoteStatus.rejected);
      expect(QuoteStatus.fromString('revised'), QuoteStatus.revised);
      expect(QuoteStatus.fromString('expired'), QuoteStatus.expired);
    });

    test('fromString returns draft for unknown values', () {
      expect(QuoteStatus.fromString('unknown'), QuoteStatus.draft);
      expect(QuoteStatus.fromString(''), QuoteStatus.draft);
      expect(QuoteStatus.fromString('foo'), QuoteStatus.draft);
    });

    test('toJson returns correct snake_case strings', () {
      expect(QuoteStatus.draft.toJson(), 'draft');
      expect(QuoteStatus.sent.toJson(), 'sent');
      expect(QuoteStatus.accepted.toJson(), 'accepted');
      expect(QuoteStatus.rejected.toJson(), 'rejected');
      expect(QuoteStatus.revised.toJson(), 'revised');
      expect(QuoteStatus.expired.toJson(), 'expired');
    });

    test('displayName returns human-readable labels', () {
      expect(QuoteStatus.draft.displayName, 'Draft');
      expect(QuoteStatus.sent.displayName, 'Sent to Client');
      expect(QuoteStatus.accepted.displayName, 'Accepted');
      expect(QuoteStatus.rejected.displayName, 'Changes Requested');
      expect(QuoteStatus.revised.displayName, 'Revised');
      expect(QuoteStatus.expired.displayName, 'Expired');
    });
  });

  group('QuoteItem', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'item-001',
        'quote_id': 'quote-001',
        'description': 'Base Pattern Drafting',
        'quantity': 1,
        'unit_price': 280000.0,
        'total_price': 280000.0,
        'sort_order': 0,
      };

      final item = QuoteItem.fromJson(json);
      expect(item.id, 'item-001');
      expect(item.quoteId, 'quote-001');
      expect(item.description, 'Base Pattern Drafting');
      expect(item.quantity, 1);
      expect(item.unitPrice, 280000.0);
      expect(item.totalPrice, 280000.0);
      expect(item.sortOrder, 0);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = <String, dynamic>{
        'description': 'Fabric Allocation',
        'unit_price': 120000.0,
        'total_price': 120000.0,
      };

      final item = QuoteItem.fromJson(json);
      expect(item.id, '');
      expect(item.quoteId, '');
      expect(item.quantity, 1);
      expect(item.sortOrder, 0);
    });

    test('toJson serializes with id', () {
      const item = QuoteItem(
        id: 'item-001',
        quoteId: 'quote-001',
        description: 'Embellishment',
        quantity: 2,
        unitPrice: 85000.0,
        totalPrice: 170000.0,
        sortOrder: 1,
      );

      final json = item.toJson();
      expect(json['id'], 'item-001');
      expect(json['quote_id'], 'quote-001');
      expect(json['description'], 'Embellishment');
      expect(json['quantity'], 2);
      expect(json['unit_price'], 85000.0);
      expect(json['total_price'], 170000.0);
      expect(json['sort_order'], 1);
    });

    test('toJson omits id when includeId is false', () {
      const item = QuoteItem(
        id: 'item-001',
        quoteId: 'quote-001',
        description: 'Tailoring',
        unitPrice: 50000.0,
        totalPrice: 50000.0,
      );

      final json = item.toJson(includeId: false);
      expect(json.containsKey('id'), isFalse);
    });
  });

  group('Quote', () {
    final sampleQuoteJson = {
      'id': 'quote-001',
      'custom_request_id': 'cr-001',
      'version': 1,
      'subtotal': 485000.0,
      'total': 485000.0,
      'deposit_percentage': 50.0,
      'deposit_amount': 242500.0,
      'balance_amount': 242500.0,
      'status': 'sent',
      'valid_until': '2026-10-15T00:00:00.000Z',
      'notes': 'Estimated 6-week turnaround.',
      'created_by': 'designer-001',
      'created_at': '2026-09-29T01:00:00.000Z',
      'updated_at': '2026-09-29T01:00:00.000Z',
      'quote_items': [
        {
          'id': 'item-001',
          'quote_id': 'quote-001',
          'description': 'Base Pattern Drafting',
          'quantity': 1,
          'unit_price': 280000.0,
          'total_price': 280000.0,
          'sort_order': 0,
        },
        {
          'id': 'item-002',
          'quote_id': 'quote-001',
          'description': 'Fabric Allocation',
          'quantity': 1,
          'unit_price': 120000.0,
          'total_price': 120000.0,
          'sort_order': 1,
        },
        {
          'id': 'item-003',
          'quote_id': 'quote-001',
          'description': 'Embellishment',
          'quantity': 1,
          'unit_price': 85000.0,
          'total_price': 85000.0,
          'sort_order': 2,
        },
      ],
    };

    test('fromJson parses all fields including embedded items', () {
      final quote = Quote.fromJson(sampleQuoteJson);

      expect(quote.id, 'quote-001');
      expect(quote.customRequestId, 'cr-001');
      expect(quote.version, 1);
      expect(quote.subtotal, 485000.0);
      expect(quote.total, 485000.0);
      expect(quote.depositPercentage, 50.0);
      expect(quote.depositAmount, 242500.0);
      expect(quote.balanceAmount, 242500.0);
      expect(quote.status, QuoteStatus.sent);
      expect(quote.notes, 'Estimated 6-week turnaround.');
      expect(quote.createdBy, 'designer-001');
      expect(quote.items.length, 3);
      expect(quote.items[0].description, 'Base Pattern Drafting');
      expect(quote.items[1].description, 'Fabric Allocation');
      expect(quote.items[2].description, 'Embellishment');
    });

    test('fromJson handles empty quote_items', () {
      final json = {
        'id': 'quote-002',
        'custom_request_id': 'cr-002',
        'subtotal': 100000.0,
        'total': 100000.0,
        'deposit_amount': 50000.0,
        'balance_amount': 50000.0,
        'status': 'draft',
      };

      final quote = Quote.fromJson(json);
      expect(quote.items, isEmpty);
      expect(quote.status, QuoteStatus.draft);
    });

    test('isAccepted returns true only for accepted status', () {
      final accepted = Quote.fromJson({...sampleQuoteJson, 'status': 'accepted'});
      final sent = Quote.fromJson({...sampleQuoteJson, 'status': 'sent'});
      final draft = Quote.fromJson({...sampleQuoteJson, 'status': 'draft'});

      expect(accepted.isAccepted, isTrue);
      expect(sent.isAccepted, isFalse);
      expect(draft.isAccepted, isFalse);
    });

    test('canBeAccepted returns true only for sent status', () {
      final sent = Quote.fromJson({...sampleQuoteJson, 'status': 'sent'});
      final accepted = Quote.fromJson({...sampleQuoteJson, 'status': 'accepted'});
      final draft = Quote.fromJson({...sampleQuoteJson, 'status': 'draft'});

      expect(sent.canBeAccepted, isTrue);
      expect(accepted.canBeAccepted, isFalse);
      expect(draft.canBeAccepted, isFalse);
    });

    test('toJson serializes correctly', () {
      final quote = Quote.fromJson(sampleQuoteJson);
      final json = quote.toJson();

      expect(json['custom_request_id'], 'cr-001');
      expect(json['version'], 1);
      expect(json['subtotal'], 485000.0);
      expect(json['total'], 485000.0);
      expect(json['deposit_percentage'], 50.0);
      expect(json['deposit_amount'], 242500.0);
      expect(json['balance_amount'], 242500.0);
      expect(json['status'], 'sent');
    });

    test('toJson omits id when includeId is false', () {
      final quote = Quote.fromJson(sampleQuoteJson);
      final json = quote.toJson(includeId: false);
      expect(json.containsKey('id'), isFalse);
    });
  });

  group('Quote deposit calculation verification', () {
    Quote makeQuote(double subtotal, double depositPct) {
      final depositAmt = subtotal * (depositPct / 100.0);
      final balanceAmt = subtotal - depositAmt;
      return Quote(
        id: 'q-calc',
        customRequestId: 'cr-calc',
        subtotal: subtotal,
        total: subtotal,
        depositPercentage: depositPct,
        depositAmount: depositAmt,
        balanceAmount: balanceAmt,
      );
    }

    test('50% deposit: 485000 -> 242500 deposit, 242500 balance', () {
      final q = makeQuote(485000, 50);
      expect(q.depositAmount, 242500.0);
      expect(q.balanceAmount, 242500.0);
    });

    test('30% deposit: 485000 -> 145500 deposit, 339500 balance', () {
      final q = makeQuote(485000, 30);
      expect(q.depositAmount, 145500.0);
      expect(q.balanceAmount, 339500.0);
    });

    test('70% deposit: 485000 -> 339500 deposit, 145500 balance', () {
      final q = makeQuote(485000, 70);
      expect(q.depositAmount, 339500.0);
      expect(q.balanceAmount, 145500.0);
    });

    test('100% deposit: 485000 -> 485000 deposit, 0 balance', () {
      final q = makeQuote(485000, 100);
      expect(q.depositAmount, 485000.0);
      expect(q.balanceAmount, 0.0);
    });
  });

  group('Quote versioning', () {
    test('version 1 quote parses correctly', () {
      final q = Quote.fromJson({
        'id': 'q-v1',
        'custom_request_id': 'cr-001',
        'version': 1,
        'subtotal': 300000.0,
        'total': 300000.0,
        'deposit_amount': 150000.0,
        'balance_amount': 150000.0,
        'status': 'sent',
      });
      expect(q.version, 1);
    });

    test('version 2 quote parses correctly', () {
      final q = Quote.fromJson({
        'id': 'q-v2',
        'custom_request_id': 'cr-001',
        'version': 2,
        'subtotal': 350000.0,
        'total': 350000.0,
        'deposit_amount': 175000.0,
        'balance_amount': 175000.0,
        'status': 'sent',
      });
      expect(q.version, 2);
    });
  });

  group('CustomRequestStatus quotation flow statuses', () {
    test('quote_sent maps to CustomRequestStatus.quoteSent', () {
      expect(CustomRequestStatus.fromString('quote_sent'),
          CustomRequestStatus.quoteSent);
    });

    test('customer_approved maps to CustomRequestStatus.customerApproved', () {
      expect(CustomRequestStatus.fromString('customer_approved'),
          CustomRequestStatus.customerApproved);
    });

    test('quoteSent displayName is Quote Sent', () {
      expect(CustomRequestStatus.quoteSent.displayName, 'Quote Sent');
    });

    test('customerApproved displayName is Customer Approved', () {
      expect(
          CustomRequestStatus.customerApproved.displayName, 'Customer Approved');
    });

    test('quoteSent toJson returns quote_sent', () {
      expect(CustomRequestStatus.quoteSent.toJson(), 'quote_sent');
    });

    test('customerApproved toJson returns customer_approved', () {
      expect(CustomRequestStatus.customerApproved.toJson(), 'customer_approved');
    });
  });
}

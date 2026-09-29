import 'package:flutter_test/flutter_test.dart';
import 'package:ochanya_gili/features/orders/domain/models/order.dart';

void main() {
  group('Loop 5: Order System & Timeline Tests', () {
    test('OrderStatus properties correctly classify lifecycle states', () {
      expect(OrderStatus.pendingPayment.isActive, isTrue);
      expect(OrderStatus.paid.isActive, isTrue);
      expect(OrderStatus.inProduction.isActive, isTrue);
      expect(OrderStatus.readyForFitting.isActive, isTrue);
      expect(OrderStatus.shipped.isActive, isTrue);

      expect(OrderStatus.delivered.isActive, isFalse);
      expect(OrderStatus.delivered.isCompleted, isTrue);

      expect(OrderStatus.cancelled.isActive, isFalse);
      expect(OrderStatus.cancelled.isCancelled, isTrue);
      expect(OrderStatus.refunded.isCancelled, isTrue);
    });

    test('OrderStatus stageNumber maps directly to the 6 atelier milestones', () {
      expect(OrderStatus.pendingPayment.stageNumber, 1);
      expect(OrderStatus.paid.stageNumber, 1);
      expect(OrderStatus.confirmed.stageNumber, 1);
      expect(OrderStatus.processing.stageNumber, 2);
      expect(OrderStatus.inProduction.stageNumber, 3);
      expect(OrderStatus.readyForFitting.stageNumber, 4);
      expect(OrderStatus.readyForDelivery.stageNumber, 4);
      expect(OrderStatus.shipped.stageNumber, 5);
      expect(OrderStatus.delivered.stageNumber, 6);
      expect(OrderStatus.cancelled.stageNumber, 0);
    });

    test('AtelierTimelineStage.buildStages calculates stages and attaches history notes', () {
      final t1 = DateTime(2026, 9, 29, 10, 0);
      final t2 = DateTime(2026, 9, 29, 14, 30);

      final history = [
        OrderStatusHistoryEntry(
          id: 'h1',
          orderId: 'ord-1',
          fromStatus: 'pending_payment',
          toStatus: 'paid',
          notes: 'Paystack transaction verified',
          createdAt: t1,
        ),
        OrderStatusHistoryEntry(
          id: 'h2',
          orderId: 'ord-1',
          fromStatus: 'paid',
          toStatus: 'processing',
          notes: 'Italian silk crepe pulled from inventory for cutting',
          createdAt: t2,
        ),
      ];

      final stages = AtelierTimelineStage.buildStages(OrderStatus.processing, history);
      expect(stages.length, 6);

      // Stage 1: Commission Received (Completed)
      expect(stages[0].stageNumber, 1);
      expect(stages[0].isCompleted, isTrue);
      expect(stages[0].isCurrent, isFalse);
      expect(stages[0].isPending, isFalse);
      expect(stages[0].completedAt, t1);
      expect(stages[0].notes, 'Paystack transaction verified');

      // Stage 2: Sourcing & Drafting (Current)
      expect(stages[1].stageNumber, 2);
      expect(stages[1].isCompleted, isFalse);
      expect(stages[1].isCurrent, isTrue);
      expect(stages[1].isPending, isFalse);
      expect(stages[1].completedAt, t2);
      expect(stages[1].notes, 'Italian silk crepe pulled from inventory for cutting');

      // Stage 3: Craftsmanship (Pending)
      expect(stages[2].stageNumber, 3);
      expect(stages[2].isCompleted, isFalse);
      expect(stages[2].isCurrent, isFalse);
      expect(stages[2].isPending, isTrue);

      // Stage 6: Delivered (Pending)
      expect(stages[5].stageNumber, 6);
      expect(stages[5].isPending, isTrue);
    });

    test('AtelierTimelineStage marks all 6 stages as completed when order is delivered', () {
      final tDelivered = DateTime(2026, 10, 5, 16, 0);
      final history = [
        OrderStatusHistoryEntry(
          id: 'h1',
          orderId: 'ord-1',
          fromStatus: 'shipped',
          toStatus: 'delivered',
          notes: 'Client signed for delivery at Maitama salon',
          createdAt: tDelivered,
        ),
      ];

      final stages = AtelierTimelineStage.buildStages(OrderStatus.delivered, history);
      expect(stages.length, 6);

      for (final stage in stages) {
        expect(stage.isCompleted, isTrue);
        expect(stage.isPending, isFalse);
      }
      expect(stages.last.notes, 'Client signed for delivery at Maitama salon');
      expect(stages.last.completedAt, tDelivered);
    });

    test('OrderStatusHistoryEntry deserializes JSON correctly', () {
      final json = {
        'id': 'hist-uuid-1',
        'order_id': 'ord-uuid-1',
        'from_status': 'in_production',
        'to_status': 'ready_for_fitting',
        'changed_by': 'usr-admin-1',
        'notes': 'Bodice assembled with hand boning. Ready for salon fitting.',
        'created_at': '2026-09-29T12:00:00Z',
      };

      final entry = OrderStatusHistoryEntry.fromJson(json);

      expect(entry.id, 'hist-uuid-1');
      expect(entry.orderId, 'ord-uuid-1');
      expect(entry.fromStatus, 'in_production');
      expect(entry.toStatus, 'ready_for_fitting');
      expect(entry.changedBy, 'usr-admin-1');
      expect(entry.notes, 'Bodice assembled with hand boning. Ready for salon fitting.');
      expect(entry.createdAt.year, 2026);
    });
  });
}

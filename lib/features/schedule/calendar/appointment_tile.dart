import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kalender/kalender.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/hover_lift.dart';
import 'appointment_calendar_event.dart';

/// Builds the [TileComponents] used by the weekly calendar to render
/// [AppointmentCalendarEvent] tiles — the stationary tile, the drop-target
/// outline, the drag feedback tile, the "left behind" placeholder shown at
/// the original position while dragging, and the resize handles.
///
/// [onToggleDone] is invoked directly by the small status icon on the
/// stationary tile — it must never open an edit screen by itself.
TileComponents appointmentTileComponents(
  BuildContext context, {
  required void Function(AppointmentCalendarEvent event) onToggleDone,
}) {
  final radius = BorderRadius.circular(20);

  return TileComponents(
    tileBuilder: (event, tileRange) {
      final e = event as AppointmentCalendarEvent;
      return HoverLift(
        liftPx: 2,
        borderRadius: radius,
        child: _AppointmentTileContent(event: e, onToggleDone: onToggleDone),
      );
    },
    dropTargetTile: (event) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
          width: 2,
        ),
        borderRadius: radius,
      ),
    ),
    feedbackTileBuilder: (event, dropTargetWidgetSize) => AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: dropTargetWidgetSize.width,
      height: dropTargetWidgetSize.height,
      decoration: BoxDecoration(
        color: (event as AppointmentCalendarEvent).displayColor.withAlpha(
          180,
        ),
        borderRadius: radius,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.topLeft,
      child: Text(
        event.appointment.clientName?.isNotEmpty == true
            ? event.appointment.clientName!
            : event.appointment.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ),
    tileWhenDraggingBuilder: (event) => DecoratedBox(
      decoration: BoxDecoration(
        color: (event as AppointmentCalendarEvent).displayColor.withAlpha(80),
        borderRadius: radius,
      ),
      // Placeholder left at the ORIGINAL position while dragging — kept
      // empty/translucent on purpose, the feedback tile under the pointer
      // is what the user actually tracks while dragging.
    ),
    dragAnchorStrategy: pointerDragAnchorStrategy,
    verticalResizeHandle: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimaryContainer.withAlpha(
          150,
        ),
        shape: BoxShape.circle,
      ),
    ),
    horizontalResizeHandle: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimaryContainer.withAlpha(
          150,
        ),
        shape: BoxShape.circle,
      ),
    ),
  );
}

/// The stationary tile content: tinted background + solid accent bar in
/// [AppointmentCalendarEvent.displayColor] (same "tinted container + solid
/// accent" language as [TransactionTile]/[AmountCard]), client name (falling
/// back to the appointment title), a compact start–end time range, and a
/// small tap-to-toggle status icon.
class _AppointmentTileContent extends StatelessWidget {
  final AppointmentCalendarEvent event;
  final void Function(AppointmentCalendarEvent event) onToggleDone;

  const _AppointmentTileContent({
    required this.event,
    required this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    final appointment = event.appointment;
    final color = event.displayColor;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final timeFmt = DateFormat('HH:mm', 'pl_PL');

    final displayName = appointment.clientName?.isNotEmpty == true
        ? appointment.clientName!
        : appointment.title;
    final timeRangeLabel =
        '${timeFmt.format(appointment.scheduledAt)}–${timeFmt.format(appointment.scheduledAt.add(Duration(minutes: appointment.durationMinutes)))}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 32;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: compact ? 2 : 4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick status toggle. Wrapped in its own GestureDetector
                  // so a quick tap is resolved by the gesture arena before
                  // the ancestor LongPressDraggable (which only starts after
                  // a long-press) or the tile's tap-to-edit detector get a
                  // chance to react — a plain tap here never starts a drag
                  // or opens the edit screen. Dragging the rest of the tile
                  // is unaffected since the draggable wraps this whole tile
                  // from the outside and still owns long-press gestures.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onToggleDone(event),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1, right: 4),
                      child: Icon(
                        appointment.isDone
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: appointment.isDone ? AppTheme.incomeColor : muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: appointment.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: appointment.isDone ? muted : null,
                          ),
                        ),
                        if (!compact)
                          Flexible(
                            child: Text(
                              timeRangeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

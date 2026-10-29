import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../utils/links.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'maintenance_screen.dart';
import 'new_ticket_screen.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticket});
  final Ticket ticket;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _message = TextEditingController();
  final _scroll = ScrollController();

  Ticket get t => widget.ticket;

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    context.appRead.sendMessage(t, text);
    _message.clear();
    HapticFeedback.lightImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.app; // rebuild on changes
    final (fg, bg) = statusColors(t.status);
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: CircleAction(icon: Icons.arrow_back_ios_new_rounded, size: 42, onTap: () => Navigator.pop(context)),
          ),
        ),
        leadingWidth: 66,
        title: Text(context.tr('ticket', {'n': t.number})),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
                            child: Icon(categoryIcons[t.category], color: AppColors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(
                                  '${context.categoryLabel(t.category)} · ${t.location}',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusPill(label: context.statusLabel(t.status), color: fg, background: bg),
                          StatusPill(
                            label: context.priorityLabel(t.priority),
                            color: t.priority == TicketPriority.urgent
                                ? AppColors.ink
                                : t.priority == TicketPriority.high
                                ? AppColors.ink
                                : AppColors.ink,
                            background: AppColors.white,
                          ),
                          StatusPill(
                            label: context.tr('opened', {'when': context.ago(t.openedAt)}),
                            color: AppColors.muted,
                            background: AppColors.white,
                            dot: false,
                          ),
                        ],
                      ),
                      if (t.photos.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: t.photos.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: SizedBox(width: 80, child: ticketImage(t.photos[i])),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (t.technician != null) _technicianCard(),
                const SizedBox(height: 22),
                Text(context.tr('timeline'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _Timeline(ticket: t),
                if (t.status == TicketStatus.resolved) ...[const SizedBox(height: 22), _RatingCard(ticket: t)],
                const SizedBox(height: 22),
                Text(context.tr('conversation'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                for (final m in t.messages) _Bubble(message: m),
                if (t.isOpen && t.status == TicketStatus.inProgress) ...[
                  const SizedBox(height: 10),
                  PillButton(
                    icon: Icons.check_circle_outline_rounded,
                    label: context.tr('mark_resolved'),
                    secondary: true,
                    height: 50,
                    onPressed: () => context.appRead.confirmResolved(t),
                  ),
                ],
              ],
            ),
          ),
          if (t.isOpen) _composer(),
        ],
      ),
    );
  }

  Widget _technicianCard() {
    final tech = t.technician!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.charcoal, AppColors.ink]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Avatar(image: tech.photo, name: tech.name, size: 52, ring: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tech.name,
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15.5),
                ),
                const SizedBox(height: 2),
                Text(
                  t.visitAt != null && t.isOpen
                      ? '${context.tr('visit_planned')} · ${context.dayLabel(t.visitAt!)} ${context.time(t.visitAt!)}'
                      : tech.trade,
                  style: TextStyle(color: AppColors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
              ],
            ),
          ),
          CircleAction(
            icon: Icons.call_rounded,
            size: 44,
            color: AppColors.ink,
            onTap: () => callNumber(context, tech.phone),
          ),
        ],
      ),
    );
  }

  Widget _composer() => Container(
    padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.paddingOf(context).bottom + 10),
    decoration: const BoxDecoration(
      color: AppColors.white,
      border: Border(top: BorderSide(color: AppColors.line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _message,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: context.tr('write_message'),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(color: AppColors.ink),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        CircleAction(
          icon: Icons.arrow_upward_rounded,
          size: 50,
          color: AppColors.white,
          background: AppColors.ink,
          onTap: _send,
        ),
      ],
    ),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final reached = switch (t.status) {
      TicketStatus.newTicket => 0,
      TicketStatus.assigned => 1,
      TicketStatus.inProgress => 2,
      TicketStatus.resolved => 3,
      TicketStatus.cancelled => 0,
    };
    final steps = [
      (context.statusLabel(TicketStatus.newTicket), context.date(t.openedAt)),
      (context.statusLabel(TicketStatus.assigned), t.technician?.name ?? ''),
      (
        context.statusLabel(TicketStatus.inProgress),
        t.visitAt != null ? '${context.dayLabel(t.visitAt!)} · ${context.time(t.visitAt!)}' : '',
      ),
      (context.statusLabel(TicketStatus.resolved), t.resolvedAt != null ? context.date(t.resolvedAt!) : ''),
    ];
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= reached ? AppColors.ink : AppColors.white,
                          border: Border.all(color: i <= reached ? AppColors.ink : AppColors.silver, width: 2),
                        ),
                        child: i <= reached ? const Icon(Icons.check_rounded, size: 13, color: AppColors.white) : null,
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: i < reached ? AppColors.ink : AppColors.silver,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].$1,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: i <= reached ? AppColors.onyx : AppColors.faint,
                            ),
                          ),
                          if (steps[i].$2.isNotEmpty && i <= reached + 1)
                            Text(steps[i].$2, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final me = message.fromMe;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: BoxDecoration(
            color: me ? AppColors.ink : AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(me ? 20 : 6),
              bottomRight: Radius.circular(me ? 6 : 20),
            ),
            boxShadow: me ? null : AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!me && message.author != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.author!,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.ink),
                  ),
                ),
              Text(message.body, style: TextStyle(color: me ? AppColors.white : AppColors.onyx, height: 1.4)),
              const SizedBox(height: 4),
              Text(
                context.ago(message.at),
                style: TextStyle(fontSize: 11, color: me ? AppColors.white.withValues(alpha: 0.6) : AppColors.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final rating = ticket.rating;
    return SurfaceCard(
      color: AppColors.white,
      border: true,
      child: Column(
        children: [
          Text(
            context.tr(rating == null ? 'rate_repair' : 'thanks_rating'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.appRead.rate(ticket, i);
                  },
                  icon: Icon(
                    i <= (rating ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 34,
                    color: AppColors.ink,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

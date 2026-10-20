import 'dart:math';
import '../models/lent_borrowed_record.dart';

/// A template for funny, contextual debt reminders.
class DebtReminderTemplate {
  final String id;
  final DebtType appliesToType;
  final DebtStatus appliesToStatus;
  final String text;
  final String emoji;

  const DebtReminderTemplate({
    required this.id,
    required this.appliesToType,
    required this.appliesToStatus,
    required this.text,
    this.emoji = '🤝',
  });
}

/// Comprehensive library of 36+ unique, contextual, hilarious reminders for Spentee's
/// Lent & Borrowed module. Uses natural, conversational humour without insulting anyone.
class DebtReminderLibrary {
  DebtReminderLibrary._();

  static const List<DebtReminderTemplate> templates = [
    // ── 1. Money Lent — Approaching Due Date (6 templates) ───────────────────
    DebtReminderTemplate(
      id: 'lent_appr_01',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '⏳',
      text: "Friendly reminder! {name}'s payment date is approaching. Let's see if their memory is as sharp as their borrowing skills! 😉",
    ),
    DebtReminderTemplate(
      id: 'lent_appr_02',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '📅',
      text: "The calendar says {name} has {remaining} due soon. Maybe casually send them a screenshot of a tea stall to break the ice? ☕",
    ),
    DebtReminderTemplate(
      id: 'lent_appr_03',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '🔔',
      text: "Only a few days left before {name}'s promise matures! Time to practice your 'Hey bro, remember that ₹{remaining}?' tone. 📞",
    ),
    DebtReminderTemplate(
      id: 'lent_appr_04',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '👀',
      text: "Payment countdown for {name} is ticking! May their Google Pay pin work flawlessly this week. 🤞",
    ),
    DebtReminderTemplate(
      id: 'lent_appr_05',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '🤝',
      text: "Due date on {due_date} is coming up for {name}. Good friendship + timely repayment = unstoppable duo! 💫",
    ),
    DebtReminderTemplate(
      id: 'lent_appr_06',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '💌',
      text: "A gentle nudge: {name}'s ₹{remaining} is due soon. No pressure, just positive cosmic energy toward your bank account! 🧘‍♂️",
    ),

    // ── 2. Money Lent — Due Today (6 templates) ──────────────────────────────
    DebtReminderTemplate(
      id: 'lent_today_01',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '🚨',
      text: "Today is D-Day for {name}! Time to send that polite UPI QR code with a smiley face. 📱😁",
    ),
    DebtReminderTemplate(
      id: 'lent_today_02',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '🎯',
      text: "The due date has arrived! {name} owes ₹{remaining} today. May their server never show 'payment processing'! ⚡",
    ),
    DebtReminderTemplate(
      id: 'lent_today_03',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '🎈',
      text: "Happy 'Return My Money' Day to {name}! Today would be a splendid occasion to clear that ₹{remaining}. 🎉",
    ),
    DebtReminderTemplate(
      id: 'lent_today_04',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '☕',
      text: "Today's the day! Invite {name} for chai and 'accidentally' keep your QR code as your phone wallpaper. ☕📲",
    ),
    DebtReminderTemplate(
      id: 'lent_today_05',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '📬',
      text: "Today is the official repayment date for {name}'s ₹{remaining}. Your bank account is ready to welcome its lost soldiers home! 🫡",
    ),
    DebtReminderTemplate(
      id: 'lent_today_06',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.pending,
      emoji: '✨',
      text: "Promise fulfillment day! Send {name} a thumbs-up emoji and see if ₹{remaining} magically credits your account. 👍💸",
    ),

    // ── 3. Money Lent — Overdue (7 templates) ────────────────────────────────
    DebtReminderTemplate(
      id: 'lent_over_01',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.overdue,
      emoji: '🕵️',
      text: "{name}'s payment is {days_overdue} days overdue! Did they switch identities or join a silent monastery? Time for a friendly ping! 🕊️",
    ),
    DebtReminderTemplate(
      id: 'lent_over_02',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.overdue,
      emoji: '🦕',
      text: "It has been {days_overdue} days since the due date. At this rate, {name}'s ₹{remaining} might qualify as an archaeological artefact! 🏺",
    ),
    DebtReminderTemplate(
      id: 'lent_over_03',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.overdue,
      emoji: '🛰️',
      text: "Houston, we have an overdue debt! {name} has been silent for {days_overdue} days. Send a ping before NASA launches a search probe! 🚀",
    ),
    DebtReminderTemplate(
      id: 'lent_over_04',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.overdue,
      emoji: '🕊️',
      text: "{name}'s payment is {days_overdue} days past due date! Reminder: Friendship is priceless, but ₹{remaining} still buys groceries! 🛒🤝",
    ),
    DebtReminderTemplate(
      id: 'lent_over_05',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.overdue,
      emoji: '👻',
      text: "Did {name} ghost you, or did their phone's banking app delete itself? {days_overdue} days overdue—time for a friendly check-in! 👻📱",
    ),
    DebtReminderTemplate(
      id: 'lent_over_06',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.overdue,
      emoji: '⏳',
      text: "Overdue by {days_overdue} days! Even fixed deposits pay interest in this timeframe. Send {name} a warm reminder! 💰",
    ),
    DebtReminderTemplate(
      id: 'lent_over_07',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.overdue,
      emoji: '☕',
      text: "It's been {days_overdue} days. A polite text message: 'Hey {name}, my wallet misses your ₹{remaining}!' works wonders. 💌",
    ),

    // ── 4. Money Lent — Partially Repaid (6 templates) ───────────────────────
    DebtReminderTemplate(
      id: 'lent_part_01',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.partiallyRepaid,
      emoji: '💪',
      text: "Progress unlocked! {name} returned ₹{repaid}. Just ₹{remaining} left to go before full liberation! 🎯",
    ),
    DebtReminderTemplate(
      id: 'lent_part_02',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.partiallyRepaid,
      emoji: '🍰',
      text: "{name} cleared a slice of the debt pie! ₹{remaining} remains. The glass is officially half-full (of your own money)! 🥛✨",
    ),
    DebtReminderTemplate(
      id: 'lent_part_03',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.partiallyRepaid,
      emoji: '🚴',
      text: "{name} is making moves! ₹{repaid} received, only ₹{remaining} to cross the finish line. Keep the momentum going! 🏁",
    ),
    DebtReminderTemplate(
      id: 'lent_part_04',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.partiallyRepaid,
      emoji: '🌱',
      text: "Small victories! {name} paid ₹{repaid}. A few more installments and your wallet can throw a mini party! 🥳",
    ),
    DebtReminderTemplate(
      id: 'lent_part_05',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.partiallyRepaid,
      emoji: '🍕',
      text: "Partial repayment from {name} logged! ₹{remaining} left. That's worth at least a couple of pizzas! 🍕🍕",
    ),
    DebtReminderTemplate(
      id: 'lent_part_06',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.partiallyRepaid,
      emoji: '🌈',
      text: "The light at the end of the tunnel! {name} owes only ₹{remaining} now. Trust the process! ☀️",
    ),

    // ── 5. Money Lent & Borrowed — Fully Settled (5 templates) ────────────────
    DebtReminderTemplate(
      id: 'settled_01',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.settled,
      emoji: '🎉',
      text: "Debt cleared! {name} returned the entire ₹{amount}. Friendship restored to 100% and credit score at legendary status! 🏆💯",
    ),
    DebtReminderTemplate(
      id: 'settled_02',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.settled,
      emoji: '👑',
      text: "All ₹{amount} received from {name}! A friend who repays on time deserves a royal salute and a lifetime of respect! 👑🫡",
    ),
    DebtReminderTemplate(
      id: 'settled_03',
      appliesToType: DebtType.lent,
      appliesToStatus: DebtStatus.settled,
      emoji: '🤝',
      text: "Account zeroed out! Both wallets are in equilibrium, cosmic balance is restored, and friendship wins! 🌟",
    ),
    DebtReminderTemplate(
      id: 'settled_04',
      appliesToType: DebtType.borrowed,
      appliesToStatus: DebtStatus.settled,
      emoji: '🕊️',
      text: "You paid back {name} in full! You are officially debt-free and your conscience is as clear as spring water! 🌿🧘",
    ),
    DebtReminderTemplate(
      id: 'settled_05',
      appliesToType: DebtType.borrowed,
      appliesToStatus: DebtStatus.settled,
      emoji: '✨',
      text: "You returned ₹{amount} to {name}! You have proven yourself as a top-tier trustworthy human! 🥇👏",
    ),

    // ── 6. Money I Borrowed — Self Reminders (6 templates) ───────────────────
    DebtReminderTemplate(
      id: 'borrowed_01',
      appliesToType: DebtType.borrowed,
      appliesToStatus: DebtStatus.pending,
      emoji: '🧘',
      text: "Self-reminder: You borrowed ₹{remaining} from {name}. Repay them before they 'casually' ask you about it over lunch! 🥗👀",
    ),
    DebtReminderTemplate(
      id: 'borrowed_02',
      appliesToType: DebtType.borrowed,
      appliesToStatus: DebtStatus.pending,
      emoji: '⭐',
      text: "Don't be that friend! {name} trusted you with ₹{remaining}. Keep karma happy and schedule that repayment soon! 😇",
    ),
    DebtReminderTemplate(
      id: 'borrowed_03',
      appliesToType: DebtType.borrowed,
      appliesToStatus: DebtStatus.pending,
      emoji: '⏰',
      text: "You owe {name} ₹{remaining}. Returning it before the due date earns you +1000 honorary karma points! 🌟",
    ),
    DebtReminderTemplate(
      id: 'borrowed_over_01',
      appliesToType: DebtType.borrowed,
      appliesToStatus: DebtStatus.overdue,
      emoji: '🏃‍♂️',
      text: "Oops! Your repayment to {name} is {days_overdue} days overdue! Clear it today before they send you awkward meme reminders! 🙈📲",
    ),
    DebtReminderTemplate(
      id: 'borrowed_over_02',
      appliesToType: DebtType.borrowed,
      appliesToStatus: DebtStatus.overdue,
      emoji: '🔥',
      text: "Alert: You're {days_overdue} days late on ₹{remaining} to {name}. Even an apology chai + repayment will save the day! ☕🤝",
    ),
    DebtReminderTemplate(
      id: 'borrowed_part_01',
      appliesToType: DebtType.borrowed,
      appliesToStatus: DebtStatus.partiallyRepaid,
      emoji: '📈',
      text: "Good job! You paid back ₹{repaid} to {name}. Only ₹{remaining} remaining to attain total debt nirvana! 🧘✨",
    ),
  ];

  /// Returns all eligible reminder templates matching the record's current state.
  static List<String> getRemindersForRecord(
    LentBorrowedRecord record, {
    String currencySymbol = '₹',
  }) {
    final isDueToday = record.dueDate != null &&
        record.daysUntilDue == 0 &&
        !record.isFullySettled;

    List<DebtReminderTemplate> matching = [];

    if (record.isFullySettled) {
      matching = templates
          .where((t) =>
              t.appliesToType == record.type &&
              t.appliesToStatus == DebtStatus.settled)
          .toList();
    } else if (record.isOverdue) {
      matching = templates
          .where((t) =>
              t.appliesToType == record.type &&
              t.appliesToStatus == DebtStatus.overdue)
          .toList();
    } else if (isDueToday && record.type == DebtType.lent) {
      // Due today specific templates
      matching = templates.where((t) => t.id.startsWith('lent_today_')).toList();
    } else if (record.repaidAmount > 0.0) {
      matching = templates
          .where((t) =>
              t.appliesToType == record.type &&
              t.appliesToStatus == DebtStatus.partiallyRepaid)
          .toList();
    } else {
      // Pending
      matching = templates
          .where((t) =>
              t.appliesToType == record.type &&
              t.appliesToStatus == DebtStatus.pending &&
              !t.id.startsWith('lent_today_'))
          .toList();
    }

    if (matching.isEmpty) {
      matching = templates.where((t) => t.appliesToType == record.type).toList();
    }

    // Format currency helper
    String fmt(double val) =>
        '$currencySymbol${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2)}';

    final dueStr = record.dueDate != null
        ? '${record.dueDate!.day}/${record.dueDate!.month}/${record.dueDate!.year}'
        : 'soon';

    return matching.map((t) {
      return t.text
          .replaceAll('{name}', record.personName)
          .replaceAll('{amount}', fmt(record.amount))
          .replaceAll('{remaining}', fmt(record.outstandingAmount))
          .replaceAll('{repaid}', fmt(record.repaidAmount))
          .replaceAll('{due_date}', dueStr)
          .replaceAll('{days_overdue}', '${record.daysOverdue}');
    }).toList();
  }

  /// Returns a single funny reminder for the record.
  static String getRandomReminder(
    LentBorrowedRecord record, {
    String currencySymbol = '₹',
    int? seed,
  }) {
    final list = getRemindersForRecord(record, currencySymbol: currencySymbol);
    if (list.isEmpty) {
      return "Friendly reminder: ${record.personName} owes $currencySymbol${record.outstandingAmount}.";
    }
    final rand = seed != null ? Random(seed) : Random();
    return list[rand.nextInt(list.length)];
  }
}

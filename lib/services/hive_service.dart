import 'package:hive_flutter/hive_flutter.dart';

import '../models/todo_item.dart';
import '../models/note.dart';
import '../models/transaction.dart';
import '../models/baki_khata.dart';
import '../models/loan.dart';
import '../models/shopping_item.dart';
import '../models/history_entry.dart';
import '../models/habit.dart';
import '../models/mood_entry.dart';
import '../models/vault_credential.dart';
import '../models/quiz_result.dart';
import '../models/subscription.dart';
import '../models/post.dart';

/// Box names, centralised so every screen reads/writes the same box.
class HiveBoxes {
  HiveBoxes._();
  static const todos = 'todos';
  static const notes = 'notes';
  static const transactions = 'transactions';
  static const people = 'baki_people';
  static const ledger = 'baki_ledger';
  static const loans = 'loans';
  static const shopping = 'shopping';
  static const history = 'history';
  static const tasbih = 'tasbih'; // simple counter storage (Map<String,dynamic>)
  static const settings = 'settings'; // app-wide prefs (Map<String,dynamic>)
  static const habits = 'habits';
  static const habitChecks = 'habit_checks';
  static const moods = 'moods';
  static const vault = 'vault';
  static const quizResults = 'quiz_results';
  static const subscriptions = 'subscriptions';
  static const posts = 'posts';
}

/// One-time Hive setup, called from `main()` before `runApp`.
class HiveService {
  HiveService._();

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(TodoItemAdapter());
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(ChecklistItemAdapter());
    Hive.registerAdapter(MoneyTransactionAdapter());
    Hive.registerAdapter(PersonAdapter());
    Hive.registerAdapter(LedgerEntryAdapter());
    Hive.registerAdapter(LoanAdapter());
    Hive.registerAdapter(LoanPaymentAdapter());
    Hive.registerAdapter(ShoppingItemAdapter());
    Hive.registerAdapter(HistoryEntryAdapter());
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(VaultCredentialAdapter());
    Hive.registerAdapter(QuizResultAdapter());
    Hive.registerAdapter(BillingCycleAdapter());
    Hive.registerAdapter(SubscriptionAdapter());
    Hive.registerAdapter(PostCategoryAdapter());
    Hive.registerAdapter(PostAdapter());

    await Future.wait([
      Hive.openBox<TodoItem>(HiveBoxes.todos),
      Hive.openBox<Note>(HiveBoxes.notes),
      Hive.openBox<MoneyTransaction>(HiveBoxes.transactions),
      Hive.openBox<Person>(HiveBoxes.people),
      Hive.openBox<LedgerEntry>(HiveBoxes.ledger),
      Hive.openBox<Loan>(HiveBoxes.loans),
      Hive.openBox<ShoppingItem>(HiveBoxes.shopping),
      Hive.openBox<HistoryEntry>(HiveBoxes.history),
      Hive.openBox(HiveBoxes.tasbih),
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox<Habit>(HiveBoxes.habits),
      Hive.openBox(HiveBoxes.habitChecks),
      Hive.openBox<MoodEntry>(HiveBoxes.moods),
      Hive.openBox<VaultCredential>(HiveBoxes.vault),
      Hive.openBox<QuizResult>(HiveBoxes.quizResults),
      Hive.openBox<Subscription>(HiveBoxes.subscriptions),
      Hive.openBox<Post>(HiveBoxes.posts),
    ]);
  }

  static Box<TodoItem> get todos => Hive.box<TodoItem>(HiveBoxes.todos);
  static Box<Note> get notes => Hive.box<Note>(HiveBoxes.notes);
  static Box<MoneyTransaction> get transactions => Hive.box<MoneyTransaction>(HiveBoxes.transactions);
  static Box<Person> get people => Hive.box<Person>(HiveBoxes.people);
  static Box<LedgerEntry> get ledger => Hive.box<LedgerEntry>(HiveBoxes.ledger);
  static Box<Loan> get loans => Hive.box<Loan>(HiveBoxes.loans);
  static Box<ShoppingItem> get shopping => Hive.box<ShoppingItem>(HiveBoxes.shopping);
  static Box<HistoryEntry> get history => Hive.box<HistoryEntry>(HiveBoxes.history);
  static Box get tasbih => Hive.box(HiveBoxes.tasbih);
  static Box get settings => Hive.box(HiveBoxes.settings);
  static Box<Habit> get habits => Hive.box<Habit>(HiveBoxes.habits);
  static Box get habitChecks => Hive.box(HiveBoxes.habitChecks);
  static Box<MoodEntry> get moods => Hive.box<MoodEntry>(HiveBoxes.moods);
  static Box<VaultCredential> get vault => Hive.box<VaultCredential>(HiveBoxes.vault);
  static Box<QuizResult> get quizResults => Hive.box<QuizResult>(HiveBoxes.quizResults);
  static Box<Subscription> get subscriptions => Hive.box<Subscription>(HiveBoxes.subscriptions);
  static Box<Post> get posts => Hive.box<Post>(HiveBoxes.posts);
}

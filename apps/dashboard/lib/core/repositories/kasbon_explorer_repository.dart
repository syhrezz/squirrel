import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/customers/models/customer_models.dart';

abstract class KasbonExplorerRepository {
  Future<CustomerPageResult> getCustomers(CustomerFilter filter);
  Future<CustomerExplorerDetail> getCustomerDetail(String customerId);
  Future<List<DebtTimelineItem>> getCustomerTimeline(String customerId);
  Future<List<DebtAgingBucket>> getDebtAging(String customerId);
  Future<KasbonSummary> getKasbonSummary();
}

class SupabaseKasbonExplorerRepository
    implements KasbonExplorerRepository {
  SupabaseKasbonExplorerRepository(this._client, this._orgId);

  final SupabaseClient _client;
  final String _orgId;

  // ---------------------------------------------------------------------------
  // getKasbonSummary
  // ---------------------------------------------------------------------------

  @override
  Future<KasbonSummary> getKasbonSummary() async {
    final customerRows = await _client
        .from('customers')
        .select('id, name, is_active')
        .eq('organization_id', _orgId);

    final allTxRows = await _client
        .from('debt_transactions')
        .select('customer_id, type, amount, created_at')
        .eq('organization_id', _orgId);

    final txList = allTxRows as List;
    final custList = customerRows as List;

    // Compute per-customer balance
    final balances = <String, int>{};
    for (final tx in txList) {
      final cid = tx['customer_id'] as String;
      final amt = tx['amount'] as int? ?? 0;
      balances[cid] = (balances[cid] ?? 0) +
          (tx['type'] == 'debt' ? amt : -amt);
    }

    int totalOutstanding = 0;
    int customersWithDebt = 0;
    int largestBalance = 0;
    String largestName = '';

    for (final c in custList) {
      final cid = c['id'] as String;
      final bal = balances[cid] ?? 0;
      if (bal > 0) {
        totalOutstanding += bal;
        customersWithDebt++;
        if (bal > largestBalance) {
          largestBalance = bal;
          largestName = c['name'] as String? ?? '';
        }
      }
    }

    final avgOutstanding = customersWithDebt > 0
        ? totalOutstanding ~/ customersWithDebt
        : 0;

    // Payments this month
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1)
        .millisecondsSinceEpoch;
    int paidThisMonth = 0;
    for (final tx in txList) {
      if (tx['type'] == 'payment' &&
          (tx['created_at'] as int? ?? 0) >= monthStart) {
        paidThisMonth += tx['amount'] as int? ?? 0;
      }
    }

    return KasbonSummary(
      totalOutstanding: totalOutstanding,
      totalCustomers: custList.length,
      customersWithDebt: customersWithDebt,
      paidThisMonth: paidThisMonth,
      averageOutstanding: avgOutstanding,
      largestBalance: largestBalance,
      largestCustomerName: largestName,
    );
  }

  // ---------------------------------------------------------------------------
  // getCustomers
  // ---------------------------------------------------------------------------

  @override
  Future<CustomerPageResult> getCustomers(
      CustomerFilter filter) async {
    var query = _client
        .from('customers')
        .select('id, name, phone, is_active, created_at, updated_at')
        .eq('organization_id', _orgId);

    if (filter.search.isNotEmpty) {
      query = query.ilike('name', '%${filter.search}%');
    }

    final rows = await query.order('name', ascending: true);
    final custList = rows as List;

    // Compute balances + last tx date
    final allTxRows = await _client
        .from('debt_transactions')
        .select('customer_id, type, amount, created_at')
        .eq('organization_id', _orgId);

    final balances = <String, int>{};
    final txCounts = <String, int>{};
    final lastTxDate = <String, int>{};

    for (final tx in allTxRows as List) {
      final cid = tx['customer_id'] as String;
      final amt = tx['amount'] as int? ?? 0;
      final ts = tx['created_at'] as int? ?? 0;
      balances[cid] = (balances[cid] ?? 0) +
          (tx['type'] == 'debt' ? amt : -amt);
      txCounts[cid] = (txCounts[cid] ?? 0) + 1;
      if (ts > (lastTxDate[cid] ?? 0)) lastTxDate[cid] = ts;
    }

    // Build items
    var items = custList.map((c) {
      final cid = c['id'] as String;
      final bal = balances[cid] ?? 0;
      final lastTs = lastTxDate[cid];
      return CustomerExplorerItem(
        id: cid,
        name: c['name'] as String,
        phone: c['phone'] as String?,
        balance: bal,
        txCount: txCounts[cid] ?? 0,
        isActive: c['is_active'] as bool? ?? true,
        lastTransactionDate: lastTs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastTs)
            : null,
      );
    }).toList();

    // Apply balance filter
    if (filter.balanceFilter != CustomerBalanceFilter.all) {
      items = items.where((c) {
        switch (filter.balanceFilter) {
          case CustomerBalanceFilter.hasDebt:
            return c.hasDebt;
          case CustomerBalanceFilter.paidOff:
            return c.isPaidOff;
          case CustomerBalanceFilter.overpaid:
            return c.isOverpaid;
          case CustomerBalanceFilter.all:
            return true;
        }
      }).toList();
    }

    // Sort
    items.sort((a, b) {
      switch (filter.sortField) {
        case CustomerSortField.name:
          return filter.sortAscending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name);
        case CustomerSortField.balance:
          return filter.sortAscending
              ? a.balance.compareTo(b.balance)
              : b.balance.compareTo(a.balance);
        case CustomerSortField.lastTransaction:
          final aTs =
              a.lastTransactionDate?.millisecondsSinceEpoch ?? 0;
          final bTs =
              b.lastTransactionDate?.millisecondsSinceEpoch ?? 0;
          return filter.sortAscending
              ? aTs.compareTo(bTs)
              : bTs.compareTo(aTs);
      }
    });

    final total = items.length;
    final offset = filter.page * filter.pageSize;
    final page = items
        .skip(offset)
        .take(filter.pageSize)
        .toList();

    return CustomerPageResult(
      items: page,
      totalCount: total,
      page: filter.page,
      pageSize: filter.pageSize,
    );
  }

  // ---------------------------------------------------------------------------
  // getCustomerDetail
  // ---------------------------------------------------------------------------

  @override
  Future<CustomerExplorerDetail> getCustomerDetail(
      String customerId) async {
    final row = await _client
        .from('customers')
        .select()
        .eq('id', customerId)
        .eq('organization_id', _orgId)
        .single();

    final txRows = await _client
        .from('debt_transactions')
        .select('type, amount, created_at')
        .eq('customer_id', customerId)
        .eq('organization_id', _orgId)
        .order('created_at', ascending: true);

    int balance = 0;
    int totalDebt = 0;
    int totalPayment = 0;
    int debtCount = 0;
    int paymentCount = 0;
    int largestDebt = 0;
    int largestPayment = 0;
    DateTime? lastPayment;

    for (final tx in txRows as List) {
      final amt = tx['amount'] as int? ?? 0;
      final ts = tx['created_at'] as int? ?? 0;
      if (tx['type'] == 'debt') {
        balance += amt;
        totalDebt += amt;
        debtCount++;
        if (amt > largestDebt) largestDebt = amt;
      } else {
        balance -= amt;
        totalPayment += amt;
        paymentCount++;
        if (amt > largestPayment) largestPayment = amt;
        final dt = DateTime.fromMillisecondsSinceEpoch(ts);
        if (lastPayment == null || dt.isAfter(lastPayment)) {
          lastPayment = dt;
        }
      }
    }

    final crTs = row['created_at'] as int? ??
        DateTime.now().millisecondsSinceEpoch;

    return CustomerExplorerDetail(
      id: row['id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      note: row['note'] as String?,
      isActive: row['is_active'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(crTs),
      balance: balance,
      totalDebt: totalDebt,
      totalPayment: totalPayment,
      debtCount: debtCount,
      paymentCount: paymentCount,
      lastPaymentDate: lastPayment,
      largestDebt: largestDebt,
      largestPayment: largestPayment,
    );
  }

  // ---------------------------------------------------------------------------
  // getCustomerTimeline
  // ---------------------------------------------------------------------------

  @override
  Future<List<DebtTimelineItem>> getCustomerTimeline(
      String customerId) async {
    final rows = await _client
        .from('debt_transactions')
        .select('id, type, amount, note, created_at')
        .eq('customer_id', customerId)
        .eq('organization_id', _orgId)
        .order('created_at', ascending: true);

    // Build running balance
    int running = 0;
    final items = <DebtTimelineItem>[];
    for (final r in rows as List) {
      final amt = r['amount'] as int? ?? 0;
      running += r['type'] == 'debt' ? amt : -amt;
      items.add(DebtTimelineItem(
        id: r['id'] as String,
        type: r['type'] as String,
        amount: amt,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            r['created_at'] as int),
        runningBalance: running,
        note: r['note'] as String?,
      ));
    }
    return items.reversed.toList(); // newest first
  }

  // ---------------------------------------------------------------------------
  // getDebtAging
  // ---------------------------------------------------------------------------

  @override
  Future<List<DebtAgingBucket>> getDebtAging(
      String customerId) async {
    final rows = await _client
        .from('debt_transactions')
        .select('type, amount, created_at')
        .eq('customer_id', customerId)
        .eq('organization_id', _orgId)
        .eq('type', 'debt')
        .order('created_at', ascending: true);

    final now = DateTime.now();
    int bucket0to30 = 0;
    int bucket31to60 = 0;
    int bucket61to90 = 0;
    int bucket90plus = 0;

    // Simple aging: how old are unpaid debt transactions
    // We assume all debts are unpaid for simplicity
    for (final r in rows as List) {
      final ts = r['created_at'] as int? ?? 0;
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      final age = now.difference(dt).inDays;
      final amt = r['amount'] as int? ?? 0;
      if (age <= 30) {
        bucket0to30 += amt;
      } else if (age <= 60) {
        bucket31to60 += amt;
      } else if (age <= 90) {
        bucket61to90 += amt;
      } else {
        bucket90plus += amt;
      }
    }

    return [
      DebtAgingBucket(
          label: '0–30 hari',
          amount: bucket0to30,
          color: 0xFF22C55E),
      DebtAgingBucket(
          label: '31–60 hari',
          amount: bucket31to60,
          color: 0xFFF59E0B),
      DebtAgingBucket(
          label: '61–90 hari',
          amount: bucket61to90,
          color: 0xFFEF4444),
      DebtAgingBucket(
          label: '90+ hari',
          amount: bucket90plus,
          color: 0xFF7C3AED),
    ];
  }
}

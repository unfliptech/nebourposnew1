class Money {
  const Money(this.amount);

  final double amount;

  Money operator +(Money other) => Money(amount + other.amount);

  @override
  String toString() => amount.toStringAsFixed(2);
}

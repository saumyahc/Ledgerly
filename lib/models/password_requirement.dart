class PasswordRequirement {
  final String label;
  final bool Function(String) check;
  PasswordRequirement(this.label, this.check);
}

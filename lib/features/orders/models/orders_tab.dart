/// Top-level order tabs in the warehouse store keeper app.
enum OrdersTab {
  open,
  completed;

  bool get isOpen => this == OrdersTab.open;
  bool get isCompleted => this == OrdersTab.completed;
}

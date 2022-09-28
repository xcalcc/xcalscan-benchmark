static int a[4];

static int get_elem(int i) {
  return a[i];
}

int foo() {
  return get_elem(0) + get_elem(4);   // AOB in a[4]
}

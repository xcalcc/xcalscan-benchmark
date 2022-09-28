extern int get_elem(int i);

int foo() {
  return get_elem(0) + get_elem(4);   // AOB in a[4]
}
